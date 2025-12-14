//
//  AddTokenView.swift
//  Keyden
//
//  Add token view - Modern design
//

import SwiftUI
import AppKit
import ScreenCaptureKit

struct AddTokenView: View {
    @Binding var isPresented: Bool
    @StateObject private var vaultService = VaultService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var inputText = ""
    @State private var errorMessage: String?
    @State private var isProcessing = false
    @State private var pendingToken: PendingToken?
    @State private var isWaitingForScreenshot = false
    @State private var showPermissionAlert = false
    
    private var theme: ModernTheme {
        ModernTheme(isDark: themeManager.isDark)
    }
    
    struct PendingToken {
        var issuer: String
        var account: String
        var secret: String
        var digits: Int
        var period: Int
        var algorithm: TOTPAlgorithm
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            Divider()
                .background(theme.separator)
            
            if let pending = pendingToken {
                confirmView(pending)
            } else {
                inputView
            }
        }
        .background(theme.background)
        .alert(L10n.screenRecordingPermission, isPresented: $showPermissionAlert) {
            Button(L10n.openSettings) {
                openScreenRecordingSettings()
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.screenRecordingPermissionDesc)
        }
    }
    
    private func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Check screen recording permission by attempting to capture a minimal screen area
    /// This also triggers the app to appear in System Settings > Privacy > Screen Recording
    private func hasScreenRecordingPermission() -> Bool {
        // Try to capture a 1x1 pixel from the main display
        // This is the reliable way to both check permission AND register the app in settings
        guard let mainDisplay = CGMainDisplayID() as CGDirectDisplayID? else {
            return false
        }
        
        // Attempt to create a screen capture - this triggers permission dialog on first use
        // and registers the app in Screen Recording settings
        let image = CGDisplayCreateImage(mainDisplay, rect: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        // If we got an image, we have permission
        // If nil or the image is blank (all same color), we don't have permission
        guard let cgImage = image else {
            return false
        }
        
        // Check if the captured image has actual content (not just wallpaper placeholder)
        // When permission is denied, macOS returns a valid image but it's just the wallpaper
        // We check by comparing with CGPreflightScreenCaptureAccess result
        return CGPreflightScreenCaptureAccess()
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            // Back button (icon only)
            Button(action: { 
                if pendingToken != nil {
                    pendingToken = nil
                } else {
                    isPresented = false
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.accent)
                    .frame(width: 28, height: 28)
                    .background(theme.accent.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(pendingToken != nil ? L10n.confirm : L10n.addAccount)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 28, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Input View
    private var inputView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(theme.accent)
                }
                .padding(.top, 16)
                
                // Instructions
                Text(L10n.scanQRCode)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
                
                // Input field
                VStack(alignment: .leading, spacing: 6) {
                    TextField(L10n.pasteSecretKey, text: $inputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundColor(theme.inputText)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme.inputBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(errorMessage != nil ? theme.danger : theme.inputBorder, lineWidth: 1)
                        )
                        .onSubmit { processInput() }
                    
                    if let error = errorMessage {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 11))
                            Text(error)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(theme.danger)
                    }
                }
                .padding(.horizontal, 20)
                
                // Action buttons
                VStack(spacing: 10) {
                    Button(action: processInput) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text(L10n.add)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(theme.accentGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                    
                    // Scan buttons - Row 1
                    HStack(spacing: 10) {
                        ScanButton(title: L10n.scanClipboard, icon: "doc.on.clipboard.fill", theme: theme) {
                            scanClipboard()
                        }
                        
                        ScanButton(title: L10n.chooseImage, icon: "photo.fill", theme: theme) {
                            chooseImage()
                        }
                    }
                    
                    // Scan buttons - Row 2: Screenshot recognition
                    ScanButton(title: L10n.scanScreen, icon: "camera.viewfinder", theme: theme, isLoading: isWaitingForScreenshot) {
                        captureScreenshot()
                    }
                    
                    // Hint for screenshot
                    Text(L10n.scanScreenHint)
                        .font(.system(size: 10))
                        .foregroundColor(theme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Confirm View
    private func confirmView(_ pending: PendingToken) -> some View {
        VStack(spacing: 20) {
            // Preview code
            TokenPreviewCard(
                secret: pending.secret,
                digits: pending.digits,
                period: pending.period,
                algorithm: pending.algorithm,
                theme: theme
            )
            .padding(.top, 16)
            
            // Account info
            VStack(spacing: 12) {
                InfoRow(label: L10n.service, value: pending.issuer.isEmpty ? "-" : pending.issuer, theme: theme)
                InfoRow(label: L10n.account, value: pending.account.isEmpty ? "-" : pending.account, theme: theme)
                InfoRow(label: L10n.algorithm, value: pending.algorithm.rawValue, theme: theme)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Confirm button
            Button(action: { saveToken(pending) }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text(L10n.confirmAdd)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(theme.accentGradient)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Actions
    
    private func processInput() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        errorMessage = nil
        
        if trimmed.lowercased().hasPrefix("otpauth://") {
            if let url = OTPAuthURL.parse(trimmed) {
                pendingToken = PendingToken(
                    issuer: url.issuer,
                    account: url.account,
                    secret: url.secret,
                    digits: url.digits,
                    period: url.period,
                    algorithm: url.algorithm
                )
                return
            } else {
                errorMessage = "Invalid otpauth:// URL format"
                return
            }
        }
        
        let cleaned = trimmed.uppercased().replacingOccurrences(of: " ", with: "")
        if TOTPService.shared.isValidBase32(cleaned) {
            pendingToken = PendingToken(
                issuer: "",
                account: "",
                secret: cleaned,
                digits: 6,
                period: 30,
                algorithm: .sha1
            )
            return
        }
        
        errorMessage = "Invalid format. Use otpauth:// URL or Base32 secret"
    }
    
    private func scanClipboard() {
        isProcessing = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = QRCodeService.shared.scanClipboard()
            DispatchQueue.main.async {
                isProcessing = false
                handleScanResult(result)
            }
        }
    }
    
    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic, .webP, .tiff, .gif]
        panel.message = "Select image containing QR code"
        
        let response = panel.runModal()
        
        if response == .OK, let url = panel.url {
            isProcessing = true
            
            DispatchQueue.global(qos: .userInitiated).async {
                let result = QRCodeService.shared.scanImageFile(at: url)
                DispatchQueue.main.async {
                    isProcessing = false
                    handleScanResult(result)
                }
            }
        }
    }
    
    private func captureScreenshot() {
        errorMessage = nil
        
        // Check screen recording permission by actually trying to capture
        // This ensures the app appears in System Settings > Privacy > Screen Recording
        if !hasScreenRecordingPermission() {
            showPermissionAlert = true
            return
        }
        
        isWaitingForScreenshot = true
        print("[Keyden] 启动系统截图工具...")
        
        // Hide the panel first so user can see and select the target area
        MenuBarController.shared?.hidePanel()
        
        // Small delay to ensure panel is hidden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Create a temporary file path for the screenshot
            let tempDir = FileManager.default.temporaryDirectory
            let screenshotPath = tempDir.appendingPathComponent("keyden_screenshot_\(UUID().uuidString).png")
            
            // Use screencapture command with interactive mode (-i)
            // -i: interactive mode (user selects area)
            // -x: no sound
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-x", screenshotPath.path]
            
            process.terminationHandler = { proc in
                DispatchQueue.main.async {
                    isWaitingForScreenshot = false
                    
                    // Check if file exists (user didn't cancel)
                    if FileManager.default.fileExists(atPath: screenshotPath.path) {
                        print("[Keyden] 截图已保存: \(screenshotPath.path)")
                        scanScreenshotFile(at: screenshotPath)
                    } else {
                        print("[Keyden] 用户取消了截图")
                        // Show panel again
                        NotificationCenter.default.post(name: .showMenuBarPanel, object: nil)
                    }
                }
            }
            
            do {
                try process.run()
            } catch {
                print("[Keyden] 启动截图工具失败: \(error.localizedDescription)")
                isWaitingForScreenshot = false
                errorMessage = L10n.captureScreenError
                NotificationCenter.default.post(name: .showMenuBarPanel, object: nil)
            }
        }
    }
    
    private func scanScreenshotFile(at url: URL) {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            defer {
                // Clean up temp file
                try? FileManager.default.removeItem(at: url)
            }
            
            let result = QRCodeService.shared.scanImageFile(at: url)
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.handleScanResult(result)
                NotificationCenter.default.post(name: .showMenuBarPanel, object: nil)
            }
        }
    }
    
    private func handleScanResult(_ result: QRScanResult) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                pendingToken = PendingToken(
                    issuer: url.issuer,
                    account: url.account,
                    secret: url.secret,
                    digits: url.digits,
                    period: url.period,
                    algorithm: url.algorithm
                )
                errorMessage = nil
            } else {
                errorMessage = L10n.noQRCodeFound
            }
        case .noQRCode:
            errorMessage = L10n.noQRCodeFound
        case .noOTPAuth:
            errorMessage = L10n.notA2FACode
        case .error(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func saveToken(_ pending: PendingToken) {
        guard !pending.secret.isEmpty else {
            errorMessage = "Secret key is required"
            return
        }
        
        isProcessing = true
        
        let label = pending.issuer.isEmpty ? pending.account : pending.issuer
        let token = Token(
            issuer: pending.issuer,
            account: pending.account,
            label: label.isEmpty ? "Account" : label,
            secret: pending.secret,
            digits: pending.digits,
            period: pending.period,
            algorithm: pending.algorithm
        )
        
        do {
            try vaultService.addToken(token)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            isProcessing = false
        }
    }
}

// MARK: - Scan Button
struct ScanButton: View {
    let title: String
    let icon: String
    let theme: ModernTheme
    var isLoading: Bool = false
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovering ? theme.cardBackgroundHover : theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.border, lineWidth: 1)
            )
            .foregroundColor(theme.textPrimary)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Token Preview Card
struct TokenPreviewCard: View {
    let secret: String
    let digits: Int
    let period: Int
    let algorithm: TOTPAlgorithm
    let theme: ModernTheme
    
    @State private var code = "------"
    @State private var remaining = 30
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 12) {
            // Code
            Text(formatCode(code))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(theme.accent)
            
            // Circular progress
            ZStack {
                Circle()
                    .stroke(theme.border, lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: CGFloat(remaining) / CGFloat(period))
                    .stroke(theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remaining)
                
                Text("\(remaining)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.accent)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 30)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.codeBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.border, lineWidth: 1)
        )
        .onAppear(perform: startTimer)
        .onDisappear { timer?.invalidate() }
    }
    
    private func formatCode(_ code: String) -> String {
        guard code.count >= 6 else { return code }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return "\(code[..<mid]) \(code[mid...])"
    }
    
    private func startTimer() {
        updateCode()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateCode()
        }
    }
    
    private func updateCode() {
        if !secret.isEmpty {
            code = TOTPService.shared.generateCode(
                secret: secret, digits: digits, period: period, algorithm: algorithm
            ) ?? "------"
        }
        remaining = TOTPService.shared.remainingSeconds(for: period)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    let theme: ModernTheme
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
                .frame(minWidth: 60, alignment: .trailing)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.cardBackground)
        )
    }
}
