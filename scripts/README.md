# 海马智慧商业平台 - 运维与诊断脚本库 (Scripts)

本目录集中存放日常运维、数据初始化与系统诊断所需的 Python 工具脚本：

### 1. 数据库与业务数据工具
- **eset_and_init_data.py**
  - 用途：阿里云 RDS MySQL 数据库清空并初始化全套标准业务演示数据（商户、门店、工位、会员、次卡、商品等）。
  - 执行方式：python scripts/reset_and_init_data.py

- **check_rds_schemas.py**
  - 用途：连通阿里云 RDS MySQL，快速检查表结构、租户/门店数据、会员等级分布与高德地图 Key。
  - 执行方式：python scripts/check_rds_schemas.py

### 2. 云端容器与服务器检测工具
- **check_server_docker.py**
  - 用途：SSH 远程连接 39.97.158.22 云端服务器，查看 Docker 容器运行状态 (docker ps) 及 seahorse-back 最新日志。
  - 执行方式：python scripts/check_server_docker.py

### 3. 发布与部署引擎
- 发布核心引擎位于 ops/02_远程Docker部署/deploy_engine.py，支持一键热部署前端、后端及本地 APK 打包。
