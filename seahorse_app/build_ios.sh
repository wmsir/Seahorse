#!/usr/bin/env bash
# ======================================================
# 🍏 海马连锁门店管家 - iOS App / IPA 一键构建脚本 (macOS)
# ======================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================================"
echo "   🍏 海马门店管家 - iOS (苹果) 一键构建脚本"
echo "======================================================"
echo ""

echo "[1/4] 检查并获取 Flutter 依赖包..."
flutter pub get

echo ""
echo "[2/4] 安装与同步 CocoaPods 依赖..."
cd ios
pod install --repo-update
cd ..

echo ""
echo "[3/4] 开始编译构建 iOS 包体..."
echo "请选择构建模式:"
echo "  1) 无证书本地调试测试包 (flutter build ios --no-codesign --release)"
echo "  2) App Store / Ad-Hoc 正式分发归档包 (flutter build ipa --release)"
read -p "请输入选项 [1-2, 默认 1]: " BUILD_CHOICE
BUILD_CHOICE=${BUILD_CHOICE:-1}

if [ "$BUILD_CHOICE" == "2" ]; then
    echo "正在构建 IPA 正式包..."
    flutter build ipa --release
    OUTPUT_PATH="$SCRIPT_DIR/build/ios/archive/Runner.xcarchive"
    IPA_DIR="$SCRIPT_DIR/build/ios/ipa"
    if [ -d "$IPA_DIR" ]; then
        OUTPUT_PATH="$IPA_DIR"
    fi
else
    echo "正在构建免签名测试包..."
    flutter build ios --no-codesign --release
    OUTPUT_PATH="$SCRIPT_DIR/build/ios/iphoneos/Runner.app"
fi

echo ""
echo "[4/4] 构建流程结束！"
echo "======================================================"
echo " 🎉 iOS 产物路径: $OUTPUT_PATH"
echo "======================================================"

if [ -e "$OUTPUT_PATH" ]; then
    open -R "$OUTPUT_PATH"
fi
