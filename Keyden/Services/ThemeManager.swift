//
//  ThemeManager.swift
//  Keyden
//
//  Theme management with light/dark/system modes
//

import SwiftUI
import AppKit

/// Theme mode options
enum ThemeMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// Theme manager singleton
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "themeMode")
            applyTheme()
        }
    }
    
    @Published var isDark: Bool = false
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "themeMode") ?? "System"
        mode = ThemeMode(rawValue: saved) ?? .system
        
        // Set isDark based on saved mode (not relying on NSApp which may not be ready)
        switch mode {
        case .system:
            // For system mode, default to light until NSApp is ready
            // Will be updated in applyTheme() when called from AppDelegate
            if let app = NSApp {
                isDark = app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            } else {
                isDark = false
            }
        case .light:
            isDark = false
        case .dark:
            isDark = true
        }
        
        // Listen for system appearance changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(systemAppearanceChanged),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
        
        // Listen for app launch completion to ensure correct theme
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidFinishLaunching),
            name: NSApplication.didFinishLaunchingNotification,
            object: nil
        )
    }
    
    @objc private func appDidFinishLaunching() {
        // Re-apply theme now that NSApp is fully ready
        DispatchQueue.main.async {
            self.applyTheme()
        }
    }
    
    @objc private func systemAppearanceChanged() {
        DispatchQueue.main.async {
            self.updateIsDark()
        }
    }
    
    private func updateIsDark() {
        switch mode {
        case .system:
            isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case .light:
            isDark = false
        case .dark:
            isDark = true
        }
    }
    
    func applyTheme() {
        updateIsDark()
        
        switch mode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - Modern Theme Colors
struct ModernTheme {
    let isDark: Bool
    
    // MARK: - Backgrounds
    
    /// Main background - subtle gradient-ready base
    var background: Color {
        isDark 
            ? Color(red: 0.08, green: 0.08, blue: 0.10)  // Deep charcoal with subtle blue
            : Color(red: 0.96, green: 0.97, blue: 0.98)  // Soft off-white with cool tint
    }
    
    /// Card/panel background with depth
    var cardBackground: Color {
        isDark
            ? Color(red: 0.13, green: 0.13, blue: 0.15)  // Elevated surface
            : Color.white
    }
    
    /// Hover state for interactive cards
    var cardBackgroundHover: Color {
        isDark
            ? Color(red: 0.17, green: 0.17, blue: 0.20)  // Subtle lift
            : Color(red: 0.94, green: 0.95, blue: 0.97)  // Gentle press
    }
    
    /// Secondary surface for nested elements
    var surfaceSecondary: Color {
        isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.12)
            : Color(red: 0.98, green: 0.98, blue: 0.99)
    }
    
    // MARK: - Accent Colors
    
    /// Primary accent - vibrant indigo-blue
    var accent: Color {
        isDark
            ? Color(red: 0.45, green: 0.55, blue: 1.0)   // Brighter for dark mode visibility
            : Color(red: 0.30, green: 0.45, blue: 0.90)  // Rich but not overwhelming
    }
    
    /// Accent secondary - for subtle highlights
    var accentSecondary: Color {
        isDark
            ? Color(red: 0.55, green: 0.45, blue: 0.95)  // Purple tint
            : Color(red: 0.45, green: 0.35, blue: 0.85)
    }
    
    /// Primary gradient - modern diagonal flow
    var accentGradient: LinearGradient {
        isDark
            ? LinearGradient(
                colors: [
                    Color(red: 0.40, green: 0.50, blue: 1.0),
                    Color(red: 0.60, green: 0.40, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            : LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.50, blue: 0.95),
                    Color(red: 0.50, green: 0.35, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
    }
    
    /// Subtle background gradient for visual interest
    var subtleGradient: LinearGradient {
        isDark
            ? LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.14),
                    Color(red: 0.08, green: 0.08, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            : LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    Color(red: 0.95, green: 0.96, blue: 0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
    }
    
    // MARK: - Semantic Colors
    
    var success: Color {
        isDark
            ? Color(red: 0.35, green: 0.85, blue: 0.60)  // Mint green, vivid
            : Color(red: 0.20, green: 0.70, blue: 0.45)  // Forest green
    }
    
    var warning: Color {
        isDark
            ? Color(red: 1.0, green: 0.75, blue: 0.35)   // Warm amber
            : Color(red: 0.90, green: 0.60, blue: 0.20)  // Rich orange
    }
    
    var danger: Color {
        isDark
            ? Color(red: 1.0, green: 0.45, blue: 0.50)   // Coral red
            : Color(red: 0.85, green: 0.30, blue: 0.35)  // Deep rose
    }
    
    // MARK: - Text Colors
    
    var textPrimary: Color {
        isDark 
            ? Color(red: 0.95, green: 0.95, blue: 0.98)  // Soft white, less harsh
            : Color(red: 0.10, green: 0.10, blue: 0.12)  // Near black with warmth
    }
    
    var textSecondary: Color {
        isDark 
            ? Color(red: 0.65, green: 0.65, blue: 0.70)  // Cool gray
            : Color(red: 0.35, green: 0.35, blue: 0.40)  // Darker for better contrast
    }
    
    var textTertiary: Color {
        isDark 
            ? Color(red: 0.45, green: 0.45, blue: 0.50)  // Muted
            : Color(red: 0.50, green: 0.50, blue: 0.55)  // Darker for better visibility
    }
    
    /// Placeholder text color - more visible than tertiary
    var placeholder: Color {
        isDark
            ? Color(red: 0.40, green: 0.40, blue: 0.45)
            : Color(red: 0.55, green: 0.55, blue: 0.60)
    }
    
    // MARK: - Borders & Separators
    
    var border: Color {
        isDark 
            ? Color(red: 0.22, green: 0.22, blue: 0.26)  // Visible but subtle
            : Color(red: 0.88, green: 0.88, blue: 0.90)  // Soft edge
    }
    
    var separator: Color {
        isDark 
            ? Color(red: 0.18, green: 0.18, blue: 0.20)  // Hairline dark
            : Color(red: 0.92, green: 0.92, blue: 0.94)  // Hairline light
    }
    
    // MARK: - Shadows & Effects
    
    var cardShadow: Color {
        isDark 
            ? Color.black.opacity(0.4)   // Deeper shadow for depth
            : Color.black.opacity(0.08)  // Subtle elevation
    }
    
    /// Inner glow for selected/focused states
    var glowColor: Color {
        accent.opacity(isDark ? 0.3 : 0.2)
    }
    
    // MARK: - Input Fields
    
    var inputBackground: Color {
        isDark
            ? Color(red: 0.10, green: 0.10, blue: 0.12)  // Inset look
            : Color.white  // Pure white for better contrast
    }
    
    var inputBorder: Color {
        isDark
            ? Color(red: 0.20, green: 0.20, blue: 0.24)
            : Color(red: 0.82, green: 0.82, blue: 0.85)  // Slightly darker border
    }
    
    var inputFocusBorder: Color {
        accent.opacity(0.6)
    }
    
    /// Input text color - ensures good contrast
    var inputText: Color {
        isDark
            ? Color(red: 0.92, green: 0.92, blue: 0.95)
            : Color(red: 0.15, green: 0.15, blue: 0.18)  // Dark text on light background
    }
    
    // MARK: - Code Display
    
    var codeBackground: Color {
        isDark
            ? Color(red: 0.06, green: 0.06, blue: 0.08)  // Terminal-like
            : Color(red: 0.96, green: 0.97, blue: 0.98)  // Paper-like
    }
    
    // MARK: - Progress Ring Colors
    
    var progressTrack: Color {
        isDark
            ? Color(white: 0.20)
            : Color(white: 0.90)
    }
}

// MARK: - Environment Key
struct ThemeKey: EnvironmentKey {
    static var defaultValue: ModernTheme {
        ModernTheme(isDark: NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    }
}

extension EnvironmentValues {
    var theme: ModernTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

