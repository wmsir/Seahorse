# 海马智慧门店桌面客户端 (`SeahorseStore Desktop`)

基于 **Rust + Tauri v2** 构建的海马智慧门店原生跨平台桌面收银与全场景履约客户端，同时支持 **Windows (x64 NSIS `.exe` / `.msi` / 独立可执行文件)** 与 **macOS (Universal `aarch64 + x86_64` `.dmg` / `.app`)**。

---

## 一、核心架构与特性

| 维度 | 说明 |
| --- | --- |
| **桌面内核** | Rust `2021` + Tauri `v2` (`SeahorseStore`, `com.seahorse.desktop`) |
| **前端构建产物** | 复用 `../seahorse_web_front/dist-desktop` (`npm run build:desktop` Hash 路由离线静态包) |
| **默认主窗口** | `1400 × 900`（最小 `1024 × 680`，居中启动，暴露 `window.__TAURI__` 全局对象） |
| **系统托盘** | 原生托盘图标与右键菜单（`显示主窗口` / `退出系统`），左键单击或双击快速唤醒还原主窗口 |
| **原生 IPC 能力** | 本地持久化服务端地址配置（`seahorse_desktop/config.json`）、运行环境诊断、后端 TCP/HTTP 连通性探测 |

### 暴露给前端的 Tauri IPC 命令 (`window.__TAURI__.core.invoke`)

1. **`get_desktop_config()`**
   - 读取（首次自动初始化）操作系统配置目录下的 `seahorse_desktop/config.json`：
     - Windows: `%APPDATA%\seahorse_desktop\config.json`
     - macOS: `~/Library/Application Support/seahorse_desktop/config.json`
   - 返回：`{ apiBaseUrl: string, configPath: string, updatedAt: number }`（默认 `https://fwpt.cn/api`）。
2. **`save_desktop_config({ apiBaseUrl })`**
   - 校验并持久化自定义后端 API 网关地址（如云端生产 `https://fwpt.cn/api`、本地联调 `http://127.0.0.1:8082/api` 或私有化部署地址）。
3. **`get_desktop_runtime_info()`**
   - 返回当前桌面端操作系统、CPU 架构、版本号与配置文件路径元数据。
4. **`probe_backend_server({ apiBaseUrl, timeoutMs })`**
   - 原生非阻塞探测目标服务端 DNS / TCP / HTTP `/ping` 连通状态与毫秒级延迟。
5. **`show_main_window()`**
   - 主动显示、取消最小化并聚焦主窗口。

---

## 二、本地开发与联调

### 1. 环境准备
- **Node.js** `>= 20`
- **Rust** `stable` (`rustup` 工具链)
- **Windows 依赖**：Microsoft Visual Studio C++ Build Tools + WebView2 Runtime（Win10/Win11 已内置）
- **macOS 依赖**：Xcode Command Line Tools (`xcode-select --install`)
- **Tauri CLI v2**：
  ```bash
  cargo install tauri-cli --version "^2.0.0" --locked
  ```

### 2. 启动热更新开发模式
1. 先启动前端开发服务器（监听 `http://localhost:3000/seahorse/`）：
   ```bash
   cd ../seahorse_web_front
   npm install
   npm run dev
   ```
2. 在另一个终端启动 Tauri 桌面容器：
   ```bash
   cd ../seahorse_desktop/src-tauri
   cargo tauri dev
   ```

---

## 三、生产打包指南（Windows & macOS）

### 第一步：构建桌面专用前端静态包 (`dist-desktop`)
```bash
cd seahorse/seahorse_web_front
npm ci
npm run build:desktop
```
> 该命令会执行 TypeScript 类型检查并将启用相对路径 (`base: './'`) 与 Hash 路由模式的静态资源输出至 `seahorse/seahorse_web_front/dist-desktop`。

### 第二步（Windows）：编译 Windows 安装包与独立 `.exe`
```powershell
cd seahorse/seahorse_desktop/src-tauri
cargo check
cargo tauri build
```
构建产物位于：
- **NSIS 安装包 (推荐分发)**：`src-tauri/target/release/bundle/nsis/SeahorseStore_1.0.0_x64-setup.exe`
- **MSI 安装包**：`src-tauri/target/release/bundle/msi/SeahorseStore_1.0.0_x64_en-US.msi`
- **免安装单文件可执行程序**：`src-tauri/target/release/seahorse_desktop.exe`

### 第二步（macOS）：编译 Apple Silicon + Intel 通用架构 `.dmg`
```bash
rustup target add aarch64-apple-darwin x86_64-apple-darwin
cd seahorse/seahorse_desktop/src-tauri
cargo tauri build --target universal-apple-darwin
```
构建产物位于：
- **Universal DMG 镜像**：`src-tauri/target/universal-apple-darwin/release/bundle/dmg/SeahorseStore_1.0.0_universal.dmg`
- **macOS App Bundle**：`src-tauri/target/universal-apple-darwin/release/bundle/macos/SeahorseStore.app`

---

## 四、GitHub Actions 云端多平台自动构建

仓库已内置跨平台构建流水线 [`.github/workflows/build-seahorse-clients.yml`](../../.github/workflows/build-seahorse-clients.yml)：
- **手动按需触发 (`workflow_dispatch`)**：在 GitHub Actions 页面选择 `all`、`windows`、`macos`、`ios`、`harmonyos` 或 `android` 即可一键云端编译并下载对应平台构建产物。
- **版本标签自动发版 (`push tags: seahorse-v*`)**：推送如 `git tag seahorse-v1.0.0 && git push origin seahorse-v1.0.0` 时，自动并行构建五大客户端并发布至 GitHub Releases。
