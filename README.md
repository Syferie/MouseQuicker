# MouseQuicker

一个简洁高效的 macOS 鼠标快捷键工具，通过长按鼠标中键呼出圆形菜单，快速执行常用键盘快捷键。

## 功能特点

- **全局触发**：在任何应用中长按鼠标中键（0.1-1秒）即可呼出菜单
- **圆形菜单**：美观的饼状菜单设计，支持最多20个快捷键
- **快速执行**：点击扇形区域即可执行对应的键盘快捷键
- **自定义配置**：可自定义快捷键、图标和描述文字
- **轻量高效**：后台运行占用资源少，响应迅速

## 系统要求

- macOS 10.15 或更高版本
- 需要授予辅助功能和输入监控权限

## 安装使用

### 1. 下载安装
- 从 [Releases](https://github.com/Syferie/MouseQuicker/releases) 下载最新版本
- 或者克隆源码自行编译

### 2. 权限设置
首次运行时，系统会提示授予以下权限：

**辅助功能权限**：
- 打开 `系统偏好设置` > `安全性与隐私` > `隐私` > `辅助功能`
- 点击锁图标解锁，添加 MouseQuicker 并勾选

**输入监控权限**：
- 打开 `系统偏好设置` > `安全性与隐私` > `隐私` > `输入监控`
- 点击锁图标解锁，添加 MouseQuicker 并勾选

### 3. 基本操作
- **呼出菜单**：长按鼠标中键 0.4 秒
- **选择功能**：选择对应快捷键，点击执行
- **取消菜单**：按 ESC 键或点击菜单外区域
- **打开设置**：点击菜单栏图标选择"设置"

## 默认快捷键

应用内置了常用的快捷键配置：

| 功能 | 快捷键 | 图标 |
|------|--------|------|
| 复制 | ⌘C | 📄 |
| 粘贴 | ⌘V | 📋 |
| 撤销 | ⌘Z | ↶ |
| 重做 | ⌘⇧Z | ↷ |
| 保存 | ⌘S | 💾 |

## 自定义配置

在设置界面中可以：
- 添加/删除快捷键项目
- 修改快捷键组合（支持复杂组合键）
- 选择自定义图标
- 编辑描述文字
- 调整触发时长
- 导入/导出配置

## 技术架构

- **开发语言**：Swift
- **UI框架**：SwiftUI + AppKit 混合架构
- **核心组件**：
  - `EventMonitor`：全局鼠标事件监听
  - `PieMenuController`：菜单显示控制
  - `ShortcutExecutor`：快捷键执行
  - `ConfigManager`：配置管理

## 开发编译

```bash
# 克隆项目
git clone https://github.com/your-username/MouseQuicker.git
cd MouseQuicker

# 使用 Xcode 打开项目
open MouseQuicker.xcodeproj

# 或使用命令行编译
xcodebuild -project MouseQuicker.xcodeproj -scheme MouseQuicker -configuration Release
```

## 许可证

本项目采用开源许可证，具体请查看 [LICENSE](LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

---

**注意**：本工具需要系统权限才能正常工作，请确保在受信任的环境中使用。
