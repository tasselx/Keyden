//
//  VaultService.swift
//  Keyden
//
//  Encrypted vault storage service
//

import Foundation
import CryptoKit

/// Service for managing encrypted vault storage
final class VaultService: ObservableObject {
    static let shared = VaultService()
    
    @Published private(set) var vault: Vault = Vault()
    @Published private(set) var isUnlocked: Bool = false
    
    private var encryptionKey: SymmetricKey?
    private let keychain = KeychainService.shared
    
    private let vaultFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let keydenDir = appSupport.appendingPathComponent("Keyden", isDirectory: true)
        try? FileManager.default.createDirectory(at: keydenDir, withIntermediateDirectories: true)
        return keydenDir.appendingPathComponent("vault.enc")
    }()
    
    private init() {
        // Auto-unlock on init
        initializeAndUnlock()
    }
    
    // MARK: - Auto Initialization
    
    /// Initialize encryption key and unlock vault automatically
    private func initializeAndUnlock() {
        do {
            encryptionKey = try getOrCreateEncryptionKey()
            isUnlocked = true
            try loadVault()
        } catch {
            print("Failed to initialize vault: \(error)")
        }
    }
    
    /// Get existing key from Keychain or create a new one
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key from Keychain
        if let keyData = keychain.load(key: KeychainService.Keys.encryptionKey) {
            return SymmetricKey(data: keyData)
        }
        
        // Generate new random key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Save to Keychain
        guard keychain.save(key: KeychainService.Keys.encryptionKey, data: keyData) else {
            throw VaultError.keyDerivationFailed
        }
        
        return key
    }
    
    /// Lock the vault (for manual lock if needed)
    func lock() {
        isUnlocked = false
        vault = Vault()
    }
    
    /// Unlock vault (re-initialize)
    func unlock() {
        initializeAndUnlock()
    }
    
    // MARK: - Vault Operations
    
    /// Load vault from disk
    func loadVault() throws {
        guard let key = encryptionKey else {
            throw VaultError.locked
        }
        
        guard FileManager.default.fileExists(atPath: vaultFileURL.path) else {
            vault = Vault()
            return
        }
        
        let data = try Data(contentsOf: vaultFileURL)
        let encryptedVault = try JSONDecoder().decode(EncryptedVault.self, from: data)
        
        // Decrypt
        let nonce = try AES.GCM.Nonce(data: encryptedVault.nonce)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: encryptedVault.ciphertext, tag: encryptedVault.tag)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        vault = try JSONDecoder().decode(Vault.self, from: decryptedData)
    }
    
    /// Save vault to disk
    func saveVault(triggerSync: Bool = true, incrementVersion: Bool = true) throws {
        guard let key = encryptionKey else {
            throw VaultError.locked
        }
        
        if incrementVersion {
            vault.incrementVersion()
        }
        
        let plainData = try JSONEncoder().encode(vault)
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plainData, using: key, nonce: nonce)
        
        let encryptedVault = EncryptedVault(
            version: EncryptedVault.currentVersion,
            salt: Data(),  // Not used for device-key encryption
            iterations: 0,
            nonce: Data(nonce),
            ciphertext: sealedBox.ciphertext,
            tag: sealedBox.tag
        )
        
        let data = try JSONEncoder().encode(encryptedVault)
        try data.write(to: vaultFileURL, options: .atomic)
        
        // Trigger auto-sync if enabled
        if triggerSync {
            triggerAutoSync()
        }
    }
    
    private var autoSyncWorkItem: DispatchWorkItem?
    
    /// Trigger auto-sync to Gist if enabled
    private func triggerAutoSync() {
        // Default to true if not set (matches @AppStorage default in SettingsView)
        let autoSyncEnabled = UserDefaults.standard.object(forKey: "autoSync") == nil 
            ? true 
            : UserDefaults.standard.bool(forKey: "autoSync")
        guard autoSyncEnabled else { return }
        guard GistSyncService.shared.isConfigured else { return }
        
        // Cancel previous pending sync
        autoSyncWorkItem?.cancel()
        
        // Debounce: wait a moment before syncing to batch rapid changes
        let workItem = DispatchWorkItem {
            Task { @MainActor in
                if GistSyncService.shared.isSyncing {
                    self.triggerAutoSync()
                    return
                }
                
                do {
                    try await GistSyncService.shared.push()
                    ToastManager.shared.show(L10n.dataSynced, icon: "checkmark.icloud.fill")
                } catch {
                    print("[AutoSync] Failed: \(error.localizedDescription)")
                }
            }
        }
        autoSyncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }
    
    /// Get encrypted vault data for Gist sync (exports plain JSON for cross-device sync)
    func getExportData() throws -> Data {
        return try JSONEncoder().encode(vault)
    }
    
    /// Import vault data from Gist (plain JSON)
    func importVaultData(_ data: Data) throws {
        let importedVault = try JSONDecoder().decode(Vault.self, from: data)
        vault = importedVault
        // Don't trigger auto-sync when importing from remote
        try saveVault(triggerSync: false, incrementVersion: false)
    }
    
    // MARK: - Token Operations
    
    /// Check if a token with the same secret already exists
    func isDuplicate(secret: String) -> Bool {
        let normalizedSecret = secret.uppercased().replacingOccurrences(of: " ", with: "")
        return vault.tokens.contains { $0.secret == normalizedSecret }
    }
    
    /// Add a new token
    func addToken(_ token: Token) throws {
        // Check for duplicate
        if isDuplicate(secret: token.secret) {
            throw VaultError.duplicateToken
        }
        
        var newToken = token
        newToken.sortOrder = vault.tokens.count
        newToken.updatedAt = Date()
        vault.tokens.append(newToken)
        try saveVault()
    }
    
    /// Update an existing token
    func updateToken(_ token: Token) throws {
        guard let index = vault.tokens.firstIndex(where: { $0.id == token.id }) else {
            throw VaultError.tokenNotFound
        }
        var updatedToken = token
        updatedToken.updatedAt = Date()
        vault.tokens[index] = updatedToken
        try saveVault()
    }
    
    /// Delete a token
    func deleteToken(id: UUID) throws {
        vault.tokens.removeAll { $0.id == id }
        try saveVault()
    }
    
    /// Clear all tokens
    func clearAllTokens() throws {
        vault.tokens.removeAll()
        try saveVault()
    }
    
    /// Reorder tokens
    func reorderTokens(from source: IndexSet, to destination: Int) throws {
        vault.tokens.move(fromOffsets: source, toOffset: destination)
        for (index, _) in vault.tokens.enumerated() {
            vault.tokens[index].sortOrder = index
        }
        try saveVault()
    }
    
    // MARK: - Vault Version
    
    var currentVaultVersion: Int {
        vault.vaultVersion
    }
}

// MARK: - Errors

enum VaultError: LocalizedError {
    case locked
    case keyDerivationFailed
    case corruptedData
    case tokenNotFound
    case noVaultFile
    case duplicateToken
    
    var errorDescription: String? {
        switch self {
        case .locked:
            return "Vault is locked"
        case .keyDerivationFailed:
            return "Failed to create encryption key"
        case .corruptedData:
            return "Vault data is corrupted"
        case .tokenNotFound:
            return "Token not found"
        case .noVaultFile:
            return "Vault file not found"
        case .duplicateToken:
            return L10n.duplicateAccount
        }
    }
}
