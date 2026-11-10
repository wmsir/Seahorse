# 海马 (Seahorse) ➔ 海马智慧门店 快速部署与运维手册

> 💡 **生产环境 Docker 远程打包部署与原理教程**：请参阅详细全景文档 [docs/DOCKER_DEPLOY_TUTORIAL.md](docs/DOCKER_DEPLOY_TUTORIAL.md)。  
> 🛠️ **一键运维与部署套件**：位于 [ops/](ops/) 专属目录下，或直接双击根目录的 [一键运维总控面板.bat](一键运维总控面板.bat)。

---

## 1. 系统运行环境要求

- **JDK**: Java 17+
- **Maven**: 3.8+ (后端编译)
- **Node.js**: v18.0+ / v20.0+ (前端构建与运行)
- **数据库**:
  - **开发环境**: 内置开箱即用内存数据库（无需安装 MySQL 即可本地直接运行体验）。
  - **生产环境**: MySQL 8.0+

---

## 2. 本地极速启动 (开发模式)

### 2.1 启动后端服务 (`seahorse_back`)

```bash
cd seahorse_back

# 方式 1: 直接使用 Maven 启动 (默认端口 8082，内置 H2 零配置数据库并自加载种子数据)
mvn spring-boot:run

# 方式 2: 打包为独立 Jar 运行
mvn clean package -DskipTests
java -jar target/seahorse-store-0.0.1-SNAPSHOT.jar
```

启动完成后：
- 后端服务端口: `http://localhost:8082`
- OpenAPI Swagger 接口文档: `http://localhost:8082/swagger-ui.html`
- H2 控制台: `http://localhost:8082/h2-console` (JDBC URL: `jdbc:h2:mem:seahorse_db`)

### 2.2 启动 PC 管理端与收银工作台 (`seahorse_web_front`)

```bash
cd seahorse_web_front

# 安装依赖
npm install

# 启动开发热更新服务器 (默认端口 3000)
npm run dev
```

浏览器访问: `http://localhost:3000`
- **预置演示账号**:
  - 超级管理员/老板: `admin` / `123456`
  - 店长: `manager` / `123456`
  - 前台收银员: `cashier` / `123456`
  - 托尼发型总监: `tony` / `123456`

### 2.3 导入顾客端小程序 (`seahorse_mini_program`)

1. 打开微信开发者工具。
2. 选择“导入项目”，目录指向 `c:\project\fwpt\seahorse\seahorse_mini_program`。
3. AppID 填入自己的测试号或保留默认模拟 AppID。
4. 即可在开发者工具中体验扫码点单、在场动态加项与海马会员中心。

---

## 3. 生产环境 Docker 容器化部署

系统根目录提供了一键部署编排文件 [`docker-compose.yml`](docker-compose.yml)：

```bash
# 1. 启动全套服务 (MySQL 8.0 + 后端微服务 + 前端 Nginx)
docker-compose up -d

# 2. 查看容器运行状态
docker-compose ps

# 3. 查看后端运行日志
docker-compose logs -f seahorse-back
```

---

## 4. 数据库全量初始化

若直接连接独立 MySQL 数据库，按顺序执行 `sql/` 目录下的脚本：
1. `sql/schema.sql`: 创建表结构与索引。
2. `sql/init_data.sql`: 导入全行业多模态（美业、餐饮、汽修）分类、商品、服务、BOM配方与“海马体”记忆会员档案。
