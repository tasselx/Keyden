//
//  MenuBarContentView.swift
//  Keyden
//
//  Main menu bar dropdown - Modern design with embedded views
//

import SwiftUI

// MARK: - View Mode
enum ViewMode {
    case list
    case addAccount
    case settings
}

// MARK: - Filter Mode
enum FilterMode {
    case all
    case grouped
    
    var icon: String {
        switch self {
        case .all: return "line.3.horizontal"
        case .grouped: return "square.stack"
        }
    }
    
    mutating func toggle() {
        self = self == .all ? .grouped : .all
    }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var isShowing = false
    @Published var message = ""
    @Published var icon = "checkmark.circle.fill"
    
    private var hideTask: DispatchWorkItem?
    
    func show(_ message: String, icon: String = "checkmark.circle.fill", duration: Double = 1.5) {
        hideTask?.cancel()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            self.message = message
            self.icon = icon
            self.isShowing = true
        }
        
        let task = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.2)) {
                self?.isShowing = false
            }
        }
        hideTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

// MARK: - Toast View
struct ToastView: View {
    @ObservedObject var manager = ToastManager.shared
    let theme: ModernTheme
    
    var body: some View {
        if manager.isShowing {
            HStack(spacing: 6) {
                Image(systemName: manager.icon)
                    .font(.system(size: 12, weight: .semibold))
                
                Text(manager.message)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        theme.isDark
                            ? Color(red: 0.22, green: 0.22, blue: 0.26)
                            : Color(red: 0.20, green: 0.20, blue: 0.25)
                    )
                    .shadow(color: .black.opacity(theme.isDark ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct MenuBarContentView: View {
    @StateObject private var vaultService = VaultService.shared
    @StateObject private var gistService = GistSyncService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var updateService = UpdateService.shared
    
    @State private var searchText = ""
    @State private var copiedTokenId: UUID?
    @State private var draggedToken: Token?
    @State private var currentView: ViewMode = .list
    @State private var filterMode: FilterMode = .all
    
    private var theme: ModernTheme {
        ModernTheme(isDark: themeManager.isDark)
    }
    
    private var sortedTokens: [Token] {
        vaultService.vault.tokens.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }
    
    private var filteredTokens: [Token] {
        if searchText.isEmpty {
            return sortedTokens
        }
        return sortedTokens.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.account.localizedCaseInsensitiveContains(searchText) ||
            $0.issuer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                switch currentView {
                case .list:
                    listView
                case .addAccount:
                    AddTokenView(isPresented: Binding(
                        get: { currentView == .addAccount },
                        set: { if !$0 { currentView = .list } }
                    ))
                case .settings:
                    SettingsView(isPresented: Binding(
                        get: { currentView == .settings },
                        set: { if !$0 { currentView = .list } }
                    ))
                }
            }
            
            // Toast overlay
            ToastView(theme: theme)
                .padding(.bottom, 60)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toastManager.isShowing)
        }
        .frame(width: 340, height: 520)
        .background(theme.background)
        .environment(\.theme, theme)
    }
    
    // MARK: - List View
    private var listView: some View {
        VStack(spacing: 0) {
            headerBar
            
            Divider()
                .background(theme.separator)
            
            if filteredTokens.isEmpty {
                emptyState
            } else {
                tokenList
            }
            
            Divider()
                .background(theme.separator)
            
            footerBar
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 10) {
            // Search field with filter button inside
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textTertiary)
                
                TextField(L10n.searchAccounts, text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textPrimary)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Filter button (icon only)
                Button(action: { filterMode.toggle() }) {
                    Image(systemName: filterMode.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 10)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.inputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.inputBorder, lineWidth: 1)
            )
            
            // Add button
            Button(action: { currentView = .addAccount }) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(theme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: theme.accent.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    // MARK: - Grouped Tokens
    private var groupedTokens: [(String, [Token])] {
        // First, separate pinned and non-pinned tokens
        let pinnedTokens = filteredTokens.filter { $0.isPinned }
        let unpinnedTokens = filteredTokens.filter { !$0.isPinned }
        
        // Group unpinned tokens by issuer (case-insensitive)
        // Use lowercase key for grouping, but keep original display name
        var groups: [String: (displayName: String, tokens: [Token])] = [:]
        for token in unpinnedTokens {
            let rawKey = token.issuer.isEmpty ? token.displayName : token.issuer
            let normalizedKey = rawKey.lowercased().trimmingCharacters(in: .whitespaces)
            
            if var existing = groups[normalizedKey] {
                existing.tokens.append(token)
                groups[normalizedKey] = existing
            } else {
                groups[normalizedKey] = (displayName: rawKey, tokens: [token])
            }
        }
        
        // Sort groups alphabetically by display name
        let sortedGroups = groups.values
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            .map { ($0.displayName, $0.tokens) }
        
        // Build result: pinned section first (if any), then grouped sections
        var result: [(String, [Token])] = []
        if !pinnedTokens.isEmpty {
            // Use special marker for pinned section
            result.append(("__PINNED__", pinnedTokens))
        }
        result.append(contentsOf: sortedGroups)
        
        return result
    }
    
    // MARK: - Token List
    private var tokenList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 6) {
                if filterMode == .grouped {
                    // Grouped view
                    ForEach(groupedTokens, id: \.0) { group in
                        let isPinned = group.0 == "__PINNED__"
                        
                        if isPinned {
                            // Pinned items: no header, just show tokens directly
                            ForEach(group.1) { token in
                                tokenRowView(for: token)
                            }
                            
                            // Add a subtle divider after pinned items if there are more groups
                            if groupedTokens.count > 1 {
                                Divider()
                                    .background(theme.separator)
                                    .padding(.vertical, 4)
                            }
                        } else {
                            // Regular groups with header
                            Section {
                                ForEach(group.1) { token in
                                    tokenRowView(for: token)
                                }
                            } header: {
                                sectionHeader(title: group.0, count: group.1.count)
                            }
                        }
                    }
                } else {
                    // Flat list view
                    ForEach(filteredTokens) { token in
                        tokenRowView(for: token)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
    
    private func tokenRowView(for token: Token) -> some View {
        TokenRow(
            token: token,
            copiedId: $copiedTokenId,
            onPin: { togglePin(token) },
            theme: theme
        )
        .onDrag {
            draggedToken = token
            return NSItemProvider(object: token.id.uuidString as NSString)
        }
        .onDrop(of: [.text], delegate: TokenDropDelegate(
            token: token,
            tokens: sortedTokens,
            draggedToken: $draggedToken,
            onReorder: reorderTokens
        ))
    }
    
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.textSecondary)
            
            Text("\(count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(theme.textTertiary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(theme.surfaceSecondary)
                )
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.accent.opacity(0.15), theme.accent.opacity(0)],
                            center: .center,
                            startRadius: 30,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                // Inner circle
                Circle()
                    .fill(theme.accent.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                // Icon
                Image(systemName: searchText.isEmpty ? "key.fill" : "magnifyingglass")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(theme.accentGradient)
            }
            
            VStack(spacing: 8) {
                Text(searchText.isEmpty ? L10n.noAccounts : L10n.noResults)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(searchText.isEmpty ? L10n.addFirstAccount : L10n.tryDifferentSearch)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty {
                Button(action: { currentView = .addAccount }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text(L10n.addAccount)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(theme.accentGradient)
                    .clipShape(Capsule())
                    .shadow(color: theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Footer
    private var footerBar: some View {
        HStack {
            FooterIconButton(icon: "gearshape.fill", theme: theme, showBadge: updateService.hasUpdate) {
                currentView = .settings
            }
            
            Spacer()
            
            // Sync in progress indicator - fixed space to prevent layout shift
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.45)
                Text(L10n.syncing)
                    .font(.system(size: 10))
            }
            .foregroundColor(theme.textTertiary)
            .opacity(gistService.isConfigured && gistService.isSyncing ? 1 : 0)
            
            Spacer()
            
            FooterIconButton(icon: "power", theme: theme) {
                NSApp.terminate(nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    // MARK: - Actions
    
    private func togglePin(_ token: Token) {
        var updated = token
        updated.isPinned.toggle()
        try? vaultService.updateToken(updated)
    }
    
    private func reorderTokens(_ from: Token, _ to: Token) {
        guard from.id != to.id else { return }
        
        var tokens = sortedTokens
        guard let fromIndex = tokens.firstIndex(where: { $0.id == from.id }),
              let toIndex = tokens.firstIndex(where: { $0.id == to.id }) else { return }
        
        tokens.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        
        for (index, var token) in tokens.enumerated() {
            token.sortOrder = index
            try? vaultService.updateToken(token)
        }
    }
}

// MARK: - Token Row - Compact with Ring Progress
struct TokenRow: View {
    let token: Token
    @Binding var copiedId: UUID?
    let onPin: () -> Void
    let theme: ModernTheme
    
    @State private var currentCode = ""
    @State private var remainingSeconds = 30
    @State private var timer: Timer?
    @State private var isHovering = false
    @State private var isPressed = false
    @State private var isInitialized = false
    
    private var isCopied: Bool { copiedId == token.id }
    
    private var progress: CGFloat {
        CGFloat(remainingSeconds) / CGFloat(token.period)
    }
    
    private var progressColor: Color {
        if remainingSeconds <= 5 { return theme.danger }
        if remainingSeconds <= 10 { return theme.warning }
        return theme.accent
    }
    
    /// Clean display string by removing control characters
    private func cleanText(_ str: String) -> String {
        str.trimmingCharacters(in: .whitespacesAndNewlines)
           .replacingOccurrences(of: "\n", with: "")
           .replacingOccurrences(of: "\r", with: "")
    }
    
    private var displayTitle: String {
        cleanText(token.issuer.isEmpty ? token.displayName : token.issuer)
    }
    
    private var displayAccount: String {
        cleanText(token.account)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Left: Service icon (fixed 32x32)
            serviceIcon
            
            // Middle: Title, Code, Account
            VStack(alignment: .leading, spacing: 2) {
                // Title with optional pin
                HStack(spacing: 4) {
                    Text(displayTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                        .layoutPriority(1)
                    
                    if token.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 7))
                            .foregroundColor(theme.accent)
                            .rotationEffect(.degrees(45))
                    }
                }
                
                // Code
                Text(formatCode(currentCode))
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(isCopied ? theme.success : theme.textPrimary)
                    .animation(.easeInOut(duration: 0.2), value: isCopied)
                
                // Account
                if !displayAccount.isEmpty {
                    Text(displayAccount)
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(2)
            
            // Right: Ring progress + Copy icon (fixed size)
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(theme.progressTrack, lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(remainingSeconds)")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(progressColor)
                }
                .frame(width: 22, height: 22)
                .animation(isInitialized ? .linear(duration: 1) : nil, value: remainingSeconds)
                
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isCopied ? theme.success : theme.textTertiary)
                    .scaleEffect(isCopied ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCopied)
            }
            .frame(width: 26)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? theme.cardBackgroundHover : theme.cardBackground)
                .shadow(color: theme.cardShadow, radius: isHovering ? 3 : 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    token.isPinned ? theme.accent.opacity(0.5) : (isHovering ? theme.border.opacity(0.4) : theme.border.opacity(0.15)),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    copyCode()
                }
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button(action: onPin) {
                Label(token.isPinned ? L10n.unpin : L10n.pinToTop, systemImage: token.isPinned ? "pin.slash" : "pin")
            }
            
            Button(action: copyCode) {
                Label(L10n.copyCode, systemImage: "doc.on.doc")
            }
            
            Button(action: downloadQRCode) {
                Label(L10n.downloadQRCode, systemImage: "qrcode")
            }
            
            Divider()
            
            Button(role: .destructive) {
                try? VaultService.shared.deleteToken(id: token.id)
            } label: {
                Label(L10n.delete, systemImage: "trash")
            }
        }
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }
    
    private var serviceIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: iconGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: iconGradientColors[0].opacity(0.4), radius: 3, x: 0, y: 2)
            
            Text(String(displayTitle.prefix(1)).uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: 34, height: 34)
        .fixedSize()
    }
    
    private var iconGradientColors: [Color] {
        let name = displayTitle
        let hash = abs(name.hashValue)
        let hue1 = Double(hash % 360) / 360.0
        let hue2 = Double((hash + 40) % 360) / 360.0
        
        // Adjust saturation and brightness based on theme
        let saturation = theme.isDark ? 0.70 : 0.60
        let brightness1 = theme.isDark ? 0.80 : 0.70
        let brightness2 = theme.isDark ? 0.65 : 0.55
        
        return [
            Color(hue: hue1, saturation: saturation, brightness: brightness1),
            Color(hue: hue2, saturation: saturation * 0.9, brightness: brightness2)
        ]
    }
    
    private func formatCode(_ code: String) -> String {
        guard code.count >= 6 else { return code }
        let mid = code.index(code.startIndex, offsetBy: code.count / 2)
        return "\(code[..<mid]) \(code[mid...])"
    }
    
    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(currentCode, forType: .string)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            copiedId = token.id
        }
        
        // Show toast
        ToastManager.shared.show(L10n.copied)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedId == token.id {
                withAnimation(.easeInOut(duration: 0.3)) {
                    copiedId = nil
                }
            }
        }
    }
    
    private func downloadQRCode() {
        _ = QRCodeService.shared.saveQRCodeToDownloads(for: token)
    }
    
    private func startTimer() {
        // Initialize without animation
        updateCode()
        
        // Enable animation after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isInitialized = true
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateCode()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isInitialized = false
    }
    
    private func updateCode() {
        currentCode = TOTPService.shared.generateCode(for: token) ?? "------"
        remainingSeconds = TOTPService.shared.remainingSeconds(for: token.period)
    }
}

// MARK: - Footer Icon Button
struct FooterIconButton: View {
    let icon: String
    let theme: ModernTheme
    var showBadge: Bool = false
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isHovering ? theme.accent : theme.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isHovering ? theme.accent.opacity(0.12) : theme.surfaceSecondary)
                    )
                    .overlay(
                        Circle()
                            .stroke(isHovering ? theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                
                // Red dot badge for updates
                if showBadge {
                    Circle()
                        .fill(theme.danger)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Drop Delegate for Reordering
struct TokenDropDelegate: DropDelegate {
    let token: Token
    let tokens: [Token]
    @Binding var draggedToken: Token?
    let onReorder: (Token, Token) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggedToken = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let dragged = draggedToken, dragged.id != token.id else { return }
        onReorder(dragged, token)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Singleton Extensions
extension TOTPService: ObservableObject {}

// MARK: - Legacy Theme Support
struct AppTheme {
    static var background: Color { ModernTheme(isDark: ThemeManager.shared.isDark).background }
    static var cardBackground: Color { ModernTheme(isDark: ThemeManager.shared.isDark).cardBackground }
    static var accent: Color { ModernTheme(isDark: ThemeManager.shared.isDark).accent }
    static var success: Color { ModernTheme(isDark: ThemeManager.shared.isDark).success }
    static var warning: Color { ModernTheme(isDark: ThemeManager.shared.isDark).warning }
    static var danger: Color { ModernTheme(isDark: ThemeManager.shared.isDark).danger }
    static var textPrimary: Color { ModernTheme(isDark: ThemeManager.shared.isDark).textPrimary }
    static var textSecondary: Color { ModernTheme(isDark: ThemeManager.shared.isDark).textSecondary }
}
