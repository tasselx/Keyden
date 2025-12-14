# Keyden

[English](README.md)

简洁优雅的 macOS 菜单栏 TOTP 双因素认证器。

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 功能特性

- 🔐 **安全存储** - TOTP 密钥存储在 macOS Keychain
- 📋 **一键复制** - 点击即可复制验证码
- 📷 **二维码扫描** - 扫描二维码添加账户
- ☁️ **Gist 同步** - 可选通过 GitHub Gist 同步
- 💾 **离线优先** - 无需联网，数据本地加密存储
- 🎨 **主题支持** - 跟随系统明暗主题

## 安装

从 [Releases](https://github.com/tassel/Keyden/releases) 下载最新 DMG：

- `Keyden-x.x.x-universal.dmg` - 推荐（Intel + Apple Silicon）

打开 DMG，将 Keyden 拖入「应用程序」文件夹。

## 使用

1. 启动 Keyden - 图标出现在菜单栏
2. 点击「+」添加 TOTP 账户
3. 点击验证码即可复制

## 从源码构建

```bash
git clone https://github.com/tassel/Keyden.git
cd Keyden
make build    # 构建应用
make dmg      # 创建 DMG
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=tassel/Keyden&type=Date)](https://star-history.com/#tasselx/Keyden&Date)

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)
