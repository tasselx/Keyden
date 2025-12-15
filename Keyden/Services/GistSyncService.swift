//
//  GistSyncService.swift
//  Keyden
//
//  GitHub Gist sync service
//

import Foundation

/// GitHub Gist sync service for vault backup/restore
final class GistSyncService: ObservableObject {
    static let shared = GistSyncService()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    @Published var lastError: String?
    
    private let keychain = KeychainService.shared
    private let vaultService = VaultService.shared
    
    private let gistFileName = "keyden_vault.json"
    private let gistDescription = "Keyden Vault Backup"
    
    private init() {}
    
    // MARK: - Configuration
    
    var isConfigured: Bool {
        keychain.githubToken != nil
    }
    
    var hasGist: Bool {
        keychain.gistId != nil
    }
    
    var gistId: String? {
        keychain.gistId
    }
    
    func setToken(_ token: String?) {
        keychain.githubToken = token
    }
    
    func setGistId(_ id: String?) {
        keychain.gistId = id
    }
    
    // MARK: - Push (Upload)
    
    /// Push vault to GitHub Gist
    /// - Parameter force: If true, skip remote version check and overwrite remote data
    @MainActor
    func push(force: Bool = false) async throws {
        guard let token = keychain.githubToken else {
            throw GistError.noToken
        }
        
        isSyncing = true
        lastError = nil
        
        defer { isSyncing = false }
        
        // Get vault data as JSON
        let vaultData = try vaultService.getExportData()
        guard let content = String(data: vaultData, encoding: .utf8) else {
            throw GistError.invalidContent
        }
        
        if let gistId = keychain.gistId {
            // Check remote version first (skip if force push)
            if !force {
                let remoteVersion = try await getRemoteVaultVersion(gistId: gistId, token: token)
                if remoteVersion > vaultService.currentVaultVersion {
                    throw GistError.remoteNewer
                }
            }
            
            // Update existing gist
            try await updateGist(id: gistId, content: content, token: token)
        } else {
            // Create new gist
            let newGistId = try await createGist(content: content, token: token)
            keychain.gistId = newGistId
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Pull (Download)
    
    /// Pull vault from GitHub Gist
    @MainActor
    func pull() async throws {
        guard let token = keychain.githubToken else {
            throw GistError.noToken
        }
        
        guard let gistId = keychain.gistId else {
            throw GistError.noGist
        }
        
        isSyncing = true
        lastError = nil
        
        defer { isSyncing = false }
        
        // Fetch gist content
        let content = try await fetchGist(id: gistId, token: token)
        
        // Parse the content as JSON vault
        guard let data = content.data(using: .utf8) else {
            throw GistError.invalidContent
        }
        
        // Import the vault
        try vaultService.importVaultData(data)
        
        lastSyncDate = Date()
    }
    
    /// Get remote vault version
    func getRemoteVaultVersion(gistId: String, token: String) async throws -> Int {
        let content = try await fetchGist(id: gistId, token: token)
        
        guard let data = content.data(using: .utf8) else {
            return 0
        }
        
        // Try to decode as Vault to get version
        if let vault = try? JSONDecoder().decode(Vault.self, from: data) {
            return vault.vaultVersion
        }
        
        return 0
    }
    
    // MARK: - Check Remote
    
    /// Check if remote vault is newer
    @MainActor
    func checkRemoteNewer() async -> Bool {
        guard let token = keychain.githubToken,
              let gistId = keychain.gistId else {
            return false
        }
        
        do {
            let remoteVersion = try await getRemoteVaultVersion(gistId: gistId, token: token)
            return remoteVersion > vaultService.currentVaultVersion
        } catch {
            return false
        }
    }
    
    // MARK: - API Calls
    
    private func createGist(content: String, token: String) async throws -> String {
        let url = URL(string: "https://api.github.com/gists")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "description": gistDescription,
            "public": false,
            "files": [
                gistFileName: [
                    "content": content
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GistError.networkError
        }
        
        guard httpResponse.statusCode == 201 else {
            throw GistError.apiError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String else {
            throw GistError.invalidResponse
        }
        
        return id
    }
    
    private func updateGist(id: String, content: String, token: String) async throws {
        let url = URL(string: "https://api.github.com/gists/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = [
            "files": [
                gistFileName: [
                    "content": content
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GistError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GistError.apiError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func fetchGist(id: String, token: String) async throws -> String {
        let url = URL(string: "https://api.github.com/gists/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GistError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GistError.apiError(statusCode: httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = json["files"] as? [String: Any],
              let file = files[gistFileName] as? [String: Any],
              let content = file["content"] as? String else {
            throw GistError.invalidResponse
        }
        
        return content
    }
    
    /// Validate GitHub token
    func validateToken(_ token: String) async -> Bool {
        let url = URL(string: "https://api.github.com/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Errors

enum GistError: LocalizedError {
    case noToken
    case noGist
    case networkError
    case apiError(statusCode: Int)
    case invalidResponse
    case invalidContent
    case remoteNewer
    
    var errorDescription: String? {
        switch self {
        case .noToken:
            return "GitHub token not configured"
        case .noGist:
            return "No Gist bound. Please create or bind a Gist first."
        case .networkError:
            return "Network error occurred"
        case .apiError(let statusCode):
            return "GitHub API error (status: \(statusCode))"
        case .invalidResponse:
            return "Invalid response from GitHub"
        case .invalidContent:
            return "Invalid vault content in Gist"
        case .remoteNewer:
            return "Remote vault is newer. Please pull first."
        }
    }
}

