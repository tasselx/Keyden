# Keyden

[中文](README.zh-CN.md)

A clean and elegant macOS menu bar TOTP authenticator.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 🔐 **Secure Storage** - TOTP secrets stored in macOS Keychain
- 📋 **One-Click Copy** - Click to copy verification codes
- 📷 **QR Code Scanning** - Scan QR codes to add accounts
- ☁️ **Gist Sync** - Optional sync via GitHub Gist
- 💾 **Offline First** - Works without internet, all data encrypted locally
- 🎨 **Theme Support** - Follows system light/dark theme

## Installation

Download the latest DMG from [Releases](https://github.com/tassel/Keyden/releases):

- `Keyden-x.x.x-universal.dmg` - Recommended (Intel + Apple Silicon)

Open the DMG and drag Keyden to Applications.

## Usage

1. Launch Keyden - icon appears in menu bar
2. Click "+" to add TOTP accounts
3. Click any code to copy

## Build from Source

```bash
git clone https://github.com/tassel/Keyden.git
cd Keyden
make build    # Build app
make dmg      # Create DMG
```

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=tassel/Keyden&type=Date)](https://star-history.com/#tasselx/Keyden&Date)

## License

MIT License - see [LICENSE](LICENSE)
