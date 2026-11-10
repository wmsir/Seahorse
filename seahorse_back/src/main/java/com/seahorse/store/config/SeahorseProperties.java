package com.seahorse.store.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "seahorse")
public class SeahorseProperties {
    private String appName = "海马智慧门店";
    private String slogan = "海马会员，记住每位好客。";
    private String industry = "BEAUTY"; // RESTAURANT | BEAUTY | AUTO | RETAIL
    private String defaultTenantId = "T001";
    private String defaultStoreId = "S001";
    private Security security = new Security();
    private Pay pay = new Pay();
    private DualBalance dualBalance = new DualBalance();
    private Device device = new Device();

    @Data
    public static class Security {
        private String jwtSecret;
        private Long accessTokenExpirationMinutes = 120L;
        private Long refreshTokenExpirationDays = 7L;
    }

    @Data
    public static class Pay {
        private Boolean mockEnabled = true;
        private Wechat wechat = new Wechat();

        @Data
        public static class Wechat {
            private String appId = "wx_mock_seahorse_app";
            private String mchId = "1900000001";
        }
    }

    @Data
    public static class DualBalance {
        // PROPORTIONAL (按本金/赠金比例分摊) | PRINCIPAL_FIRST (优先扣除本金)
        private String deductMode = "PROPORTIONAL";
    }

    @Data
    public static class Device {
        private Boolean cashDrawerPulseEnabled = true;
        private Boolean receiptPrinterEnabled = true;
    }
}
