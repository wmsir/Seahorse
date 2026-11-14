# 海马 (Seahorse) ➔ 海马智慧门店 快速部署与运维手册

> 💡 **生产环境 Docker 远程打包部署与原理教程**：请参阅详细全景文档 [docs/DOCKER_DEPLOY_TUTORIAL.md](docs/DOCKER_DEPLOY_TUTORIAL.md)。  
> 🛠️ **一键运维与部署套件**：位于 [ops/](ops/) 专属目录下，或直接双击根目录的 [一键运维总控面板.bat](一键运维总控面板.bat)。

---

## 1. 系统运行环境要求

- **JDK**: Java 17+
- **Maven**: 3.8+ (后端编译)
- **Node.js**: v18.0+ / v20.0+ (前端构建与运行)
- **数据库**:
  - **开发环境 (`dev`)**: 默认连接本地 MySQL 8.0 (`127.0.0.1:3306/seahorse_store`，可通过环境变量 `SPRING_DATASOURCE_URL` / `SPRING_DATASOURCE_USERNAME` / `SPRING_DATASOURCE_PASSWORD` 覆盖)，首次启动由 `DataInitializer` 自动构建表结构并注入种子数据；单元测试/集成测试可使用内置 H2 内存数据库。
  - **生产环境 (`prod`)**: MySQL 8.0+

---

## 2. 本地极速启动 (开发模式)

### 2.1 启动后端服务 (`seahorse_back`)

```bash
cd seahorse_back

# 方式 1: 直接使用 Maven 启动 (默认端口 8082，连接本地 MySQL seahorse_store 并自动加载种子数据)
mvn spring-boot:run

# 方式 2: 打包为独立 Jar 运行
mvn clean package -DskipTests
java -jar target/seahorse-store-0.0.1-SNAPSHOT.jar
```

启动完成后：
- 后端服务端口: `http://localhost:8082`
- 健康心跳探针: `http://localhost:8082/api/health`
- OpenAPI Swagger 接口文档: `http://localhost:8082/swagger-ui.html`

### 2.2 启动 PC 管理端与收银工作台 (`seahorse_web_front`)

```bash
cd seahorse_web_front

# 安装依赖
npm install

# 启动开发热更新服务器 (默认端口 3000)
npm run dev
```

浏览器访问: `http://localhost:3000/seahorse/`
- **预置演示账号**:
  - 平台开发维护人 / 超级管理员: `admin` / `123456`
  - 店长: `manager` / `123456`
  - 前台收银员: `cashier` / `123456`
  - 托尼发型总监: `tony` / `123456`

### 2.3 构建与运行 Windows / macOS 原生桌面端 (`seahorse_desktop`)

桌面客户端基于 **Rust + Tauri v2** 构建，内置系统托盘常驻、服务端网关地址切换与连通性探测：

```bash
# 1. 生成桌面端专用前端资源包 (输出至 seahorse_web_front/dist-desktop)
cd seahorse_web_front
npm run build:desktop

# 2. 编译校验或打包原生安装包 (Windows .exe/.msi 或 macOS Universal .dmg)
cd ../seahorse_desktop/src-tauri
cargo check
cargo tauri build
```

### 2.4 移动端 APP (`seahorse_app` — Android / iOS / HarmonyOS NEXT)

- **本地构建 Android Release APK**：执行 `powershell -ExecutionPolicy Bypass -File seahorse_app/build_android.ps1` 或双击 `ops/02_远程Docker部署/deploy_app_apk.bat`。
- **全平台 CI/CD 自动构建**：仓库工作流 [`.github/workflows/build-seahorse-clients.yml`](../.github/workflows/build-seahorse-clients.yml) 支持在 GitHub Actions 中自动构建 **Windows (Tauri)、macOS Universal (Tauri)、Android (APK)、iOS (IPA) 与 HarmonyOS NEXT (HAP)** 产物。

### 2.5 导入顾客端小程序 (`seahorse_mini_program`)

1. 打开微信开发者工具。
2. 选择“导入项目”，目录指向 `c:\project\fwpt\seahorse\seahorse_mini_program`。
3. AppID 填入自己的测试号或保留默认模拟 AppID。
4. 即可在开发者工具中体验扫码点单、在场动态加项与海马会员中心。

---

## 3. 全栈环境变量管理与生产安全审计

为杜绝源码硬编码凭据（`application-prod.yml` 已完全移除硬编码生产 RDS 地址，默认连接容器网络 `seahorse-mysql:3306`），海马全栈采用 **环境变量 > `seahorse/.env` > 框架安全默认值** 的三级配置注入机制。

### 3.1 本地 `.env` 快速配置与自动加载

1. 复制根目录模板文件生成私有配置（`seahorse/.env` 已被 `.gitignore` 严格忽略，不会进入 Git 版本库）：
   ```bash
   copy .env.example .env
   ```
2. **全链路自动注入支持**：
   - **本地一键启动**：`ops/01_本地开发运行/start.ps1`、`run-backend.bat`、`run-frontend.bat` 启动时自动解析 `seahorse/.env` 中的非空变量并注入进程环境。
   - **本地 Docker Compose**：[`docker-compose.yml`](docker-compose.yml) 通过 `${VAR:-default}` 自动读取 `seahorse/.env` 并传入 `seahorse-back` 容器。
   - **远程自动化部署**：[`ops/02_远程Docker部署/deploy_engine.py`](ops/02_远程Docker部署/deploy_engine.py) 自动读取 `seahorse/.env` 与父仓 `.secrets/fwpt_credentials.json`。

### 3.2 核心环境变量矩阵

| 变量名 | 作用域 | 本地开发默认 / 示例 | 生产环境说明 |
| :--- | :--- | :--- | :--- |
| `SPRING_PROFILES_ACTIVE` | 后端 | `dev` (`docker-compose` 为 `prod`) | 生产容器固定设为 `prod` |
| `SERVER_PORT` | 后端 | `8082` | 云端 Node 2 容器运行在 `8080`（宿主机同时映射 `8080`/`8082`） |
| `SPRING_DATASOURCE_URL` | 后端 | `jdbc:mysql://127.0.0.1:3306/seahorse_store?...` | **生产必填**：外部 RDS 或独立 MySQL JDBC URL |
| `SPRING_DATASOURCE_USERNAME` | 后端 | `root` | **生产必填**：数据库最小权限账号 |
| `SPRING_DATASOURCE_PASSWORD` | 后端 | `root123456` | **生产必填**：高强度数据库口令 |
| `SEAHORSE_JWT_SECRET` | 后端 | 内置开发环境 >=32B 默认串 | **强烈建议生产注入**：至少 32 字节（256-bit）高熵随机密钥 |
| `SEAHORSE_AMAP_WEB_KEY` | 后端/脚本 | 空 | 高德开放平台 Web 服务 API Key（门店地理编码/考勤校验） |
| `SEAHORSE_AMAP_JS_KEY` | 后端/脚本 | 空 | 高德开放平台 JS API Key（服务端兜底下发） |
| `SEAHORSE_AMAP_SECURITY_CODE` | 后端/脚本 | 空 | 高德 JS API 安全密钥 `securityJsCode` |
| `VITE_AMAP_WEB_KEY` | Web 前端 | 空 | Vite 构建/开发期默认高德 Web Key |
| `VITE_AMAP_JS_KEY` | Web 前端 | 空 | Vite 构建/开发期默认高德 JS Key |
| `VITE_AMAP_SECURITY_CODE` | Web 前端 | 空 | Vite 构建/开发期默认高德安全密钥 |
| `FWPT_NODE2` / `FWPT_SSH_USER` | 远程运维 | `39.97.158.22` / `root` | 云端目标部署节点地址与 SSH 账号 |
| `FWPT_SSH_KEY` / `FWPT_SSH_PASSWORD` | 远程运维 | 空（优先读取 `.secrets/fwpt_credentials.json`） | 远程部署 SSH 私钥路径（推荐）或口令 |

### 3.3 全栈环境安全审计与防断连部署保护

- **一键只读环境审计**（全程脱敏展示，零明文输出任何密码、RDS 域名或 API Key）：
  ```bash
  # 同时审计本地配置与云端 Node 2 seahorse-back 容器环境变量（或双击 ops/02_远程Docker部署/check_env.bat）
  python scripts/check_seahorse_env.py

  # 仅审计本地环境 / 仅只读审计云端容器
  python scripts/check_seahorse_env.py --local
  python scripts/check_seahorse_env.py --remote
  ```
- **`deploy_engine.py` 生产防断连预检与加密注入**：
  - 每次执行 `deploy_engine.py --backend`（或 `--all`）在覆盖 `app.jar` 并重启 `seahorse-back` 前，都会自动检查云端容器 `Config.Env` 中的 `SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_USERNAME`、`SPRING_DATASOURCE_PASSWORD`。
  - 若检测到云端容器缺失 `SPRING_DATASOURCE_URL`（或误指不存在的 `seahorse-mysql` 容器），引擎会**自动拒绝盲目覆盖重启**，防止因移除 `application-prod.yml` 硬编码地址导致线上数据库断连。
  - 如需首次初始化或补齐云端容器环境变量，可在 `.secrets/fwpt_credentials.json` 中配置 `seahorse_db_url`（或 `db_host`）、`db_user`、`db_password`、`seahorse_jwt_secret` 后运行：
    ```bash
    python ops/02_远程Docker部署/deploy_engine.py --backend --inject-env
    ```
    引擎将通过 SFTP 加密通道生成权限 `0600` 的 `/opt/seahorse/.env`（不在命令行或日志回显任何密钥）并执行 `docker compose up -d seahorse-back`。

---

## 4. 生产环境 Docker 容器化部署

系统根目录提供了一键部署编排文件 [`docker-compose.yml`](docker-compose.yml)：

```bash
# 1. 启动全套服务 (MySQL 8.0 + 后端微服务 + 前端 Nginx)
docker compose up -d

# 2. 查看容器运行状态
docker compose ps

# 3. 查看后端运行日志
docker compose logs -f seahorse-back
```

---

## 5. 数据库全量初始化

若直接连接独立 MySQL 数据库，按顺序执行 `sql/` 目录下的脚本：
1. `sql/schema.sql`: 创建全量表结构、乐观锁版本列（`version`）与核心索引。
2. `sql/init_data.sql`: 导入 7 大支持业态（美业、餐饮、汽修、专营零售、足疗养生、茶馆棋牌、宠物门店）基础分类、商品、服务、BOM 配方与“海马体”记忆会员档案。
3. `sql/migrations/V*.sql`: 按版本号顺序执行增量索引与结构迁移脚本（幂等可重入）。
