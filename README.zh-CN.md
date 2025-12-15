# Keyden

[English](README.md)

简洁优雅的 macOS 菜单栏 TOTP 双因素认证器。

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 截图

<p align="center">
  <img src="docs/screenshot-light.png" width="340" alt="浅色模式" />
  <img src="docs/screenshot-dark.png" width="340" alt="深色模式" />
</p>

## 功能特性

- 🔐 **安全存储** - TOTP 密钥加密存储在 macOS Keychain
- 📋 **一键复制** - 点击即可复制验证码
- 📷 **二维码支持** - 扫描二维码添加账户，支持导出二维码图片
- 📥 **批量导入** - 支持通过剪贴板或输入框批量导入多个账户
- ☁️ **GitHub Gist 同步** - 可选通过私有 GitHub Gist 同步
- 💾 **离线优先** - 无需联网，数据本地加密存储
- 🎨 **主题支持** - 明暗模式，跟随系统偏好设置
- 🌍 **多语言** - 支持英文和简体中文
- 📌 **置顶与排序** - 置顶常用账户，拖拽调整顺序
- 🔄 **导入/导出** - 轻松备份和恢复令牌
- 🚀 **开机启动** - 支持随 Mac 自动启动

## 快速开始 - 主流平台两步验证设置

点击下方链接可直接跳转至对应平台的两步验证设置页面：

| 平台 | 两步验证设置链接 |
|------|------------------|
| 🔵 Google | [安全设置](https://myaccount.google.com/signinoptions/two-step-verification) |
| 🐙 GitHub | [两步验证](https://github.com/settings/two_factor_authentication/setup/intro) |
| 🟦 微软 | [安全选项](https://account.live.com/proofs/manage/additional) |
| 🍎 Apple | [账户安全](https://appleid.apple.com/account/manage) |
| 🟠 亚马逊 | [两步验证](https://www.amazon.com/a/settings/approval) |
| 📘 Facebook | [安全设置](https://www.facebook.com/settings?tab=security) |
| 🐦 X (Twitter) | [账户安全](https://twitter.com/settings/account/login_verification) |
| 🎮 Discord | [账户设置](https://discord.com/channels/@me) → 用户设置 → 我的账户 |
| 📦 Dropbox | [安全设置](https://www.dropbox.com/account/security) |
| 💼 领英 | [两步验证](https://www.linkedin.com/psettings/two-step-verification) |
| ☁️ 阿里云 | [安全设置](https://account.console.aliyun.com/#/secure) |
| ☁️ 腾讯云 | [安全设置](https://console.cloud.tencent.com/developer/security) |
| ☁️ AWS | [IAM 安全](https://console.aws.amazon.com/iam/home#/security_credentials) |
| 🔷 Cloudflare | [账户安全](https://dash.cloudflare.com/profile/authentication) |
| 📧 ProtonMail | [账户设置](https://account.proton.me/u/0/mail/account-password) |

## 安装

从 [Releases](https://github.com/tasselx/Keyden/releases) 下载最新 DMG：

打开 DMG，将 Keyden 拖入「应用程序」文件夹。


## 使用

1. 启动 Keyden - 图标出现在菜单栏
2. 点击「+」添加 TOTP 账户（扫描二维码或手动输入）
3. 点击验证码即可复制到剪贴板
4. 右键点击可查看更多选项（置顶、删除、导出二维码）

### GitHub Gist 同步

1. 进入设置 → 同步
2. 创建 [GitHub Personal Access Token](https://github.com/settings/tokens)，勾选 `gist` 权限
3. 输入 Token 并启用同步
4. 令牌将同步到私有 Gist

## 从源码构建

环境要求：
- macOS 12.0+
- Xcode 15.0+

```bash
git clone https://github.com/tasselx/Keyden.git
cd Keyden

# 构建通用版应用
make build

# 创建 DMG 安装包
make dmg

# 或构建特定架构版本
make build-arm      # 仅 Apple Silicon
make build-intel    # 仅 Intel
make build-all      # 通用

# 清理构建产物
make clean
```

## 技术栈

- SwiftUI + AppKit
- CryptoKit（TOTP 生成）
- Keychain Services（安全存储）
- Vision Framework（二维码扫描）

## 捐赠

如果 Keyden 对你有帮助，欢迎请我喝杯咖啡 ☕

<p align="center">
  <img src="assets/alipay.png" width="200" alt="支付宝" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/wepay.png" width="200" alt="微信支付" />
</p>

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=tasselx/Keyden&type=Date)](https://star-history.com/#tasselx/Keyden&Date)

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)
