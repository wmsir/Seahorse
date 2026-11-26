package com.seahorse.store.context;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import java.math.BigInteger;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.RSAPublicKeySpec;
import java.time.Duration;
import java.util.Arrays;
import java.util.Base64;
import java.util.Collection;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

/**
 * FWPT 统一认证中心 (OneID 2.0) JWKS 本地零 RPC 验签器。
 * 定期缓存 /.well-known/jwks.json 公钥（默认 5 分钟），业务请求全程毫秒级内存校验 RS256。
 */
@Slf4j
@Component
public class AuthCenterJwksVerifier {

    private static final long JWKS_CACHE_TTL_MS = 300_000L;
    private static final long UNKNOWN_KID_COOLDOWN_MS = 15_000L;

    @Value("${seahorse.auth-center.jwks-url:https://fwpt.cn/auth/.well-known/jwks.json}")
    private String jwksUrl;

    @Value("${seahorse.auth-center.issuer:https://fwpt.cn/auth}")
    private String expectedIssuer;

    @Value("${seahorse.auth-center.allowed-audiences:seahorse-web,seahorse-app,fwpt-all}")
    private String allowedAudiencesRaw;

    private static final HttpClient HTTP = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(2))
            .build();
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private volatile Map<String, RSAPublicKey> keyMap = new ConcurrentHashMap<>();
    private final AtomicLong expiresAtMs = new AtomicLong(0L);
    private final AtomicLong lastForceRefreshMs = new AtomicLong(0L);
    private final Object refreshLock = new Object();

    public Claims verifyToken(String token) {
        if (!StringUtils.hasText(token)) {
            return null;
        }
        String[] parts = token.trim().split("\\.");
        if (parts.length != 3) {
            return null;
        }
        try {
            byte[] hdrBytes = Base64.getUrlDecoder().decode(parts[0]);
            JsonNode hdr = MAPPER.readTree(hdrBytes);
            if (!"RS256".equalsIgnoreCase(hdr.path("alg").asText(""))) {
                return null;
            }
            String kid = hdr.path("kid").asText("");
            if (!StringUtils.hasText(kid)) {
                log.debug("AuthCenter RS256 令牌缺少 kid 头，拒绝验签");
                return null;
            }
            RSAPublicKey pubKey = resolveKey(kid);
            if (pubKey == null) {
                return null;
            }
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(pubKey)
                    .requireIssuer(expectedIssuer)
                    .setAllowedClockSkewSeconds(10)
                    .build()
                    .parseClaimsJws(token.trim())
                    .getBody();
            if (!hasAllowedAudience(claims)) {
                log.debug("AuthCenter RS256 令牌 aud 校验未通过: aud={}", claims.get("aud"));
                return null;
            }
            return claims;
        } catch (Exception e) {
            log.debug("AuthCenter RS256 令牌校验未通过: {}", e.getMessage());
            return null;
        }
    }

    private boolean hasAllowedAudience(Claims claims) {
        if (claims == null || !StringUtils.hasText(allowedAudiencesRaw)) {
            return false;
        }
        Set<String> allowed = Arrays.stream(allowedAudiencesRaw.split(","))
                .map(String::trim)
                .filter(StringUtils::hasText)
                .collect(Collectors.toSet());
        if (allowed.isEmpty()) {
            return false;
        }
        Object rawAud = claims.get("aud");
        if (rawAud instanceof String s) {
            return allowed.contains(s.trim());
        }
        if (rawAud instanceof Collection<?> col) {
            for (Object item : col) {
                if (item != null && allowed.contains(item.toString().trim())) {
                    return true;
                }
            }
            return false;
        }
        String singleAud = claims.getAudience();
        return StringUtils.hasText(singleAud) && allowed.contains(singleAud.trim());
    }

    private RSAPublicKey resolveKey(String kid) {
        if (!StringUtils.hasText(kid)) {
            return null;
        }
        long now = System.currentTimeMillis();
        Map<String, RSAPublicKey> cur = keyMap;
        if (now > expiresAtMs.get() || cur.isEmpty()) {
            refreshJwks(false);
            cur = keyMap;
        }
        RSAPublicKey found = cur.get(kid.trim());
        if (found != null) {
            return found;
        }
        if (now - lastForceRefreshMs.get() > UNKNOWN_KID_COOLDOWN_MS) {
            refreshJwks(true);
            cur = keyMap;
        }
        return cur.get(kid.trim());
    }

    private void refreshJwks(boolean force) {
        synchronized (refreshLock) {
            long now = System.currentTimeMillis();
            if (!force && now <= expiresAtMs.get() && !keyMap.isEmpty()) {
                return;
            }
            if (force && now - lastForceRefreshMs.get() <= UNKNOWN_KID_COOLDOWN_MS) {
                return;
            }
            if (force) {
                lastForceRefreshMs.set(now);
            }
            if (!StringUtils.hasText(jwksUrl)) {
                return;
            }
            try {
                HttpRequest req = HttpRequest.newBuilder()
                        .uri(URI.create(jwksUrl))
                        .timeout(Duration.ofSeconds(3))
                        .header("Accept", "application/json")
                        .GET()
                        .build();
                HttpResponse<String> resp = HTTP.send(req, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
                if (resp.statusCode() != 200 || !StringUtils.hasText(resp.body())) {
                    return;
                }
                JsonNode root = MAPPER.readTree(resp.body());
                JsonNode keysNode = root.path("keys");
                if (!keysNode.isArray()) {
                    return;
                }
                Map<String, RSAPublicKey> next = new ConcurrentHashMap<>();
                KeyFactory kf = KeyFactory.getInstance("RSA");
                for (JsonNode k : keysNode) {
                    if (!"RSA".equalsIgnoreCase(k.path("kty").asText(""))) {
                        continue;
                    }
                    String kid = k.path("kid").asText("");
                    String nStr = k.path("n").asText("");
                    String eStr = k.path("e").asText("");
                    if (!StringUtils.hasText(kid) || !StringUtils.hasText(nStr) || !StringUtils.hasText(eStr)) {
                        continue;
                    }
                    BigInteger n = new BigInteger(1, Base64.getUrlDecoder().decode(nStr));
                    BigInteger e = new BigInteger(1, Base64.getUrlDecoder().decode(eStr));
                    RSAPublicKey pub = (RSAPublicKey) kf.generatePublic(new RSAPublicKeySpec(n, e));
                    next.put(kid, pub);
                }
                if (!next.isEmpty()) {
                    keyMap = next;
                    expiresAtMs.set(now + JWKS_CACHE_TTL_MS);
                    log.info("已刷新 FWPT Auth Center JWKS 公钥集, 数量={}", next.size());
                }
            } catch (Exception e) {
                log.warn("拉取 FWPT Auth Center JWKS 失败 ({}): {}", jwksUrl, e.getMessage());
            }
        }
    }
}
