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

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        try {
            String token = resolveToken(request);
            Claims claims = null;
            if (StringUtils.hasText(token)) {
                try {
                    claims = jwtUtil.parseToken(token);
                } catch (Exception ignored) {
                    // 非本系统签发的外部令牌走下方免登/请求头上下文分支
                }
            }
            if (claims != null) {
                Object uidObj = claims.get("userId");
                Long userId = uidObj instanceof Number ? ((Number) uidObj).longValue() : 1L;
                String username = claims.get("username", String.class);
                String tenantId = claims.get("tenantId", String.class);
                String storeId = claims.get("storeId", String.class);
                String role = claims.get("role", String.class);
                String industry = claims.get("industry", String.class);

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

                // 若指定了请求头门店ID，校验该门店是否归属当前租户（或当前为平台管理员），防止旧缓存跨租户污染
                if (StringUtils.hasText(headerStoreId)) {
                    String candidateStoreId = headerStoreId.trim();
                    lookedUpStoreId = candidateStoreId;
                    lookedUpStoreOpt = storeRepository.findByStoreId(candidateStoreId);
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

                // 若当前选定门店存在，同步其真实行业属性（复用上方已查询结果，避免每次请求重复 SELECT）
                if (StringUtils.hasText(storeId)) {
                    String trimmedStoreId = storeId.trim();
                    java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = trimmedStoreId.equals(lookedUpStoreId)
                            ? lookedUpStoreOpt
                            : storeRepository.findByStoreId(trimmedStoreId);
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
                    java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = storeRepository.findByStoreId(effStore.trim());
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
