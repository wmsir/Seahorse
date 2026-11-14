# 海马智慧商业平台 - 运维与诊断脚本库 (Scripts)

本目录集中存放日常运维与数据初始化所需的 Python 工具脚本：

### 1. 数据库与业务数据工具
- **`reset_and_init_data.py`**
  - 用途：MySQL 数据库清空测试业务流水并幂等初始化标准演示数据（双租户门店、默认员工账号 `admin` / `manager` / `cashier` / `tony` / `yl_manager` 密码均为 `123456`、工位、会员、双轨储值、次卡、商品及当日预约）。
  - 数据库环境变量：`SEAHORSE_DB_HOST`（默认 `127.0.0.1`）、`SEAHORSE_DB_PORT`（默认 `3306`）、`SEAHORSE_DB_USER`（默认 `root`）、`SEAHORSE_DB_PASSWORD`、`SEAHORSE_DB_NAME`（默认 `seahorse_store`）。
  - 高德地图可选环境变量：`SEAHORSE_AMAP_WEB_KEY`、`SEAHORSE_AMAP_JS_KEY`、`SEAHORSE_AMAP_SECURITY_CODE`（绝不在代码中硬编码密钥）。
  - 执行方式：`python scripts/reset_and_init_data.py`

### 2. 发布与部署引擎
- 发布核心引擎位于 `ops/02_远程Docker部署/deploy_engine.py`，支持读取 `FWPT_SSH_PASSWORD` / `FWPT_SSH_KEY` 或父仓 `.secrets/` 凭据配置，一键热部署前端、后端及移动端 APK。
