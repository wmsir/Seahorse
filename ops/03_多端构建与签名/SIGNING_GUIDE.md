# 海马智慧门店 (Seahorse Store) 全平台双模生产签名与 CI 配置指南

本指南说明独立 GitHub 仓库 [`https://github.com/wmsir/Seahorse`](https://github.com/wmsir/Seahorse) 下 `.github/workflows/build-seahorse-clients.yml` 的**五端双模自动签名机制**（Dual-Mode Production Signing）及本地密钥生成、Base64 编码和 GitHub Actions Secrets 配置方法。

---

## 一、双模构建架构总览（零阻塞开箱即用 + 有证自动正式签名）

流水线在每次构建时会自动探测对应平台的 GitHub Repository Secrets：

| 目标平台 | 构建 Job | 已配置生产签名 Secrets（正式签名模式） | 未配置 Secrets（优雅回退模式） |
| :--- | :--- | :--- | :--- |
| **Android** | `build-android-flutter` | 自动解码 `upload-keystore.jks` 与 `key.properties`，产出 **V1/V2/V3 生产正式签名** `seahorse_app-v1.0.0-android.apk`（可直接上架国内应用市场 / 覆盖升级） | 自动回退至兼容签名 (`signingConfigs.debug`)，正常产出可安装 APK |
| **iOS** | `build-ios-flutter` | 自动创建临时钥匙串 `seahorse-build.keychain`，导入 `.p12` 与 `.mobileprovision`，渲染 `ios/ExportOptions.plist` 执行 `flutter build ipa`，产出 **`seahorse_app-v1.0.0-ios-signed.ipa`**（可直传 App Store Connect / TestFlight 或 Ad-Hoc 分发） | 执行 `flutter build ios --release --no-codesign` 并封装 `Payload/Runner.app`，产出 **`seahorse_app-v1.0.0-ios-unsigned.ipa`**（支持爱思助手 / AltStore / Sideloadly 重签安装） |
| **HarmonyOS NEXT** | `build-harmonyos-hap` | `ohos/configure_ohos_signing.py` 自动解码 `.p12` / `.cer` / `.p7b` 至临时目录 `ohos/signing/` 并注入 `build-profile.json5`，产出 **`SHA256withECDSA` 正式签名 `.hap`** | 保持 `signingConfigs: []` 原样不动，平滑产出未签名 `.hap` 安装包 |
| **macOS Desktop** | `build-macos-tauri` | 自动注入 Apple `Developer ID Application` 证书完成 `.app` / Universal `.dmg` 代码签名，并在提供 Apple ID 时自动完成 **Apple Notary Service 公证**与 Tauri Updater 签名 | 自动清空未设置的签名环境变量，编译输出 Universal (`Apple Silicon + Intel`) `.dmg` 与 `.app.tar.gz` |
| **Windows Desktop** | `build-windows-tauri` | 自动启用 Tauri Updater 签名，并在提供 `.pfx` 代码签名证书时调用 Windows SDK `signtool.exe` 对 NSIS `setup.exe`、`.msi` 与 `seahorse_desktop.exe` 执行 **SHA-256 Authenticode 时间戳数字签名** | 平滑产出标准未签名 NSIS 安装程序、MSI 安装包与独立绿色版 `.exe` |

> **安全铁律**：所有私钥、证书密码、`.jks` / `.p12` / `.pfx` / `.mobileprovision` / `.cer` / `.p7b` 及导出的 Base64 `.txt` 均**严禁进入 Git 仓库**，本地统一存放于已被 `.gitignore` 屏蔽的 `.secrets/seahorse_signing/` 安全目录中。

---

## 二、本地一键生成与 Base64 编码工具

位于仓库根目录下的 `ops/03_多端构建与签名/`：

- **`generate_and_encode_signing.bat`**（双击交互运行或命令行传参）
- **`generate_and_encode_signing.ps1`**（PowerShell 核心引擎）

### 常用命令示例

```powershell
# 1. 一键生成 Android 生产签名证书 (.jks) 并自动导出单行 Base64 (.txt) 至 .secrets\seahorse_signing\
.\ops\03_多端构建与签名\generate_and_encode_signing.bat -NonInteractive

# 2. 将从 Apple Developer / 华为 AppGallery / CA 机构下载的任意证书或描述文件批量编码为 GitHub Secret 专用 Base64
powershell -ExecutionPolicy Bypass -File .\ops\03_多端构建与签名\generate_and_encode_signing.ps1 -EncodeOnly -InputPath "D:\certs\ios_dist.p12" -NonInteractive

# 3. 批量编码某个文件夹下的全部 .p12 / .mobileprovision / .cer / .p7b / .pfx
powershell -ExecutionPolicy Bypass -File .\ops\03_多端构建与签名\generate_and_encode_signing.ps1 -EncodeOnly -InputPath "D:\certs" -NonInteractive
```

生成产物统一保存在本地 Git 忽略目录 `.secrets\seahorse_signing\`：
- `seahorse-release.jks`：Android 生产发布密钥库（RSA 2048-bit，有效期 10,000 天）
- `SEAHORSE_ANDROID_KEYSTORE_BASE64.txt`：可直接全选粘贴至同名 GitHub Secret 的单行 Base64 文本
- `android_signing_credentials.txt`：记录自动生成的随机强密码、Alias 以及用于微信开放平台 / 高德地图备案的 `SHA-1` 与 `SHA-256` 证书公开指纹

---

## 三、全平台 GitHub Actions Secrets 完整配置表

在 GitHub 仓库（`https://github.com/wmsir/Seahorse`）页面进入 **Settings → Secrets and variables → Actions → New repository secret**，按需添加以下条目（未配置任何平台的 Secret 时，该平台自动走无签名回退分支，不会导致流水线报错）：

### 1. Android 移动端 (`build-android-flutter`)

| Secret 名称 | 必填 | 取值来源 / 说明 |
| :--- | :---: | :--- |
| `SEAHORSE_ANDROID_KEYSTORE_BASE64` | 签名必填 | `.secrets\seahorse_signing\SEAHORSE_ANDROID_KEYSTORE_BASE64.txt` 全文（单行 Base64） |
| `SEAHORSE_ANDROID_STORE_PASSWORD` | 签名必填 | `.secrets\seahorse_signing\android_signing_credentials.txt` 中的密钥库密码 |
| `SEAHORSE_ANDROID_KEY_ALIAS` | 推荐 | 密钥别名（默认工具生成值为 `seahorse`） |
| `SEAHORSE_ANDROID_KEY_PASSWORD` | 推荐 | 私钥密码（PKCS12 格式与 `SEAHORSE_ANDROID_STORE_PASSWORD` 一致；留空时自动复用 Store Password） |

### 2. iOS 移动端 (`build-ios-flutter`)

| Secret 名称 | 必填 | 取值来源 / 说明 |
| :--- | :---: | :--- |
| `SEAHORSE_IOS_P12_BASE64` | 签名必填 | Apple Distribution（或 Development）`.p12` 证书经工具导出的单行 Base64 |
| `SEAHORSE_IOS_P12_PASSWORD` | 签名必填 | 从钥匙串访问 (Keychain Access) 导出 `.p12` 时设置的密码 |
| `SEAHORSE_IOS_PROVISION_BASE64` | 签名必填 | Apple Developer 后台下载的 `.mobileprovision` 描述文件单行 Base64（自动解析 UUID / TeamID / ProfileName） |
| `SEAHORSE_IOS_EXPORT_METHOD` | 可选 | 导出类型：`app-store`（默认，上架 App Store / TestFlight）、`ad-hoc`、`enterprise` 或 `development` |
| `SEAHORSE_IOS_TEAM_ID` | 可选 | 10 位 Apple Developer Team ID（默认自动从 `.mobileprovision` 的 `TeamIdentifier` 提取） |
| `SEAHORSE_IOS_SIGNING_STYLE` | 可选 | `manual`（默认，配合 `.mobileprovision` 精确签名）或 `automatic` |

### 3. HarmonyOS NEXT 纯血鸿蒙端 (`build-harmonyos-hap`)

| Secret 名称 | 必填 | 取值来源 / 说明 |
| :--- | :---: | :--- |
| `SEAHORSE_OHOS_P12_BASE64` | 签名必填 | 鸿蒙应用发布密钥库 `.p12` 文件的单行 Base64 |
| `SEAHORSE_OHOS_CER_BASE64` | 签名必填 | 华为 AppGallery Connect 签发的发布证书 `.cer` 文件的单行 Base64 |
| `SEAHORSE_OHOS_P7B_BASE64` | 签名必填 | 华为 AppGallery Connect 下载的发布 Profile `.p7b` 文件的单行 Base64 |
| `SEAHORSE_OHOS_STORE_PASSWORD` | 签名必填 | DevEco Studio `build-profile.json5` 中的 `storePassword`（密文或对应口令） |
| `SEAHORSE_OHOS_KEY_ALIAS` | 签名必填 | 鸿蒙密钥别名 `keyAlias` |
| `SEAHORSE_OHOS_KEY_PASSWORD` | 推荐 | DevEco Studio `build-profile.json5` 中的 `keyPassword`（留空时默认复用 `SEAHORSE_OHOS_STORE_PASSWORD`） |
| `SEAHORSE_OHOS_BUNDLE_NAME` | 可选 | 若华为 AGC 注册包名与默认 `com.seahorse.store.app` 不同，设置此项可在构建时自动覆写 `AppScope/app.json5` |

### 4. macOS 桌面客户端 (`build-macos-tauri`)

| Secret 名称 | 必填 | 取值来源 / 说明 |
| :--- | :---: | :--- |
| `APPLE_CERTIFICATE` | 可选 | macOS `Developer ID Application` `.p12` 证书的单行 Base64（Tauri v2 原生识别） |
| `APPLE_CERTIFICATE_PASSWORD` | 可选 | `APPLE_CERTIFICATE` 导出密码 |
| `APPLE_SIGNING_IDENTITY` | 可选 | 证书签名标识，例如 `Developer ID Application: Your Company Name (TEAMID)` |
| `APPLE_ID` | 可选 | 用于 Apple 公证 (Notarization) 的 Apple ID 邮箱 |
| `APPLE_PASSWORD` | 可选 | 在 `appleid.apple.com` 生成的 **App 专用密码 (App-Specific Password)** |
| `APPLE_TEAM_ID` | 可选 | 10 位 Apple Developer Team ID |
| `TAURI_SIGNING_PRIVATE_KEY` | 可选 | `cargo tauri signer generate` 生成的桌面端热更新私钥内容 |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | 可选 | Tauri 热更新私钥密码 |

### 5. Windows 桌面客户端 (`build-windows-tauri`)

| Secret 名称 | 必填 | 取值来源 / 说明 |
| :--- | :---: | :--- |
| `SEAHORSE_WINDOWS_PFX_BASE64` | 可选 | Windows OV/EV 代码签名证书 `.pfx` 的单行 Base64（配置后自动使用 `signtool` 对 `.exe` 与 `.msi` 签名并加盖 DigiCert 时间戳） |
| `SEAHORSE_WINDOWS_PFX_PASSWORD` | 可选 | `.pfx` 代码签名证书密码 |
| `TAURI_SIGNING_PRIVATE_KEY` | 可选 | Tauri v2 构建产物更新签名私钥（与 macOS 共用同一 Secret） |
| `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` | 可选 | Tauri v2 构建产物更新签名私钥密码 |

---

## 四、触发全平台云端构建与自动发版

1. **手动按需触发单端或全端构建**：
   在 GitHub 仓库（[`https://github.com/wmsir/Seahorse/actions/workflows/build-seahorse-clients.yml`](https://github.com/wmsir/Seahorse/actions/workflows/build-seahorse-clients.yml)）进入 **Actions → 构建海马智慧门店全平台客户端 (Seahorse Multi-Platform Clients) → Run workflow**，选择 `all` 或单独选择 `android` / `ios` / `harmonyos` / `windows` / `macos`。
2. **Tag 正式发版（自动汇聚五端产物 + 生成 `SHA256SUMS-seahorse.txt` + 发布 GitHub Release）**：
   推送 `seahorse-v*` 标签（例如 `git push origin seahorse-v1.0.0`），或使用同目录下的 `.\ops\03_多端构建与签名\trigger_github_build.bat` 一键推送并触发云端流水线。
