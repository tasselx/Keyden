//
//  HotkeyService.swift
//  Keyden
//
//  Global hotkey management for opening the menu bar panel
//

import SwiftUI
import Carbon.HIToolbox

/// Represents a keyboard shortcut with modifiers
struct KeyboardShortcut: Equatable, Codable {
    var keyCode: UInt32
    var modifiers: UInt32
    
    var isEmpty: Bool {
        keyCode == 0 && modifiers == 0
    }
    
    /// Display string for the shortcut
    var displayString: String {
        guard !isEmpty else { return "" }
        
        var parts: [String] = []
        
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        
        if let keyName = Self.keyCodeToString(keyCode) {
            parts.append(keyName)
        }
        
        return parts.joined()
    }
    
    /// Convert key code to human-readable string
    static func keyCodeToString(_ keyCode: UInt32) -> String? {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Escape: return "⎋"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_Grave: return "`"
        default: return nil
        }
    }
    
    /// Create from NSEvent modifiers
    static func modifiersFromNSEvent(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var mods: UInt32 = 0
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        return mods
    }
    
    /// Default shortcut: Cmd+Shift+K
    static let defaultShortcut = KeyboardShortcut(
        keyCode: UInt32(kVK_ANSI_K),
        modifiers: UInt32(cmdKey | shiftKey)
    )
}

/// Service for managing global hotkeys
final class HotkeyService: ObservableObject {
    static let shared = HotkeyService()
    
    @Published var shortcut: KeyboardShortcut {
        didSet {
            saveShortcut()
            registerHotkey()
        }
    }
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hotkeyEnabled")
            registerHotkey()
        }
    }
    
    private var eventHandler: EventHandlerRef?
    private var hotkeyRef: EventHotKeyRef?
    private let hotkeyID = EventHotKeyID(signature: OSType(0x4B444E00), id: 1) // "KDN\0"
    
    private init() {
        // Load saved settings
        if let data = UserDefaults.standard.data(forKey: "hotkeyShortcut"),
           let decoded = try? JSONDecoder().decode(KeyboardShortcut.self, from: data) {
            self.shortcut = decoded
        } else {
            self.shortcut = KeyboardShortcut.defaultShortcut
        }
        self.isEnabled = UserDefaults.standard.object(forKey: "hotkeyEnabled") as? Bool ?? true
    }
    
    private func saveShortcut() {
        if let encoded = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(encoded, forKey: "hotkeyShortcut")
        }
    }
    
    /// Start listening for hotkeys
    func start() {
        guard isEnabled, !shortcut.isEmpty else { return }
        registerHotkey()
    }
    
    /// Stop listening for hotkeys
    func stop() {
        unregisterHotkey()
    }
    
    private func registerHotkey() {
        // First unregister any existing hotkey
        unregisterHotkey()
        
        guard isEnabled, !shortcut.isEmpty else { return }
        
        // Convert Carbon modifiers to CGEventFlags
        var carbonModifiers: UInt32 = 0
        if shortcut.modifiers & UInt32(cmdKey) != 0 { carbonModifiers |= UInt32(cmdKey) }
        if shortcut.modifiers & UInt32(shiftKey) != 0 { carbonModifiers |= UInt32(shiftKey) }
        if shortcut.modifiers & UInt32(optionKey) != 0 { carbonModifiers |= UInt32(optionKey) }
        if shortcut.modifiers & UInt32(controlKey) != 0 { carbonModifiers |= UInt32(controlKey) }
        
        // Install event handler if not already installed
        if eventHandler == nil {
            var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            
            let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                
                // Check if this is our hotkey
                if hotKeyID.signature == OSType(0x4B444E00) && hotKeyID.id == 1 {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .showMenuBarPanel, object: nil)
                    }
                }
                
                return noErr
            }
            
            InstallEventHandler(
                GetApplicationEventTarget(),
                handler,
                1,
                &eventSpec,
                nil,
                &eventHandler
            )
        }
        
        // Register the hotkey
        var hotKeyID = hotkeyID
        RegisterEventHotKey(
            shortcut.keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }
    
    private func unregisterHotkey() {
        if let hotkey = hotkeyRef {
            UnregisterEventHotKey(hotkey)
            hotkeyRef = nil
        }
    }
    
    /// Clear the current shortcut
    func clearShortcut() {
        shortcut = KeyboardShortcut(keyCode: 0, modifiers: 0)
    }
    
    /// Reset to default shortcut
    func resetToDefault() {
        shortcut = KeyboardShortcut.defaultShortcut
    }
    
    deinit {
        unregisterHotkey()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
        }
    }
}

/// View for recording a keyboard shortcut
struct ShortcutRecorderView: View {
    @ObservedObject var hotkeyService: HotkeyService
    let theme: ModernTheme
    
    @State private var isRecording = false
    @State private var localMonitor: Any?
    
    var body: some View {
        HStack(spacing: 6) {
            // Shortcut display/recorder button
            Button(action: { toggleRecording() }) {
                HStack(spacing: 4) {
                    if isRecording {
                        Text(L10n.pressShortcut)
                            .font(.system(size: 11))
                            .foregroundColor(theme.accent)
                    } else if hotkeyService.shortcut.isEmpty {
                        Text(L10n.notSet)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textTertiary)
                    } else {
                        Text(hotkeyService.shortcut.displayString)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(theme.textPrimary)
                    }
                }
                .frame(minWidth: 70)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isRecording ? theme.accent.opacity(0.1) : theme.inputBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isRecording ? theme.accent : theme.inputBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            // Clear button
            if !hotkeyService.shortcut.isEmpty && !isRecording {
                Button(action: { hotkeyService.clearShortcut() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textTertiary)
                }
                .buttonStyle(.plain)
                .help(L10n.clearShortcut)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        
        // Temporarily disable the hotkey while recording
        hotkeyService.stop()
        
        // Monitor for key events
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Ignore modifier-only key presses
            let modifiers = KeyboardShortcut.modifiersFromNSEvent(event.modifierFlags)
            
            // Check if at least one modifier is pressed (except for function keys)
            let isFunctionKey = (event.keyCode >= 122 && event.keyCode <= 135) || 
                               (event.keyCode >= 96 && event.keyCode <= 111)
            
            if modifiers == 0 && !isFunctionKey {
                // No modifiers and not a function key, ignore
                return nil
            }
            
            // Escape cancels recording
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }
            
            // Set the new shortcut
            hotkeyService.shortcut = KeyboardShortcut(
                keyCode: UInt32(event.keyCode),
                modifiers: modifiers
            )
            
            stopRecording()
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        
        // Re-enable the hotkey
        hotkeyService.start()
    }
}
