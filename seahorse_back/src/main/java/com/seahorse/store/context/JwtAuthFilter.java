package com.seahorse.store.context;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final com.seahorse.store.infrastructure.repository.StoreRepository storeRepository;

    private static final long STORE_CACHE_TTL_MS = 60_000L;
    private static final int STORE_CACHE_MAX_SIZE = 1024;
    private static final long ONEID_CACHE_TTL_MS = 300_000L;
    private static final long ONEID_NEG_TTL_MS = 15_000L;
    private static final int ONEID_CACHE_MAX_SIZE = 2048;

    @org.springframework.beans.factory.annotation.Value("${seahorse.oneid.base-url:http://101.35.100.169:8088}")
    private String oneIdBaseUrl;

    private static final java.net.http.HttpClient ONEID_HTTP = java.net.http.HttpClient.newBuilder()
            .connectTimeout(java.time.Duration.ofSeconds(2))
            .build();
    private static final com.fasterxml.jackson.databind.ObjectMapper ONEID_MAPPER =
            new com.fasterxml.jackson.databind.ObjectMapper();

    public static final class OneIdPrincipal {
        private final Long userId;
        private final String username;
        private final String realName;
        private final String role;
        private final String tenantId;
        private final String storeId;

        public OneIdPrincipal(Long userId, String username, String realName, String role, String tenantId, String storeId) {
            this.userId = userId;
            this.username = username;
            this.realName = realName;
            this.role = role;
            this.tenantId = tenantId;
            this.storeId = storeId;
        }

        public Long getUserId() { return userId; }
        public String getUsername() { return username; }
        public String getRealName() { return realName; }
        public String getRole() { return role; }
        public String getTenantId() { return tenantId; }
        public String getStoreId() { return storeId; }
    }

    private static final class CachedOneIdPrincipal {
        final OneIdPrincipal principal;
        final long expiresAt;
        CachedOneIdPrincipal(OneIdPrincipal principal, long expiresAt) {
            this.principal = principal;
            this.expiresAt = expiresAt;
        }
    }

    private final java.util.concurrent.ConcurrentHashMap<String, CachedOneIdPrincipal> oneIdCache =
            new java.util.concurrent.ConcurrentHashMap<>();

    private static final class CachedStore {
        final com.seahorse.store.domain.iam.model.Store store;
        final long expiresAt;
        CachedStore(com.seahorse.store.domain.iam.model.Store store, long expiresAt) {
            this.store = store;
            this.expiresAt = expiresAt;
        }
    }
    private final java.util.concurrent.ConcurrentHashMap<String, CachedStore> storeCache =
            new java.util.concurrent.ConcurrentHashMap<>();

    private static String sha256Hex(String input) {
        try {
            byte[] digest = java.security.MessageDigest.getInstance("SHA-256")
                    .digest(input.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                sb.append(Character.forDigit((b >> 4) & 0xF, 16));
                sb.append(Character.forDigit(b & 0xF, 16));
            }
            return sb.toString();
        } catch (Exception e) {
            return String.valueOf(input.hashCode());
        }
    }

    /**
     * 通过 OneID 统一通行证中心核验外部 JWT，并缓存 5 分钟（无效令牌负缓存 15 秒）
     */
    public OneIdPrincipal verifyOneIdToken(String token) {
        if (!StringUtils.hasText(token) || !StringUtils.hasText(oneIdBaseUrl)) {
            return null;
        }
        String cleanToken = token.trim();
        String cacheKey = sha256Hex(cleanToken);
        long now = System.currentTimeMillis();
        CachedOneIdPrincipal cached = oneIdCache.get(cacheKey);
        if (cached != null && cached.expiresAt > now) {
            return cached.principal;
        }

        OneIdPrincipal resolved = null;
        try {
            String base = oneIdBaseUrl.endsWith("/") ? oneIdBaseUrl.substring(0, oneIdBaseUrl.length() - 1) : oneIdBaseUrl;
            java.net.http.HttpRequest req = java.net.http.HttpRequest.newBuilder()
                    .uri(java.net.URI.create(base + "/api/v1/user/profile"))
                    .timeout(java.time.Duration.ofSeconds(3))
                    .header("Authorization", "Bearer " + cleanToken)
                    .header("Accept", "application/json")
                    .GET()
                    .build();
            java.net.http.HttpResponse<String> resp = ONEID_HTTP.send(req, java.net.http.HttpResponse.BodyHandlers.ofString(java.nio.charset.StandardCharsets.UTF_8));
            if (resp.statusCode() == 200 && StringUtils.hasText(resp.body())) {
                com.fasterxml.jackson.databind.JsonNode root = ONEID_MAPPER.readTree(resp.body());
                if ("00000".equals(root.path("code").asText())) {
                    com.fasterxml.jackson.databind.JsonNode data = root.path("data");
                    String uname = data.path("username").asText("").trim();
                    if (!StringUtils.hasText(uname)) {
                        uname = data.path("sub").asText("").trim();
                    }
                    if (StringUtils.hasText(uname)) {
                        long uid = data.path("id").isNumber() ? data.path("id").asLong(1L) : 1L;
                        String rname = data.path("realName").asText("").trim();
                        if (!StringUtils.hasText(rname)) {
                            rname = data.path("nickname").asText(uname).trim();
                        }
                        String rawRole = data.path("role").asText("").trim();
                        boolean isDev = "admin".equalsIgnoreCase(uname)
                                || "ADMIN".equalsIgnoreCase(rawRole)
                                || "PLATFORM_DEVELOPER".equalsIgnoreCase(rawRole);
                        resolved = new OneIdPrincipal(
                                uid,
                                uname,
                                rname,
                                isDev ? "PLATFORM_DEVELOPER" : "SUPER_ADMIN",
                                isDev ? "PLATFORM" : "T001",
                                isDev ? "PLATFORM" : "S001"
                        );
                    }
                }
            }
        } catch (Exception e) {
            log.debug("OneID 令牌核验失败: {}", e.getMessage());
            return null;
        }

        if (oneIdCache.size() >= ONEID_CACHE_MAX_SIZE) {
            oneIdCache.clear();
        }
        oneIdCache.put(cacheKey, new CachedOneIdPrincipal(resolved, now + (resolved != null ? ONEID_CACHE_TTL_MS : ONEID_NEG_TTL_MS)));
        return resolved;
    }

    private void applyAuthenticatedContext(
            HttpServletRequest request,
            Long userId,
            String username,
            String tenantId,
            String storeId,
            String role,
            String industry
    ) {
        String jwtTenantId = tenantId;
        String jwtStoreId = storeId;
        boolean isPlatformAdmin = "PLATFORM".equalsIgnoreCase(jwtTenantId)
                || "PLATFORM_DEVELOPER".equalsIgnoreCase(role);

        String headerStoreId = request.getHeader("X-Store-Id");
        String headerTenantId = request.getHeader("X-Tenant-Id");
        if (isPlatformAdmin && StringUtils.hasText(headerTenantId)) {
            tenantId = headerTenantId.trim();
        }

        String lookedUpStoreId = null;
        java.util.Optional<com.seahorse.store.domain.iam.model.Store> lookedUpStoreOpt = java.util.Optional.empty();

        if (StringUtils.hasText(headerStoreId)) {
            String candidateStoreId = headerStoreId.trim();
            lookedUpStoreId = candidateStoreId;
            lookedUpStoreOpt = findStoreCached(candidateStoreId);
            if (lookedUpStoreOpt.isPresent()) {
                com.seahorse.store.domain.iam.model.Store s = lookedUpStoreOpt.get();
                String storeOwnerTenant = s.getTenantId();
                if (isPlatformAdmin || (storeOwnerTenant != null && storeOwnerTenant.equalsIgnoreCase(jwtTenantId))) {
                    storeId = candidateStoreId;
                    if (storeOwnerTenant != null && !storeOwnerTenant.trim().isEmpty()) {
                        tenantId = storeOwnerTenant;
                    }
                    if (s.getIndustry() != null) {
                        industry = s.getIndustry().name();
                    }
                } else {
                    log.debug("忽略跨租户残留 X-Store-Id={}, 当前JWT租户={}, 保持门店={}", candidateStoreId, jwtTenantId, jwtStoreId);
                }
            } else if (isPlatformAdmin || !StringUtils.hasText(jwtStoreId)) {
                storeId = candidateStoreId;
            }
        }

        if (StringUtils.hasText(storeId)) {
            String trimmedStoreId = storeId.trim();
            java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = trimmedStoreId.equals(lookedUpStoreId)
                    ? lookedUpStoreOpt
                    : findStoreCached(trimmedStoreId);
            if (sOpt.isPresent()) {
                com.seahorse.store.domain.iam.model.Store s = sOpt.get();
                if (isPlatformAdmin && s.getTenantId() != null && !s.getTenantId().trim().isEmpty()) {
                    tenantId = s.getTenantId();
                }
                if (s.getIndustry() != null) {
                    industry = s.getIndustry().name();
                }
            }
        }

        String effectiveRole = role != null ? role : "STORE_MANAGER";
        TenantContext.set(TenantContext.TenantInfo.builder()
                .userId(userId)
                .username(username)
                .tenantId(tenantId != null ? tenantId : "T001")
                .storeId(storeId != null && !storeId.isEmpty() ? storeId : (("T001".equalsIgnoreCase(tenantId) || "PLATFORM".equalsIgnoreCase(tenantId)) ? "S001" : null))
                .role(effectiveRole)
                .industry(industry != null ? industry : "BEAUTY")
                .authenticated(true)
                .build());

        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                username, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + effectiveRole)));
        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private java.util.Optional<com.seahorse.store.domain.iam.model.Store> findStoreCached(String storeId) {
        if (!StringUtils.hasText(storeId)) {
            return java.util.Optional.empty();
        }
        String key = storeId.trim();
        long now = System.currentTimeMillis();
        CachedStore cached = storeCache.get(key);
        if (cached != null && cached.expiresAt > now) {
            return java.util.Optional.ofNullable(cached.store);
        }
        java.util.Optional<com.seahorse.store.domain.iam.model.Store> loaded = storeRepository.findByStoreId(key);
        if (storeCache.size() >= STORE_CACHE_MAX_SIZE) {
            storeCache.clear();
        }
        storeCache.put(key, new CachedStore(loaded.orElse(null), now + STORE_CACHE_TTL_MS));
        return loaded;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String token = resolveToken(request);
            Claims claims = null;
            OneIdPrincipal oneId = null;
            if (StringUtils.hasText(token)) {
                try {
                    claims = jwtUtil.parseToken(token);
                } catch (Exception ignored) {
                    // 非海马原生 JWT：自动回源 FWPT OneID 通行证核验并缓存
                    oneId = verifyOneIdToken(token);
                }
            }
            if (claims != null) {
                Object uidObj = claims.get("userId");
                Long userId = uidObj instanceof Number ? ((Number) uidObj).longValue() : 1L;
                applyAuthenticatedContext(
                        request,
                        userId,
                        claims.get("username", String.class),
                        claims.get("tenantId", String.class),
                        claims.get("storeId", String.class),
                        claims.get("role", String.class),
                        claims.get("industry", String.class)
                );
            } else if (oneId != null) {
                applyAuthenticatedContext(
                        request,
                        oneId.getUserId(),
                        oneId.getUsername(),
                        oneId.getTenantId(),
                        oneId.getStoreId(),
                        oneId.getRole(),
                        "BEAUTY"
                );
            } else {
                // 未携带有效 JWT 令牌：仅提取请求头中的公开门店/租户定位上下文，不授予已登录 Security 权限
                String headerTenantId = request.getHeader("X-Tenant-Id");
                String headerStoreId = request.getHeader("X-Store-Id");
                String headerUsername = request.getHeader("X-User-Name");
                if (StringUtils.hasText(headerUsername)) {
                    try {
                        headerUsername = java.net.URLDecoder.decode(headerUsername.trim(), java.nio.charset.StandardCharsets.UTF_8);
                    } catch (Exception ignored) {}
                }
                String effUser = StringUtils.hasText(headerUsername) ? headerUsername.trim() : "guest";
                String effStore = StringUtils.hasText(headerStoreId) ? headerStoreId.trim() : null;
                String effTenant = StringUtils.hasText(headerTenantId) ? headerTenantId.trim() : null;
                String effIndustry = "BEAUTY";

                if (StringUtils.hasText(effStore)) {
                    java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = findStoreCached(effStore.trim());
                    if (sOpt.isPresent()) {
                        com.seahorse.store.domain.iam.model.Store s = sOpt.get();
                        if (s.getTenantId() != null && !s.getTenantId().trim().isEmpty()) {
                            effTenant = s.getTenantId();
                        }
                        if (s.getIndustry() != null) {
                            effIndustry = s.getIndustry().name();
                        }
                    }
                }
                if (!StringUtils.hasText(effTenant) || "PLATFORM".equalsIgnoreCase(effTenant)) {
                    effTenant = "T001";
                }
                if (!StringUtils.hasText(effStore) && "T001".equalsIgnoreCase(effTenant)) {
                    effStore = "S001";
                }

                TenantContext.set(TenantContext.TenantInfo.builder()
                        .userId(null)
                        .username(effUser)
                        .tenantId(effTenant)
                        .storeId(effStore)
                        .role(null)
                        .industry(effIndustry)
                        .authenticated(false)
                        .build());
            }
            filterChain.doFilter(request, response);
        } finally {
            TenantContext.clear();
        }
    }

    private String resolveToken(HttpServletRequest request) {
        String bearer = request.getHeader("Authorization");
        if (StringUtils.hasText(bearer) && bearer.startsWith("Bearer ")) {
            return bearer.substring(7);
        }
        return null;
    }
}
