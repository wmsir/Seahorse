# 海马智慧商业平台 - 运维与诊断脚本库 (Scripts)

本目录集中存放日常运维与数据初始化所需的 Python 工具脚本：

### 1. 数据库与业务数据工具
- **`reset_and_init_data.py`**
  - 用途：阿里云 RDS MySQL 数据库清空并初始化全套标准业务演示数据（商户、门店、工位、会员、次卡、商品等）。
  - 执行方式：`python scripts/reset_and_init_data.py`

### 2. 发布与部署引擎
- 发布核心引擎位于 `ops/02_远程Docker部署/deploy_engine.py`，支持一键热部署前端、后端及本地 APK 打包。
