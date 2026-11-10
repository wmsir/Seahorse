package com.seahorse.store.context;

import com.seahorse.store.config.SeahorseProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class JwtUtil {

    private final SeahorseProperties properties;

    @jakarta.annotation.PostConstruct
    public void validateSecret() {
        String secret = properties.getSecurity().getJwtSecret();
        if (secret == null || secret.trim().getBytes(java.nio.charset.StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("CRITICAL SECURITY VIOLATION: seahorse.security.jwt-secret must be provided and must be at least 32 bytes in length!");
        }
    }

    private Key getSigningKey() {
        byte[] keyBytes = properties.getSecurity().getJwtSecret().getBytes(java.nio.charset.StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    public String generateToken(Long userId, String username, String tenantId, String storeId, String role, String industry) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("username", username);
        claims.put("tenantId", tenantId);
        claims.put("storeId", storeId);
        claims.put("role", role);
        claims.put("industry", industry);

        long expMillis = System.currentTimeMillis() + properties.getSecurity().getAccessTokenExpirationMinutes() * 60 * 1000;
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(username)
                .setIssuedAt(new Date())
                .setExpiration(new Date(expMillis))
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    public Claims parseToken(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public boolean validateToken(String token) {
        try {
            Claims claims = parseToken(token);
            return !claims.getExpiration().before(new Date());
        } catch (Exception e) {
            return false;
        }
    }
}
