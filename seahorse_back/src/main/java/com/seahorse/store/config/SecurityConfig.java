package com.seahorse.store.config;

import com.seahorse.store.context.JwtAuthFilter;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(ex -> ex
                .authenticationEntryPoint((req, resp, authEx) -> {
                    resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    resp.setCharacterEncoding(StandardCharsets.UTF_8.name());
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"code\":401,\"message\":\"未登录或登录凭证已过期，请重新登录\",\"data\":null}");
                })
                .accessDeniedHandler((req, resp, deniedEx) -> {
                    resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    resp.setCharacterEncoding(StandardCharsets.UTF_8.name());
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"code\":403,\"message\":\"权限不足，无权执行该受限操作\",\"data\":null}");
                })
            )
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                // 1. 网关健康检查与公共探测端点（生产关闭匿名 API 文档暴露）
                .requestMatchers(
                    "/api",
                    "/api/",
                    "/api/health",
                    "/api/ping",
                    "/favicon.ico",
                    "/error"
                ).permitAll()
                // 2. 认证、自助注册、找回密码与小程序免登端点
                .requestMatchers(
                    "/api/auth/login",
                    "/api/auth/oneid-exchange",
                    "/api/auth/member-login",
                    "/api/auth/member-send-code",
                    "/api/auth/register-merchant",
                    "/api/auth/plans",
                    "/api/auth/send-reset-code",
                    "/api/auth/reset-password",
                    "/api/miniapp/auth/**"
                ).permitAll()
                // 3. H5/扫码点单/自助开卡/门店基础公开只读端点（移除会员PII检索/预约/会话流水匿名访问）
                .requestMatchers(HttpMethod.GET,
                    "/api/store/info",
                    "/api/store/register-config",
                    "/api/store/common-remarks",
                    "/api/store/staff-display-mode",
                    "/api/store/notice/list",
                    "/api/store/notice/urgent-latest",
                    "/api/space/public/**",
                    "/api/space/list",
                    "/api/product/list",
                    "/api/product/categories",
                    "/api/card-template/list",
                    "/api/industry/**",
                    "/api/member/levels/rules"
                ).permitAll()
                // 4. H5/扫码点单/自助开卡/招聘/入职公开提交端点
                .requestMatchers(HttpMethod.POST,
                    "/api/member/register",
                    "/api/member/preference",
                    "/api/space/call-service",
                    "/api/space/order-notify",
                    "/api/merchant/staff/self-register",
                    "/api/job-application/submit",
                    "/api/appointment/create"
                ).permitAll()
                // 5. 平台开发商运营后台仅限平台超级管理员角色访问
                .requestMatchers("/api/vendor/**").hasAuthority("ROLE_PLATFORM_DEVELOPER")
                // 6. 其余管理后台与写接口必须携带有效 JWT 令牌
                .anyRequest().authenticated()
            )
            .headers(headers -> headers.frameOptions(frame -> frame.sameOrigin()))
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList(
            "https://fwpt.cn",
            "https://*.fwpt.cn",
            "http://localhost:*",
            "http://127.0.0.1:*",
            "tauri://localhost",
            "https://tauri.localhost"
        ));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Requested-With", "Accept", "Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers", "X-Tenant-Id", "X-Store-Id", "X-User-Name"));
        configuration.setExposedHeaders(Arrays.asList("Authorization"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
