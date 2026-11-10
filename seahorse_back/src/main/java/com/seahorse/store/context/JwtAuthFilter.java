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
            if (StringUtils.hasText(token) && jwtUtil.validateToken(token)) {
                Claims claims = jwtUtil.parseToken(token);
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
                        || "T001".equalsIgnoreCase(jwtTenantId)
                        || "PLATFORM_DEVELOPER".equalsIgnoreCase(role);

                String headerStoreId = request.getHeader("X-Store-Id");
                String headerTenantId = request.getHeader("X-Tenant-Id");
                if (isPlatformAdmin && StringUtils.hasText(headerTenantId)) {
                    tenantId = headerTenantId.trim();
                }

                // 若指定了请求头门店ID，校验该门店是否归属当前租户（或当前为平台管理员），防止旧缓存跨租户污染
                if (StringUtils.hasText(headerStoreId)) {
                    String candidateStoreId = headerStoreId.trim();
                    java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = storeRepository.findByStoreId(candidateStoreId);
                    if (sOpt.isPresent()) {
                        com.seahorse.store.domain.iam.model.Store s = sOpt.get();
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

                // 若当前选定门店存在，同步其真实行业属性
                if (StringUtils.hasText(storeId)) {
                    java.util.Optional<com.seahorse.store.domain.iam.model.Store> sOpt = storeRepository.findByStoreId(storeId.trim());
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

                TenantContext.set(TenantContext.TenantInfo.builder()
                        .userId(userId)
                        .username(username)
                        .tenantId(tenantId != null ? tenantId : "T001")
                        .storeId(storeId != null && !storeId.isEmpty() ? storeId : (("T001".equalsIgnoreCase(tenantId) || "PLATFORM".equalsIgnoreCase(tenantId)) ? "S001" : null))
                        .role(role != null ? role : "STORE_MANAGER")
                        .industry(industry != null ? industry : "BEAUTY")
                        .build());

                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        username, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role)));
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } else {
                // 默认上下文用于方便测试或免登开发模式
                String headerTenantId = request.getHeader("X-Tenant-Id");
                String headerStoreId = request.getHeader("X-Store-Id");
                String headerUsername = request.getHeader("X-User-Name");
                if (StringUtils.hasText(headerUsername)) {
                    try {
                        headerUsername = java.net.URLDecoder.decode(headerUsername.trim(), java.nio.charset.StandardCharsets.UTF_8);
                    } catch (Exception ignored) {}
                }
                String effUser = StringUtils.hasText(headerUsername) ? headerUsername.trim() : "admin";
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
                if (!StringUtils.hasText(effTenant)) {
                    effTenant = "T001";
                }
                if (!StringUtils.hasText(effStore) && ("T001".equalsIgnoreCase(effTenant) || "PLATFORM".equalsIgnoreCase(effTenant))) {
                    effStore = "S001";
                }

                TenantContext.set(TenantContext.TenantInfo.builder()
                        .userId(1L)
                        .username(effUser)
                        .tenantId(effTenant)
                        .storeId(effStore)
                        .role("STORE_MANAGER")
                        .industry(effIndustry)
                        .build());

                UsernamePasswordAuthenticationToken guestAuth = new UsernamePasswordAuthenticationToken(
                        effUser, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_STORE_MANAGER")));
                SecurityContextHolder.getContext().setAuthentication(guestAuth);
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
