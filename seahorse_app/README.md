# 海马智慧门店与全场景门店履约系统 - 跨平台移动端 APP (`seahorse_app`)

基于 **Flutter 3.x** 构建，原生全功能覆盖 **华为鸿蒙 (HarmonyOS NEXT / OpenHarmony)**、**谷歌安卓 (Android)** 与 **苹果 (iOS)** 三大主流移动操作系统。

---

## 一、核心业务功能实现

| 业务模块 | 功能实现说明 |
|:---|:---|
| **1. 经营总览工作台** | 今日营业流水、到店客流、在场包厢/工位动态监控、会员储值看板，集成「快速开台、新客预约、收银结账、会员开卡」4大快捷办理入口。 |
| **2. 房态与包厢工位看板** | 楼层区域自适应分类、房态矩阵（空闲可用、在场服务中、待清台复位、维护停用）、**开台入座派工**、**已上钟时长与实时账单累计**、**一键翻台清扫消毒**。 |
| **3. 预约排班与到店履约** | 预约日历时间轴（今日/明日/后天/任意日期）、**登记新顾客预约**（选择顾客、服务项目、指派技师、预留包厢）、**顾客到店一键核销开台**。 |
| **4. 移动收银与结账收银台** | 挂单包厢快速关联、多品类点单购物车（足道推拿、精油SPA、特色加项、茶歇养生、实物周边）、**多渠道支付（会员储值划扣、次卡核销、微信支付、支付宝、现金）**、**小票凭条打印与查看**。 |
| **5. 会员中心与储值次卡** | 会员模糊检索（姓名/手机/卡号）、**快速建档录入**、**会员卡储值充值（充1000送150等加油包）**、**次卡发售与扣减**。 |
| **6. 门店与多业态切换** | 支持多连锁分店无缝切换（御境云足天府环球店、万象城店、交子金融城店、海马美业体验中心），称谓自适应（养生包厢 / 造型工位）。 |

---

## 二、三端原生宿主工程目录架构

```text
seahorse_app/
├── pubspec.yaml                     # Flutter 项目依赖与配置
├── lib/                             # 100% 共享 Dart 业务逻辑代码
│   ├── main.dart                    # 应用启动入口
│   ├── app.dart                     # MaterialApp 主配置与 Provider 状态注入
│   ├── core/                        # 品牌主题规范、Dio 客户端、持久化存储、格式化工具
│   ├── models/                      # 门店、包厢房态、预约、会员、项目、技师、订单实体
│   ├── mock/                        # 真实完整离线业务模拟数据集 (御境云足全套场景)
│   ├── services/                    # 认证、门店、房态、预约、收银、会员服务 (双引擎)
│   ├── providers/                   # 6 大核心业务响应式状态管理 (Provider)
│   ├── widgets/                     # 经营指标卡片、房态卡片、状态徽章等复用组件
│   └── views/                       # 核心业务界面与模态弹窗
│
├── ohos/                            # 1. 华为鸿蒙 (OpenHarmony ArkTS Stage 模式) 原生工程
│   ├── AppScope/app.json5           # 应用全局包名、图标与配置
│   ├── build-profile.json5          # 编译 SDK 版本 (API 11 / 12) 与产品定义
│   ├── hvigorfile.ts                # hvigor 构建脚本
│   ├── oh-package.json5             # 鸿蒙三方包依赖
│   └── entry/                       # 主 Ability 模块 (HAP)
│       ├── src/main/module.json5    # 网络权限与 EntryAbility 注册
│       └── src/main/ets/
│           ├── entryability/EntryAbility.ets # FlutterAbility 引擎生命周期集成
│           └── pages/Index.ets      # FlutterPage ArkTS 渲染容器
│
├── android/                         # 2. 谷歌安卓 (Android Gradle) 原生工程
│   ├── build.gradle                 # 根级 Gradle 构建脚本
│   ├── settings.gradle              # 模块注册与 Flutter Gradle 插件加载
│   ├── gradle.properties            # JVM 参数与 AndroidX 配置
│   └── app/                         # 应用程序模块
│       ├── build.gradle             # compileSdkVersion 34, applicationId, signing
│       └── src/main/
│           ├── AndroidManifest.xml  # 网络权限、活动配置与图标
│           ├── kotlin/              # MainActivity.kt (继承 FlutterActivity)
│           └── res/                 # 启动样式与背景资源
│
└── ios/                             # 3. 苹果 (iOS Xcode CocoaPods) 原生工程
    ├── Podfile                      # iOS CocoaPods 依赖配置 (platform: 12.0)
    ├── Runner/
    │   ├── Info.plist               # 权限声明、应用显示名称与横竖屏配置
    │   ├── AppDelegate.swift        # FlutterAppDelegate 原生入口
    │   ├── Runner-Bridging-Header.h # OC/Swift 桥接头文件
    │   └── Base.lproj/              # LaunchScreen 与 Main Storyboard
    └── Runner.xcodeproj/            # Xcode 项目配置文件 (project.pbxproj)
```

---

## 三、便捷一键构建脚本 (One-Click Scripts)

为极大方便日常打包与自动化构建，在工程根目录下预置了针对三大平台的独立一键脚本及综合控制台：

| 脚本名称 | 适用操作系统 | 说明与功能 |
|:---|:---|:---|
| **`build_menu.bat`** | Windows | 🚀 **全平台综合控制台**：交互式菜单，输入数字 1~5 即可选择构建 Android、HarmonyOS、iOS 或清理依赖 |
| **`build_android.bat`** | Windows | 📱 **Android 一键打包**：双击即可自动执行 `flutter pub get`、构建 `app-release.apk` 并在完成后自动定位文件夹 |
| **`build_harmonyos.bat`**| Windows | 🔷 **鸿蒙 NEXT 一键打包**：自动检测 OpenHarmony Flutter SDK，支持 `flutter build hap` 与本地 `hvigorw` 双模式编译 |
| **`build_ios.bat`** | Windows | 🍏 **iOS 跨端构建引导**：自动拉取依赖并提供 Mac 编译、Xcode 联调或 CI/CD 云端构建操作指引 |
| **`build_ios.sh`** | macOS / Linux | 🍏 **iOS 苹果一键打包**：一键安装 CocoaPods、支持选择构建免签名测试包或正式发布 IPA |

---

## 四、三端详细开发与构建运行指南

### 1. 华为鸿蒙 (HarmonyOS NEXT / OpenHarmony)
- **开发工具**：华为 **DevEco Studio** (NEXT 支持 API 11 / 12 Stage 模式)；
- **SDK**：**OpenHarmony-SIG Flutter SDK** (`flutter_flutter`)；
- **编译命令**：
  ```bash
  cd c:\project\fwpt\seahorse\seahorse_app
  flutter pub get
  flutter build hap --target-platform ohos-arm64
  ```
- **DevEco 运行**：使用 DevEco Studio 直接打开 `seahorse_app/ohos` 目录，连接鸿蒙设备点击 Run。

### 2. 谷歌安卓 (Android)
- **开发工具**：Android Studio / VS Code；
- **环境要求**：JDK 17、Android SDK Platform 34；
- **编译与安装**：
  ```bash
  cd c:\project\fwpt\seahorse\seahorse_app
  flutter pub get
  # 编译通用 APK
  flutter build apk --release
  # 或直接真机调试运行
  flutter run -d <android-device-id>
  ```
- 产物输出路径：`build/app/outputs/flutter-apk/app-release.apk`。

### 3. 苹果系统 (iOS)
- **开发工具**：macOS 上的 Xcode 15+；
- **环境要求**：CocoaPods (`sudo gem install cocoapods`)；
- **编译与运行**：
  ```bash
  cd c:\project\fwpt\seahorse\seahorse_app
  flutter pub get
  cd ios && pod install && cd ..
  # 编译 iOS 产物或运行
  flutter build ios --no-codesign
  # 或直接在 Xcode 中打开 ios/Runner.xcworkspace
  ```

---

## 四、网络连接与离线双引擎说明

1. **后端 Spring Boot 联动**：
   - 默认配置连接 `http://localhost:8080/api`（局域网调试真机时，可在 `lib/core/network/api_client.dart` 中调整为服务器局域网 IP，如 `http://192.168.x.x:8080/api`）；
   - 请求头自动附加 `Authorization: Bearer <token>` 与 `X-Store-Id: <storeId>`，权限与多租户严格隔离。
2. **离线自洽体验模式**：
   - 内置完整的 `MockData` 引擎，支持断网离线单机闭环演示所有业务流程。
