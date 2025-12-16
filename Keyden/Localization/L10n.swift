//
//  L10n.swift
//  Keyden
//
//  Localization strings - supports Chinese and English with in-app language switching
//

import Foundation
import SwiftUI

// MARK: - Language Mode
enum LanguageMode: String, CaseIterable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"
    
    var displayName: String {
        switch self {
        case .system: return L10n.languageSystem
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "globe"
        case .english: return "a.circle"
        case .chinese: return "character.textbox"
        }
    }
}

// MARK: - Language Manager
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("appLanguage") var languageMode: LanguageMode = .system {
        didSet {
            objectWillChange.send()
        }
    }
    
    private init() {}
    
    var currentLanguageCode: String {
        switch languageMode {
        case .system:
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.hasPrefix("zh") {
                return "zh-Hans"
            }
            return "en"
        case .english:
            return "en"
        case .chinese:
            return "zh-Hans"
        }
    }
    
    func localizedString(forKey key: String) -> String {
        let languageCode = currentLanguageCode
        
        // Try to get the localized string from the appropriate bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            if value != key {
                return value
            }
        }
        
        // Fallback to English
        return englishStrings[key] ?? key
    }
    
    // English fallback dictionary
    private let englishStrings: [String: String] = [
        // Common
        "copy": "Copy",
        "copied": "Copied",
        "cancel": "Cancel",
        "save": "Save",
        "delete": "Delete",
        "confirm": "Confirm",
        "settings": "Settings",
        "quit": "Quit",
        "search": "Search",
        "add": "Add",
        
        // Token List
        "no_accounts": "No accounts yet",
        "no_results": "No results found",
        "add_first_account": "Add your first 2FA account",
        "try_different_search": "Try a different search",
        "search_accounts": "Search accounts...",
        "pin_to_top": "Pin to Top",
        "unpin": "Unpin",
        "copy_code": "Copy Code",
        "download_qr_code": "Download QR Code",
        
        // Add Token
        "add_account": "Add Account",
        "scan_qr_code": "Scan QR Code or Enter Key",
        "paste_secret_key": "Paste otpauth:// URL or secret key",
        "scan_clipboard": "Clipboard",
        "choose_image": "Choose Image",
        "capture_screen": "Capture Screen",
        "capture_screen_hint": "Use Cmd+Shift+4 to capture, then click Clipboard",
        "capture_screen_error": "Screen capture failed",
        "scan_screen": "Screenshot",
        "scan_screen_hint": "Click to select the QR code area on screen",
        "screen_recording_permission": "Screen Recording Permission Required",
        "screen_recording_permission_desc": "Keyden needs screen recording permission to capture QR codes from your screen. Please enable it in System Settings → Privacy & Security → Screen Recording.",
        "open_settings": "Open Settings",
        "enter_manually": "Enter details manually",
        "confirm_add": "Confirm & Add",
        "invalid_format": "Invalid format. Use otpauth:// URL or Base32 secret",
        "no_qr_code_found": "No QR code found in image",
        "not_a_2fa_code": "QR code is not a 2FA code",
        "secret_required": "Secret key is required",
        "quick_add_platforms": "Quick add popular platforms",
        "service": "Service",
        "account": "Account",
        "algorithm": "Algorithm",
        
        // Settings
        "general": "General",
        "sync": "Sync",
        "data": "Data",
        "appearance": "Appearance",
        "theme": "Theme",
        "theme_system": "System",
        "theme_light": "Light",
        "theme_dark": "Dark",
        "clipboard": "Clipboard",
        "auto_clear": "Auto-clear clipboard",
        "auto_clear_desc": "Clear copied code after 30 seconds",
        "statistics": "Statistics",
        "accounts": "Accounts",
        "pinned": "Pinned",
        "about": "About",
        "version": "Version",
        "launch_at_login": "Launch at Login",
        "launch_at_login_desc": "Start Keyden when you log in",
        
        // Language
        "language": "Language",
        "language_system": "System",
        "language_desc": "Choose your preferred language",
        
        // Sync
        "github_gist": "GitHub Gist",
        "personal_access_token": "Personal Access Token",
        "connected": "Connected",
        "not_configured": "Not configured",
        "configure": "Configure",
        "change": "Change",
        "auto_sync": "Auto-sync",
        "auto_sync_desc": "Sync automatically when changes are made",
        "gist_id": "Gist ID",
        "will_create_on_sync": "Will be created on first sync",
        "bind_existing": "Bind Existing",
        "manual_sync": "Manual Sync",
        "push": "Push",
        "pull": "Pull",
        "last_sync": "Last sync",
        "syncing": "Syncing...",
        "push_success": "Pushed successfully",
        "pull_success": "Pulled successfully",
        "data_synced": "Data synced",
        "pull_confirm_title": "Pull from Backup",
        "pull_confirm_message": "This will replace all local accounts with the backup. Continue?",
        "token_saved": "Token saved successfully",
        "invalid_token": "Invalid token. Check your token and try again.",
        "open_github_token_settings": "Open GitHub Token Settings",
        "create_token_desc": "Create a Personal Access Token with the 'gist' scope",
        
        // Data
        "export": "Export",
        "export_desc": "Export all accounts to a JSON file for backup or migration.",
        "export_button": "Export",
        "export_success": "Exported successfully",
        "import": "Import",
        "import_desc": "Import accounts from a previously exported JSON file.",
        "import_button": "Import",
        "merge_with_existing": "Merge with existing",
        "duplicates_skipped": "Duplicates will be skipped",
        "import_confirm_title": "Import Accounts",
        "import_confirm_message": "This will merge imported accounts with your existing accounts. Continue?",
        "import_success": "Imported successfully",
        "security_warning": "Exported files contain unencrypted secret keys. Keep them secure!",
        "unencrypted_json": "Unencrypted JSON format",
        "export_text": "Export TXT",
        "export_json": "Export JSON",
        "export_text_desc": "Export as plain text with otpauth:// URIs, one per line.",
        "otpauth_uri_format": "otpauth:// URI format",
        
        // Update
        "check_update": "Check for Updates",
        "new_version_available": "New version available",
        "up_to_date": "You're up to date",
        "checking_update": "Checking...",
        
        // Hotkey
        "hotkey": "Hotkey",
        "open_menu": "Open Menu",
        "press_shortcut": "Press...",
        "not_set": "Not Set",
        "clear_shortcut": "Clear",
        "hotkey_desc": "Press to open menu bar",
        
        // Filter
        "filter_all": "All",
        "filter_grouped": "Grouped",
        "pinned_section": "Pinned",
        "other_section": "Other"
    ]
}

/// Localization helper
enum L10n {
    private static var manager: LanguageManager { LanguageManager.shared }
    
    // MARK: - Common
    static var copy: String { manager.localizedString(forKey: "copy") }
    static var copied: String { manager.localizedString(forKey: "copied") }
    static var cancel: String { manager.localizedString(forKey: "cancel") }
    static var save: String { manager.localizedString(forKey: "save") }
    static var delete: String { manager.localizedString(forKey: "delete") }
    static var confirm: String { manager.localizedString(forKey: "confirm") }
    static var settings: String { manager.localizedString(forKey: "settings") }
    static var quit: String { manager.localizedString(forKey: "quit") }
    static var search: String { manager.localizedString(forKey: "search") }
    static var add: String { manager.localizedString(forKey: "add") }
    
    // MARK: - Token List
    static var noAccounts: String { manager.localizedString(forKey: "no_accounts") }
    static var noResults: String { manager.localizedString(forKey: "no_results") }
    static var addFirstAccount: String { manager.localizedString(forKey: "add_first_account") }
    static var tryDifferentSearch: String { manager.localizedString(forKey: "try_different_search") }
    static var searchAccounts: String { manager.localizedString(forKey: "search_accounts") }
    static var pinToTop: String { manager.localizedString(forKey: "pin_to_top") }
    static var unpin: String { manager.localizedString(forKey: "unpin") }
    static var copyCode: String { manager.localizedString(forKey: "copy_code") }
    static var downloadQRCode: String { manager.localizedString(forKey: "download_qr_code") }
    
    // MARK: - Add Token
    static var addAccount: String { manager.localizedString(forKey: "add_account") }
    static var scanQRCode: String { manager.localizedString(forKey: "scan_qr_code") }
    static var pasteSecretKey: String { manager.localizedString(forKey: "paste_secret_key") }
    static var scanClipboard: String { manager.localizedString(forKey: "scan_clipboard") }
    static var chooseImage: String { manager.localizedString(forKey: "choose_image") }
    static var captureScreen: String { manager.localizedString(forKey: "capture_screen") }
    static var captureScreenHint: String { manager.localizedString(forKey: "capture_screen_hint") }
    static var captureScreenError: String { manager.localizedString(forKey: "capture_screen_error") }
    static var scanScreen: String { manager.localizedString(forKey: "scan_screen") }
    static var scanScreenHint: String { manager.localizedString(forKey: "scan_screen_hint") }
    static var screenRecordingPermission: String { manager.localizedString(forKey: "screen_recording_permission") }
    static var screenRecordingPermissionDesc: String { manager.localizedString(forKey: "screen_recording_permission_desc") }
    static var openSettings: String { manager.localizedString(forKey: "open_settings") }
    static var enterManually: String { manager.localizedString(forKey: "enter_manually") }
    static var confirmAdd: String { manager.localizedString(forKey: "confirm_add") }
    static var addAndNext: String { manager.localizedString(forKey: "add_and_next") }
    static func addAll(_ count: Int) -> String {
        manager.localizedString(forKey: "add_all").replacingOccurrences(of: "%d", with: "\(count)")
    }
    static func addedCount(_ count: Int) -> String {
        manager.localizedString(forKey: "added_count").replacingOccurrences(of: "%d", with: "\(count)")
    }
    static var skip: String { manager.localizedString(forKey: "skip") }
    static var invalidFormat: String { manager.localizedString(forKey: "invalid_format") }
    static var noQRCodeFound: String { manager.localizedString(forKey: "no_qr_code_found") }
    static var notA2FACode: String { manager.localizedString(forKey: "not_a_2fa_code") }
    static var secretRequired: String { manager.localizedString(forKey: "secret_required") }
    static var duplicateAccount: String { manager.localizedString(forKey: "duplicate_account") }
    static var quickAddPlatforms: String { manager.localizedString(forKey: "quick_add_platforms") }
    static var service: String { manager.localizedString(forKey: "service") }
    static var account: String { manager.localizedString(forKey: "account") }
    static var algorithm: String { manager.localizedString(forKey: "algorithm") }
    
    // MARK: - Settings
    static var general: String { manager.localizedString(forKey: "general") }
    static var sync: String { manager.localizedString(forKey: "sync") }
    static var data: String { manager.localizedString(forKey: "data") }
    static var appearance: String { manager.localizedString(forKey: "appearance") }
    static var theme: String { manager.localizedString(forKey: "theme") }
    static var themeSystem: String { manager.localizedString(forKey: "theme_system") }
    static var themeLight: String { manager.localizedString(forKey: "theme_light") }
    static var themeDark: String { manager.localizedString(forKey: "theme_dark") }
    static var clipboard: String { manager.localizedString(forKey: "clipboard") }
    static var autoClear: String { manager.localizedString(forKey: "auto_clear") }
    static var autoClearDesc: String { manager.localizedString(forKey: "auto_clear_desc") }
    static var statistics: String { manager.localizedString(forKey: "statistics") }
    static var accounts: String { manager.localizedString(forKey: "accounts") }
    static var pinned: String { manager.localizedString(forKey: "pinned") }
    static var about: String { manager.localizedString(forKey: "about") }
    static var version: String { manager.localizedString(forKey: "version") }
    static var launchAtLogin: String { manager.localizedString(forKey: "launch_at_login") }
    static var launchAtLoginDesc: String { manager.localizedString(forKey: "launch_at_login_desc") }
    
    // MARK: - Language
    static var language: String { manager.localizedString(forKey: "language") }
    static var languageSystem: String { manager.localizedString(forKey: "language_system") }
    static var languageDesc: String { manager.localizedString(forKey: "language_desc") }
    
    // MARK: - Sync
    static var githubGist: String { manager.localizedString(forKey: "github_gist") }
    static var personalAccessToken: String { manager.localizedString(forKey: "personal_access_token") }
    static var connected: String { manager.localizedString(forKey: "connected") }
    static var notConfigured: String { manager.localizedString(forKey: "not_configured") }
    static var configure: String { manager.localizedString(forKey: "configure") }
    static var change: String { manager.localizedString(forKey: "change") }
    static var autoSync: String { manager.localizedString(forKey: "auto_sync") }
    static var autoSyncDesc: String { manager.localizedString(forKey: "auto_sync_desc") }
    static var gistId: String { manager.localizedString(forKey: "gist_id") }
    static var willCreateOnSync: String { manager.localizedString(forKey: "will_create_on_sync") }
    static var bind: String { manager.localizedString(forKey: "bind") }
    static var bindExisting: String { manager.localizedString(forKey: "bind_existing") }
    static var manualSync: String { manager.localizedString(forKey: "manual_sync") }
    static var push: String { manager.localizedString(forKey: "push") }
    static var pull: String { manager.localizedString(forKey: "pull") }
    static var lastSync: String { manager.localizedString(forKey: "last_sync") }
    static var syncing: String { manager.localizedString(forKey: "syncing") }
    static var pushSuccess: String { manager.localizedString(forKey: "push_success") }
    static var pullSuccess: String { manager.localizedString(forKey: "pull_success") }
    static var dataSynced: String { manager.localizedString(forKey: "data_synced") }
    static var pullConfirmTitle: String { manager.localizedString(forKey: "pull_confirm_title") }
    static var pullConfirmMessage: String { manager.localizedString(forKey: "pull_confirm_message") }
    static var tokenSaved: String { manager.localizedString(forKey: "token_saved") }
    static var invalidToken: String { manager.localizedString(forKey: "invalid_token") }
    static var openGitHubTokenSettings: String { manager.localizedString(forKey: "open_github_token_settings") }
    static var createTokenDesc: String { manager.localizedString(forKey: "create_token_desc") }
    
    // MARK: - Data (Import/Export)
    static var export: String { manager.localizedString(forKey: "export") }
    static var exportDesc: String { manager.localizedString(forKey: "export_desc") }
    static var exportButton: String { manager.localizedString(forKey: "export_button") }
    static var exportSuccess: String { manager.localizedString(forKey: "export_success") }
    static var importData: String { manager.localizedString(forKey: "import") }
    static var importDesc: String { manager.localizedString(forKey: "import_desc") }
    static var importButton: String { manager.localizedString(forKey: "import_button") }
    static var mergeWithExisting: String { manager.localizedString(forKey: "merge_with_existing") }
    static var duplicatesSkipped: String { manager.localizedString(forKey: "duplicates_skipped") }
    static var importConfirmTitle: String { manager.localizedString(forKey: "import_confirm_title") }
    static var importConfirmMessage: String { manager.localizedString(forKey: "import_confirm_message") }
    static var importSuccess: String { manager.localizedString(forKey: "import_success") }
    static var securityWarning: String { manager.localizedString(forKey: "security_warning") }
    static var unencryptedJson: String { manager.localizedString(forKey: "unencrypted_json") }
    static var exportText: String { manager.localizedString(forKey: "export_text") }
    static var exportJson: String { manager.localizedString(forKey: "export_json") }
    static var exportTextDesc: String { manager.localizedString(forKey: "export_text_desc") }
    static var otpauthUriFormat: String { manager.localizedString(forKey: "otpauth_uri_format") }
    
    // MARK: - Management
    static var manageAccounts: String { manager.localizedString(forKey: "manage_accounts") }
    static var editAccount: String { manager.localizedString(forKey: "edit_account") }
    static var deleteAccount: String { manager.localizedString(forKey: "delete_account") }
    static func deleteConfirmMessage(_ name: String) -> String {
        manager.localizedString(forKey: "delete_confirm_message").replacingOccurrences(of: "%@", with: name)
    }
    static var name: String { manager.localizedString(forKey: "name") }
    static var issuer: String { manager.localizedString(forKey: "issuer") }
    static var saveBackupMessage: String { manager.localizedString(forKey: "save_backup_message") }
    static var openInBrowser: String { manager.localizedString(forKey: "open_in_browser") }
    
    // MARK: - Update
    static var checkUpdate: String { manager.localizedString(forKey: "check_update") }
    static var newVersionAvailable: String { manager.localizedString(forKey: "new_version_available") }
    static var upToDate: String { manager.localizedString(forKey: "up_to_date") }
    static var checkingUpdate: String { manager.localizedString(forKey: "checking_update") }
    
    // MARK: - Hotkey
    static var hotkey: String { manager.localizedString(forKey: "hotkey") }
    static var openMenu: String { manager.localizedString(forKey: "open_menu") }
    static var pressShortcut: String { manager.localizedString(forKey: "press_shortcut") }
    static var notSet: String { manager.localizedString(forKey: "not_set") }
    static var clearShortcut: String { manager.localizedString(forKey: "clear_shortcut") }
    static var hotkeyDesc: String { manager.localizedString(forKey: "hotkey_desc") }
    
    // MARK: - Filter
    static var filterAll: String { manager.localizedString(forKey: "filter_all") }
    static var filterGrouped: String { manager.localizedString(forKey: "filter_grouped") }
    static var pinnedSection: String { manager.localizedString(forKey: "pinned_section") }
    static var otherSection: String { manager.localizedString(forKey: "other_section") }
}

// MARK: - RawRepresentable for AppStorage
extension LanguageMode: RawRepresentable {
    typealias RawValue = String
}
