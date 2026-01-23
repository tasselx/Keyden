//
//  SettingsView.swift
//  Keyden
//
//  Settings - Modern design with theme picker
//

import SwiftUI
import ServiceManagement

// MARK: - View Extension for conditional color invert
extension View {
    @ViewBuilder
    func colorInvert(_ condition: Bool) -> some View {
        if condition {
            self.colorInvert()
        } else {
            self
        }
    }
}

struct SettingsView: View {
    @Binding var isPresented: Bool
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @State private var selectedTab = 0
    
    private var theme: ModernTheme {
        ModernTheme(isDark: themeManager.isDark)
    }
    
    // Computed properties for tab titles to ensure they update on language change
    private var tabTitles: [String] {
        [L10n.general, L10n.sync, L10n.data]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Back button (icon only)
                Button(action: { isPresented = false }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accent)
                        .frame(width: 28, height: 28)
                        .background(theme.accent.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(L10n.settings)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 28, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(theme.separator)
            
            // Tabs
            HStack(spacing: 4) {
                TabPill(title: tabTitles[0], icon: "gearshape", isSelected: selectedTab == 0, theme: theme) { selectedTab = 0 }
                TabPill(title: tabTitles[1], icon: "arrow.triangle.2.circlepath", isSelected: selectedTab == 1, theme: theme) { selectedTab = 1 }
                TabPill(title: tabTitles[2], icon: "square.and.arrow.up.on.square", isSelected: selectedTab == 2, theme: theme) { selectedTab = 2 }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .id(languageManager.languageMode) // Force refresh on language change
            
            // Content
            ScrollView(.vertical, showsIndicators: false) {
                if selectedTab == 0 {
                    GeneralTabContent(theme: theme)
                } else if selectedTab == 1 {
                    SyncTabContent(theme: theme)
                } else {
                    DataTabContent(theme: theme)
                }
            }
            
            Spacer(minLength: 0)
        }
        .background(theme.background)
    }
}

// MARK: - Custom Picker (Theme-aware)
struct CustomPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String
    let theme: ModernTheme
    
    @State private var isExpanded = false
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    HStack {
                        Text(label(option))
                        if selection == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(label(selection))
                    .font(.system(size: 12))
                    .foregroundColor(theme.textPrimary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(theme.inputBorder, lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Tab Pill
struct TabPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let theme: ModernTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? theme.accentGradient : LinearGradient(colors: [theme.cardBackground], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Tab
struct GeneralTabContent: View {
    let theme: ModernTheme
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var updateService = UpdateService.shared
    @StateObject private var hotkeyService = HotkeyService.shared
    @State private var launchAtLogin = false
    
    private func themeDisplayName(_ mode: ThemeMode) -> String {
        switch mode {
        case .system: return L10n.themeSystem
        case .light: return L10n.themeLight
        case .dark: return L10n.themeDark
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Appearance section - Theme & Language
            SettingsCard(title: L10n.appearance, icon: "paintbrush.fill", theme: theme) {
                VStack(spacing: 14) {
                    // Theme row
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: themeManager.mode.icon)
                                .font(.system(size: 12))
                                .foregroundColor(theme.accent)
                                .frame(width: 16)
                            Text(L10n.theme)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        CustomPicker(
                            selection: $themeManager.mode,
                            options: ThemeMode.allCases,
                            label: { themeDisplayName($0) },
                            theme: theme
                        )
                    }
                    
                    Divider()
                        .background(theme.separator)
                    
                    // Language row
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .font(.system(size: 12))
                                .foregroundColor(theme.accent)
                                .frame(width: 16)
                            Text(L10n.language)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        CustomPicker(
                            selection: $languageManager.languageMode,
                            options: LanguageMode.allCases,
                            label: { $0.displayName },
                            theme: theme
                        )
                    }
                }
            }
            
            // General section - Launch at login & Hotkey
            SettingsCard(title: L10n.general, icon: "gearshape.fill", theme: theme) {
                VStack(spacing: 12) {
                    // Launch at login row
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "power")
                                .font(.system(size: 12))
                                .foregroundColor(theme.accent)
                                .frame(width: 16)
                            Text(L10n.launchAtLogin)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                            .onChange(of: launchAtLogin) { newValue in
                                setLaunchAtLogin(newValue)
                            }
                    }
                    
                    Divider()
                        .background(theme.separator)
                    
                    // Hotkey row - fixed height design
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "command")
                                .font(.system(size: 12))
                                .foregroundColor(theme.accent)
                                .frame(width: 16)
                            Text(L10n.hotkey)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        ShortcutRecorderView(hotkeyService: hotkeyService, theme: theme)
                            .opacity(hotkeyService.isEnabled ? 1 : 0.4)
                            .disabled(!hotkeyService.isEnabled)
                        
                        Toggle("", isOn: $hotkeyService.isEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                    }
                    
                    Divider()
                        .background(theme.separator)
                    
                    // CLI row
                    CLISettingsRow(theme: theme)
                }
            }
            .onAppear {
                launchAtLogin = getLaunchAtLogin()
            }
            
            // About section
            SettingsCard(title: L10n.about, icon: "info.circle.fill", theme: theme) {
                VStack(spacing: 14) {
                    // App info row
                    HStack {
                        HStack(spacing: 10) {
                            Image(nsImage: NSApp.applicationIconImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Keyden")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.textPrimary)
                                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(theme.textTertiary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                        .background(theme.separator)
                    
                    // Check for updates row
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12))
                                .foregroundColor(theme.accent)
                                .frame(width: 16)
                            Text(L10n.checkUpdate)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        // Status indicator with action
                        if updateService.isChecking {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 12, height: 12)
                                Text(L10n.checkingUpdate)
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.textSecondary)
                            }
                        } else if updateService.hasUpdate, let version = updateService.latestVersion {
                            Button(action: { updateService.openReleasesPage() }) {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(theme.danger)
                                        .frame(width: 6, height: 6)
                                    Text("v\(version)")
                                        .font(.system(size: 11, weight: .medium))
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(theme.accent)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                            }
                        } else {
                            Button(action: { checkForUpdates() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(theme.success)
                                    Text(L10n.upToDate)
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                            }
                        }
                    }
                    
                    Divider()
                        .background(theme.separator)
                    
                    // GitHub row
                    HStack {
                        Button(action: openGitHub) {
                            HStack(spacing: 8) {
                                Image("GitHubLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                    .colorInvert(theme.isDark)
                                Text("GitHub")
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.textPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                        
                        Spacer()
                        
                        Button(action: openGitHub) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(theme.accent)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                        }
                    }
                }
            }
        }
        .padding(16)
    }
    
    private func checkForUpdates() {
        Task {
            await updateService.checkForUpdates()
        }
    }
    
    private func openGitHub() {
        if let url = URL(string: "https://github.com/tasselx/Keyden") {
            NSWorkspace.shared.open(url)
        }
        // Close the menu panel
        MenuBarController.shared?.hidePanel()
    }
    
    // MARK: - Launch at Login Helpers
    
    private func getLaunchAtLogin() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }
    
    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            // Fallback for macOS 12 - just save preference
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let theme: ModernTheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.accent)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sync Tab
struct SyncTabContent: View {
    let theme: ModernTheme
    @StateObject private var gistService = GistSyncService.shared
    @StateObject private var vaultService = VaultService.shared
    @AppStorage("autoSync") private var autoSync = true
    
    @State private var showTokenInput = false
    @State private var showGistInput = false
    @State private var gistIdInput = ""
    @State private var isValidating = false
    @State private var message: (text: String, isError: Bool)?
    @State private var showPullConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // GitHub Gist section
            SettingsCard(title: L10n.githubGist, icon: "cloud.fill", theme: theme) {
                VStack(alignment: .leading, spacing: 12) {
                    // Token status
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.personalAccessToken)
                                .font(.system(size: 13))
                                .foregroundColor(theme.textPrimary)
                            if gistService.isConfigured {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(theme.success)
                                        .frame(width: 6, height: 6)
                                    Text(L10n.connected)
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.success)
                                }
                            } else {
                                Text(L10n.notConfigured)
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(gistService.isConfigured ? L10n.change : L10n.configure) {
                            showTokenInput = true
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(theme.accent)
                        .cornerRadius(4)
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                    
                    if gistService.isConfigured {
                        Divider().background(theme.separator)
                        
                        // Auto sync toggle
                        Toggle(isOn: $autoSync) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.autoSync)
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.textPrimary)
                                Text(L10n.autoSyncDesc)
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: autoSync) { newValue in
                            if newValue {
                                // Push immediately when enabling auto-sync
                                push()
                            }
                        }
                        
                        Divider().background(theme.separator)
                        
                        // Gist ID
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.gistId)
                                    .font(.system(size: 13))
                                    .foregroundColor(theme.textPrimary)
                                if let gistId = gistService.gistId {
                                    Text(gistId)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(theme.textSecondary)
                                        .lineLimit(1)
                                } else {
                                    Text(L10n.willCreateOnSync)
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let gistId = gistService.gistId {
                                Button(action: { openGist(gistId) }) {
                                    Image(systemName: "arrow.up.right.square")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.accent)
                                }
                                .buttonStyle(.plain)
                                .help(L10n.openInBrowser)
                            }
                            
                            Button(action: { showGistInput = true }) {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.accent)
                            }
                            .buttonStyle(.plain)
                            .help(L10n.bindExisting)
                        }
                    }
                }
            }
            
            if gistService.isConfigured {
                // Sync actions - compact row
                HStack(spacing: 8) {
                    // Push button
                    Button(action: push) {
                        HStack(spacing: 4) {
                            if gistService.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 12))
                            }
                            Text(L10n.push)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.accentGradient)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(gistService.isSyncing)
                    
                    // Pull button
                    Button(action: { showPullConfirm = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 12))
                            Text(L10n.pull)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(gistService.hasGist ? theme.accent : theme.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(theme.cardBackground)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(gistService.hasGist ? theme.accent.opacity(0.3) : theme.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!gistService.hasGist || gistService.isSyncing)
                    
                    Spacer()
                    
                    // Error indicator only
                    if let msg = message, msg.isError {
                        HStack(spacing: 3) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                            Text(msg.text)
                                .font(.system(size: 10))
                                .lineLimit(1)
                        }
                        .foregroundColor(theme.danger)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .animation(.easeInOut(duration: 0.2), value: message?.text)
        .sheet(isPresented: $showTokenInput) {
            TokenInputSheet(isPresented: $showTokenInput, isValidating: $isValidating, theme: theme) { newToken in
                validateAndSaveToken(newToken)
            }
        }
        .sheet(isPresented: $showGistInput) {
            GistInputSheet(isPresented: $showGistInput, gistId: $gistIdInput, theme: theme) {
                gistService.setGistId(gistIdInput)
                gistIdInput = ""
                // Force sync local data to the bound Gist (overwrite remote)
                forcePush()
            }
        }
        .alert(L10n.pullConfirmTitle, isPresented: $showPullConfirm) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.pull, role: .destructive) { pull() }
        } message: {
            Text(L10n.pullConfirmMessage)
        }
    }
    
    private func validateAndSaveToken(_ token: String) {
        isValidating = true
        message = nil
        
        Task {
            let valid = await gistService.validateToken(token)
            await MainActor.run {
                isValidating = false
                if valid {
                    gistService.setToken(token)
                    showTokenInput = false
                    message = (L10n.tokenSaved, false)
                    // Immediately sync after adding token
                    push()
                } else {
                    message = ("Invalid token. Check your token and try again.", true)
                }
            }
        }
    }
    
    private func push() {
        message = nil
        Task {
            do {
                try await gistService.push()
                ToastManager.shared.show(L10n.dataSynced, icon: "checkmark.icloud.fill")
            } catch {
                message = (error.localizedDescription, true)
                autoDismissError()
            }
        }
    }
    
    private func forcePush() {
        message = nil
        Task {
            do {
                try await gistService.push(force: true)
                ToastManager.shared.show(L10n.dataSynced, icon: "checkmark.icloud.fill")
            } catch {
                message = (error.localizedDescription, true)
                autoDismissError()
            }
        }
    }
    
    private func pull() {
        message = nil
        Task {
            do {
                try await gistService.pull()
                ToastManager.shared.show(L10n.dataSynced, icon: "checkmark.icloud.fill")
            } catch {
                message = (error.localizedDescription, true)
                autoDismissError()
            }
        }
    }
    
    private func autoDismissError() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            message = nil
        }
    }
    
    private func openGist(_ gistId: String) {
        if let url = URL(string: "https://gist.github.com/\(gistId)") {
            NSWorkspace.shared.open(url)
        }
        // Close the menu panel
        MenuBarController.shared?.hidePanel()
    }
}

// MARK: - Data Tab (Import/Export)
struct DataTabContent: View {
    let theme: ModernTheme
    @StateObject private var vaultService = VaultService.shared
    @StateObject private var gistService = GistSyncService.shared
    @AppStorage("autoSync") private var autoSync = true
    
    @State private var showingExportSuccess = false
    @State private var showingImportConfirm = false
    @State private var showingClearConfirm = false
    @State private var importURL: URL?
    @State private var message: (text: String, isError: Bool)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Export section
            SettingsCard(title: L10n.export, icon: "square.and.arrow.up.fill", theme: theme) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.exportDesc)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(vaultService.vault.tokens.count) \(L10n.accounts)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.textPrimary)
                            Text(L10n.unencryptedJson)
                                .font(.system(size: 11))
                                .foregroundColor(theme.textTertiary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Button(action: exportData) {
                                HStack(spacing: 3) {
                                    Image(systemName: "curlybraces")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("JSON")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(theme.accent)
                                .cornerRadius(5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: exportTextData) {
                                HStack(spacing: 3) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 10, weight: .semibold))
                                    Text("TXT")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(theme.accent)
                                .cornerRadius(5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Import section
            SettingsCard(title: L10n.importData, icon: "square.and.arrow.down.fill", theme: theme) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.importDesc)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.mergeWithExisting)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.textPrimary)
                            Text(L10n.duplicatesSkipped)
                                .font(.system(size: 11))
                                .foregroundColor(theme.textTertiary)
                        }
                        
                        Spacer()
                        
                        Button(action: selectImportFile) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 11))
                                Text(L10n.importData)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.accent)
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Clear all data section
            SettingsCard(title: L10n.clearAllData, icon: "trash.fill", theme: theme) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.clearAllDataDesc)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(vaultService.vault.tokens.count) \(L10n.accounts)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.textPrimary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingClearConfirm = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text(L10n.clearAllDataButton)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(theme.danger)
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(vaultService.vault.tokens.isEmpty)
                        .opacity(vaultService.vault.tokens.isEmpty ? 0.5 : 1)
                    }
                }
            }
            
            // Warning
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.warning)
                
                Text(L10n.securityWarning)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.warning.opacity(0.1))
            )
            
            // Message
            if let msg = message {
                HStack(spacing: 6) {
                    Image(systemName: msg.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text(msg.text)
                        .font(.system(size: 12))
                }
                .foregroundColor(msg.isError ? theme.danger : theme.success)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill((msg.isError ? theme.danger : theme.success).opacity(0.1))
                )
            }
        }
        .padding(16)
        .alert(L10n.importConfirmTitle, isPresented: $showingImportConfirm) {
            Button(L10n.cancel, role: .cancel) { importURL = nil }
            Button(L10n.importData) { performImport() }
        } message: {
            Text(L10n.importConfirmMessage)
        }
        .alert(L10n.clearAllDataConfirmTitle, isPresented: $showingClearConfirm) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.clearAllDataButton, role: .destructive) { clearAllData() }
        } message: {
            Text(L10n.clearAllDataConfirmMessage)
        }
    }
    
    private func clearAllData() {
        message = nil
        
        do {
            try vaultService.clearAllTokens()
            
            // Sync to cloud if auto-sync is enabled
            if autoSync && gistService.isConfigured {
                Task {
                    try? await gistService.push(force: true)
                }
            }
            
            // Show toast
            ToastManager.shared.show(L10n.dataCleared, icon: "trash.fill")
        } catch {
            message = ("Clear failed: \(error.localizedDescription)", true)
        }
    }
    
    private func exportData() {
        message = nil
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "keyden_backup_\(formattedDate()).json"
        panel.message = L10n.saveBackupMessage
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let data = try vaultService.getExportData()
                    try data.write(to: url, options: .atomic)
                    message = ("Exported \(vaultService.vault.tokens.count) accounts successfully", false)
                } catch {
                    message = ("Export failed: \(error.localizedDescription)", true)
                }
            }
        }
    }
    
    private func exportTextData() {
        message = nil
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "keyden_backup_\(formattedDate()).txt"
        panel.message = L10n.saveBackupMessage
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let textContent = vaultService.vault.tokens
                        .map { $0.otpauthURL }
                        .joined(separator: "\n")
                    try textContent.write(to: url, atomically: true, encoding: .utf8)
                    message = ("Exported \(vaultService.vault.tokens.count) accounts successfully", false)
                } catch {
                    message = ("Export failed: \(error.localizedDescription)", true)
                }
            }
        }
    }
    
    private func selectImportFile() {
        message = nil
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.json, .plainText]  // Support JSON and TXT files
        panel.message = "Select a Keyden backup file (JSON or TXT)"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                importURL = url
                showingImportConfirm = true
            }
        }
    }
    
    /// Simple import format for external JSON files (e.g., converted_keyden.json)
    /// Supports flexible import with auto-generated missing fields
    private struct SimpleImportToken: Codable {
        let account: String?
        let label: String?
        let isPinned: Bool?
        let issuer: String?
        let sortOrder: Int?
        let secret: String
        // Additional optional fields
        let algorithm: String?
        let digits: Int?
        let period: Int?
        let id: String?
        let updatedAt: Double?
        
        /// Convert algorithm string to TOTPAlgorithm enum
        private func parseAlgorithm() -> TOTPAlgorithm {
            switch algorithm?.uppercased() {
            case "SHA256": return .sha256
            case "SHA512": return .sha512
            default: return .sha1
            }
        }
        
        /// Convert to Token with auto-generated missing fields
        func toToken(sortIndex: Int) -> Token {
            Token(
                id: UUID(),  // Auto-generate new UUID
                issuer: issuer ?? "",
                account: account ?? "",
                label: label ?? "",
                secret: secret,
                digits: digits ?? 6,
                period: period ?? 30,
                algorithm: parseAlgorithm(),
                sortOrder: sortOrder ?? sortIndex,  // Use index if not provided
                isPinned: isPinned ?? false,
                updatedAt: Date()  // Auto-generate current timestamp
            )
        }
    }
    
    private func performImport() {
        guard let url = importURL else { return }
        
        do {
            let data = try Data(contentsOf: url)
            var tokens: [Token] = []
            
            // Check file extension for format hint
            let fileExtension = url.pathExtension.lowercased()
            
            // Try TXT format first if extension is .txt
            if fileExtension == "txt" {
                if let textContent = String(data: data, encoding: .utf8) {
                    let lines = textContent.components(separatedBy: .newlines)
                    for (index, line) in lines.enumerated() {
                        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                        if trimmedLine.hasPrefix("otpauth://"),
                           let otpauth = OTPAuthURL.parse(trimmedLine) {
                            var token = otpauth.toToken()
                            token.sortOrder = index
                            tokens.append(token)
                        }
                    }
                }
                if tokens.isEmpty {
                    throw NSError(domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No valid otpauth URLs found in file"])
                }
            }
            // Try to decode as native Vault format first
            else if let importedVault = try? JSONDecoder().decode(Vault.self, from: data) {
                tokens = importedVault.tokens
            }
            // Try to decode as simple JSON array format (e.g., converted_keyden.json)
            else if let simpleTokens = try? JSONDecoder().decode([SimpleImportToken].self, from: data) {
                tokens = simpleTokens.enumerated().map { index, item in
                    item.toToken(sortIndex: index)
                }
            }
            // If all fail, report error
            else {
                throw NSError(domain: "ImportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unrecognized file format"])
            }
            
            var addedCount = 0
            var skippedCount = 0
            
            for token in tokens {
                // Check for duplicate by secret
                let isDuplicate = vaultService.vault.tokens.contains { $0.secret == token.secret }
                if isDuplicate {
                    skippedCount += 1
                } else {
                    try vaultService.addToken(token)
                    addedCount += 1
                }
            }
            
            if addedCount > 0 {
                message = ("Imported \(addedCount) accounts (\(skippedCount) duplicates skipped)", false)
            } else {
                message = ("No new accounts to import (\(skippedCount) duplicates)", false)
            }
        } catch {
            message = ("Import failed: \(error.localizedDescription)", true)
        }
        
        importURL = nil
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return formatter.string(from: Date())
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let theme: ModernTheme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(theme.accent)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.textTertiary)
                    .tracking(0.5)
            }
            
            content
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.cardBackground)
                        .shadow(color: theme.cardShadow, radius: 3, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.border.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Sync Button
struct SyncButton: View {
    let title: String
    let icon: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let theme: ModernTheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                ZStack {
                    ProgressView()
                        .scaleEffect(0.6)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .opacity(isLoading ? 1 : 0)
                    
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .opacity(isLoading ? 0 : 1)
                }
                .frame(width: 16, height: 16)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDisabled ? AnyShapeStyle(theme.inputBackground) : AnyShapeStyle(theme.accentGradient))
            )
            .foregroundColor(isDisabled ? theme.textTertiary : .white)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isDisabled)
    }
}

// MARK: - Token Input Sheet
struct TokenInputSheet: View {
    @Binding var isPresented: Bool
    @Binding var isValidating: Bool
    let theme: ModernTheme
    let onSave: (String) -> Void
    
    @State private var token = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("GitHub Token")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            // Instructions
            VStack(spacing: 8) {
                Text(L10n.createTokenDesc)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: openGitHubTokenPage) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 11))
                        Text(L10n.openGitHubTokenSettings)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
            }
            
            // Input
            SecureField("ghp_xxxxxxxxxxxx", text: $token)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(theme.inputText)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.inputBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.inputBorder, lineWidth: 1)
                )
            
            // Actions
            HStack(spacing: 10) {
                Button(L10n.cancel) { isPresented = false }
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.inputBackground)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                
                Button(action: { onSave(token) }) {
                    HStack {
                        if isValidating {
                            ProgressView().scaleEffect(0.7)
                        } else {
                            Text(L10n.save)
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(token.isEmpty ? theme.textTertiary : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if token.isEmpty {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(theme.border, lineWidth: 1)
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.accentGradient)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(token.isEmpty || isValidating)
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(theme.background)
    }
    
    private func openGitHubTokenPage() {
        if let url = URL(string: "https://github.com/settings/tokens/new?scopes=gist&description=Keyden") {
            NSWorkspace.shared.open(url)
        }
        // Close the menu panel
        MenuBarController.shared?.hidePanel()
    }
}

// MARK: - Gist Input Sheet
struct GistInputSheet: View {
    @Binding var isPresented: Bool
    @Binding var gistId: String
    let theme: ModernTheme
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L10n.bindExisting)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            
            Text("Gist ID")
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
            
            TextField("e.g. abc123def456...", text: $gistId)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(theme.inputText)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.inputBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.inputBorder, lineWidth: 1)
                )
            
            HStack(spacing: 10) {
                Button(L10n.cancel) { isPresented = false }
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(theme.inputBackground)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                
                Button(L10n.bind) {
                    onSave()
                    isPresented = false
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(gistId.isEmpty ? theme.textTertiary : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if gistId.isEmpty {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.surfaceSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(theme.border, lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.accentGradient)
                        }
                    }
                )
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .disabled(gistId.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 280)
        .background(theme.background)
    }
}

// MARK: - CLI Settings Row
struct CLISettingsRow: View {
    let theme: ModernTheme
    
    @State private var isInstalled = CLIService.shared.isInstalled
    @State private var isProcessing = false
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accent)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.cliTool)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textPrimary)
                    Text(isInstalled ? "/usr/local/bin/keyden" : L10n.cliNotInstalledShort)
                        .font(.system(size: 10))
                        .foregroundColor(isInstalled ? theme.success : theme.textTertiary)
                }
            }
            
            Spacer()
            
            if isProcessing {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 60)
            } else {
                Button(isInstalled ? L10n.uninstall : L10n.install) {
                    if isInstalled {
                        uninstallCLI()
                    } else {
                        installCLI()
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isInstalled ? theme.danger : theme.accent)
                .cornerRadius(4)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
            }
        }
    }
    
    private func installCLI() {
        isProcessing = true
        CLIService.shared.installCLI { result in
            isProcessing = false
            switch result {
            case .success:
                isInstalled = true
                ToastManager.shared.show(L10n.cliInstalled, icon: "checkmark.circle.fill")
            case .failure(let error):
                ToastManager.shared.show(error.localizedDescription, icon: "xmark.circle.fill")
            }
        }
    }
    
    private func uninstallCLI() {
        isProcessing = true
        CLIService.shared.uninstallCLI { result in
            isProcessing = false
            switch result {
            case .success:
                isInstalled = false
                ToastManager.shared.show(L10n.cliUninstalled, icon: "checkmark.circle.fill")
            case .failure(let error):
                ToastManager.shared.show(error.localizedDescription, icon: "xmark.circle.fill")
            }
        }
    }
}
