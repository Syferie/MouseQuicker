#!/bin/bash

# 创建 DMG 包的脚本
# 使用方法: ./create-dmg.sh <version>

set -e

VERSION=$1
if [[ -z "$VERSION" ]]; then
    echo "错误: 请提供版本号"
    echo "使用方法: $0 <version>"
    exit 1
fi

APP_NAME="MouseQuicker"
DMG_NAME="${APP_NAME}-${VERSION}"
APP_PATH="build/export/${APP_NAME}.app"
DMG_PATH="build/${DMG_NAME}.dmg"

echo "开始创建 DMG 包..."
echo "应用路径: $APP_PATH"
echo "DMG 路径: $DMG_PATH"

# 检查应用是否存在
if [[ ! -d "$APP_PATH" ]]; then
    echo "错误: 找不到应用文件 $APP_PATH"
    exit 1
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
echo "临时目录: $TEMP_DIR"

# 复制应用到临时目录
cp -R "$APP_PATH" "$TEMP_DIR/"

# 创建 Applications 链接
ln -s /Applications "$TEMP_DIR/Applications"

# 创建 DMG
echo "创建 DMG 包..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# 清理临时目录
rm -rf "$TEMP_DIR"

echo "DMG 包创建完成: $DMG_PATH"

# 验证 DMG
if [[ -f "$DMG_PATH" ]]; then
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo "DMG 大小: $DMG_SIZE"
    
    # 验证 DMG 可以挂载
    echo "验证 DMG 包..."
    MOUNT_POINT=$(mktemp -d)
    hdiutil attach "$DMG_PATH" -mountpoint "$MOUNT_POINT" -quiet
    
    if [[ -d "$MOUNT_POINT/$APP_NAME.app" ]]; then
        echo "✅ DMG 验证成功"
    else
        echo "❌ DMG 验证失败"
        exit 1
    fi
    
    hdiutil detach "$MOUNT_POINT" -quiet
    rm -rf "$MOUNT_POINT"
else
    echo "❌ DMG 创建失败"
    exit 1
fi

echo "🎉 DMG 包创建完成!"
