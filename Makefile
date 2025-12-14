# Keyden Makefile
# 用于构建和打包 macOS 应用

# 项目配置
PROJECT_NAME = Keyden
SCHEME = Keyden
CONFIGURATION = Release
BUILD_DIR = build
DIST_DIR = dist
ARCHIVE_PATH = $(BUILD_DIR)/$(PROJECT_NAME).xcarchive

# 获取版本号 (从 project.pbxproj 中读取 MARKETING_VERSION)
VERSION := $(shell grep -m1 'MARKETING_VERSION' $(PROJECT_NAME).xcodeproj/project.pbxproj | sed 's/.*= *\([^;]*\);.*/\1/' | tr -d ' ')

# DMG 配置
DMG_VOLUME_NAME = $(PROJECT_NAME)
DMG_WINDOW_SIZE = 600x400
DMG_ICON_SIZE = 128
DMG_BACKGROUND_COLOR = \#FFFFFF

# 默认目标
.PHONY: all
all: dmg

# 清理构建产物
.PHONY: clean
clean:
	@echo "🧹 清理构建产物..."
	rm -rf $(BUILD_DIR)
	rm -rf $(DIST_DIR)
	rm -rf DerivedData
	@echo "✅ 清理完成"

# 创建必要的目录
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

# 构建通用版本 (Universal - arm64 + x86_64)
.PHONY: build build-universal
build: build-universal
build-universal: $(BUILD_DIR)
	@echo "🔨 构建通用版本 (Universal)..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination "generic/platform=macOS" \
		-archivePath $(ARCHIVE_PATH) \
		ARCHS="arm64 x86_64" \
		ONLY_ACTIVE_ARCH=NO \
		archive
	@echo "📦 导出应用..."
	@# 先清理目标目录，避免嵌套问题
	@rm -rf "$(BUILD_DIR)/$(PROJECT_NAME)-universal.app"
	@rm -rf "$(BUILD_DIR)/universal"
	@# 尝试使用 exportArchive，如果失败则直接从 archive 复制
	@xcodebuild -exportArchive \
		-archivePath $(ARCHIVE_PATH) \
		-exportPath $(BUILD_DIR)/universal \
		-exportOptionsPlist ExportOptions.plist 2>/dev/null && \
		mv "$(BUILD_DIR)/universal/$(PROJECT_NAME).app" "$(BUILD_DIR)/$(PROJECT_NAME)-universal.app" && \
		rm -rf "$(BUILD_DIR)/universal" || \
		cp -R "$(ARCHIVE_PATH)/Products/Applications/$(PROJECT_NAME).app" "$(BUILD_DIR)/$(PROJECT_NAME)-universal.app"
	@echo "✅ 通用版本构建完成"

# 构建 Intel 版本 (x86_64)
.PHONY: build-intel
build-intel: $(BUILD_DIR)
	@echo "🔨 构建 Intel 版本 (x86_64)..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination "generic/platform=macOS" \
		-archivePath $(BUILD_DIR)/$(PROJECT_NAME)-intel.xcarchive \
		ARCHS="x86_64" \
		ONLY_ACTIVE_ARCH=NO \
		archive
	@echo "📦 导出应用..."
	@rm -rf "$(BUILD_DIR)/$(PROJECT_NAME)-x86_64.app"
	cp -R "$(BUILD_DIR)/$(PROJECT_NAME)-intel.xcarchive/Products/Applications/$(PROJECT_NAME).app" "$(BUILD_DIR)/$(PROJECT_NAME)-x86_64.app"
	@echo "✅ Intel 版本构建完成"

# 构建 Apple Silicon 版本 (arm64)
.PHONY: build-arm
build-arm: $(BUILD_DIR)
	@echo "🔨 构建 Apple Silicon 版本 (arm64)..."
	xcodebuild -project $(PROJECT_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination "generic/platform=macOS" \
		-archivePath $(BUILD_DIR)/$(PROJECT_NAME)-arm.xcarchive \
		ARCHS="arm64" \
		ONLY_ACTIVE_ARCH=NO \
		archive
	@echo "📦 导出应用..."
	@rm -rf "$(BUILD_DIR)/$(PROJECT_NAME)-arm64.app"
	cp -R "$(BUILD_DIR)/$(PROJECT_NAME)-arm.xcarchive/Products/Applications/$(PROJECT_NAME).app" "$(BUILD_DIR)/$(PROJECT_NAME)-arm64.app"
	@echo "✅ Apple Silicon 版本构建完成"

# 构建所有架构版本
.PHONY: build-all
build-all: build-universal build-intel build-arm

# 创建 DMG (通用版本)
.PHONY: dmg-universal
dmg-universal: build-universal $(DIST_DIR)
	@echo "💿 创建通用版本 DMG..."
	$(call create_dmg,$(BUILD_DIR)/$(PROJECT_NAME)-universal.app,$(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-universal.dmg)
	@echo "✅ 通用版本 DMG 创建完成: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-universal.dmg"

# 创建 DMG (Intel 版本)
.PHONY: dmg-intel
dmg-intel: build-intel $(DIST_DIR)
	@echo "💿 创建 Intel 版本 DMG..."
	$(call create_dmg,$(BUILD_DIR)/$(PROJECT_NAME)-x86_64.app,$(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-x86_64.dmg)
	@echo "✅ Intel 版本 DMG 创建完成: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-x86_64.dmg"

# 创建 DMG (Apple Silicon 版本)
.PHONY: dmg-arm
dmg-arm: build-arm $(DIST_DIR)
	@echo "💿 创建 Apple Silicon 版本 DMG..."
	$(call create_dmg,$(BUILD_DIR)/$(PROJECT_NAME)-arm64.app,$(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-arm64.dmg)
	@echo "✅ Apple Silicon 版本 DMG 创建完成: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION)-arm64.dmg"

# 创建所有 DMG
.PHONY: dmg
dmg: dmg-universal dmg-intel dmg-arm
	@echo ""
	@echo "🎉 所有 DMG 文件创建完成!"
	@echo "📁 输出目录: $(DIST_DIR)/"
	@ls -lh $(DIST_DIR)/*.dmg

# 创建 DMG 的函数
# 参数: $(1) = 应用路径, $(2) = DMG 输出路径
define create_dmg
	@# 创建临时目录
	$(eval TMP_DIR := $(shell mktemp -d))
	@echo "  📁 准备 DMG 内容..."
	@# 复制应用到临时目录
	cp -R "$(1)" "$(TMP_DIR)/$(PROJECT_NAME).app"
	@# 创建 Applications 快捷方式
	ln -s /Applications "$(TMP_DIR)/Applications"
	@# 删除旧的 DMG 文件（如果存在）
	rm -f "$(2)"
	@echo "  📀 创建 DMG 镜像..."
	@# 创建 DMG
	hdiutil create -volname "$(DMG_VOLUME_NAME)" \
		-srcfolder "$(TMP_DIR)" \
		-ov -format UDZO \
		"$(2)"
	@# 清理临时目录
	rm -rf "$(TMP_DIR)"
endef

# 显示帮助信息
.PHONY: help
help:
	@echo "Keyden 构建脚本"
	@echo ""
	@echo "使用方法:"
	@echo "  make build          - 构建通用版本 (Universal)"
	@echo "  make build-intel    - 构建 Intel 版本 (x86_64)"
	@echo "  make build-arm      - 构建 Apple Silicon 版本 (arm64)"
	@echo "  make build-all      - 构建所有架构版本"
	@echo ""
	@echo "  make dmg            - 创建所有 DMG 安装包"
	@echo "  make dmg-universal  - 创建通用版本 DMG"
	@echo "  make dmg-intel      - 创建 Intel 版本 DMG"
	@echo "  make dmg-arm        - 创建 Apple Silicon 版本 DMG"
	@echo ""
	@echo "  make clean          - 清理构建产物"
	@echo "  make help           - 显示此帮助信息"
	@echo ""
	@echo "输出文件:"
	@echo "  dist/$(PROJECT_NAME)-x.x.x-universal.dmg  - 通用版本"
	@echo "  dist/$(PROJECT_NAME)-x.x.x-x86_64.dmg     - Intel 版本"
	@echo "  dist/$(PROJECT_NAME)-x.x.x-arm64.dmg      - Apple Silicon 版本"
