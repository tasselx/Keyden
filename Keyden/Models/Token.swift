//
//  Token.swift
//  Keyden
//
//  TOTP Token model
//

import Foundation

/// TOTP Algorithm types
enum TOTPAlgorithm: String, Codable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

/// Represents a single TOTP token/account
struct Token: Identifiable, Codable, Equatable {
    var id: UUID
    var issuer: String
    var account: String
    var label: String
    var secret: String  // Base32 encoded
    var digits: Int
    var period: Int
    var algorithm: TOTPAlgorithm
    var sortOrder: Int
    var isPinned: Bool  // Pin to top
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        issuer: String = "",
        account: String = "",
        label: String = "",
        secret: String,
        digits: Int = 6,
        period: Int = 30,
        algorithm: TOTPAlgorithm = .sha1,
        sortOrder: Int = 0,
        isPinned: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.issuer = issuer
        self.account = account
        self.label = label
        self.secret = secret.uppercased().replacingOccurrences(of: " ", with: "")
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
        self.sortOrder = sortOrder
        self.isPinned = isPinned
        self.updatedAt = updatedAt
    }
    
    /// Clean string by removing control characters
    private func cleanDisplayString(_ str: String) -> String {
        str.trimmingCharacters(in: .whitespacesAndNewlines)
           .replacingOccurrences(of: "\n", with: "")
           .replacingOccurrences(of: "\r", with: "")
    }
    
    /// Display name for the token
    var displayName: String {
        if !label.isEmpty {
            return cleanDisplayString(label)
        }
        let cleanIssuer = cleanDisplayString(issuer)
        let cleanAccount = cleanDisplayString(account)
        
        if !cleanIssuer.isEmpty && !cleanAccount.isEmpty {
            return "\(cleanIssuer) (\(cleanAccount))"
        }
        if !cleanIssuer.isEmpty {
            return cleanIssuer
        }
        if !cleanAccount.isEmpty {
            return cleanAccount
        }
        return "Unknown"
    }
    
    /// Generate otpauth:// URL for this token
    var otpauthURL: String {
        // Build label path: issuer:account or just account
        let labelPart: String
        if !issuer.isEmpty && !account.isEmpty {
            labelPart = "\(issuer):\(account)"
        } else if !issuer.isEmpty {
            labelPart = issuer
        } else if !account.isEmpty {
            labelPart = account
        } else {
            labelPart = "Unknown"
        }
        
        // Custom character set for path encoding (allow more characters than default)
        var pathAllowed = CharacterSet.urlPathAllowed
        pathAllowed.remove(":") // Keep colon unencoded for issuer:account format
        let encodedLabel = labelPart.addingPercentEncoding(withAllowedCharacters: pathAllowed) ?? labelPart
        
        // Build query parameters manually to ensure proper encoding
        var queryParts: [String] = []
        queryParts.append("secret=\(secret)")
        
        // Always include issuer in query parameters if not empty
        if !issuer.isEmpty {
            let encodedIssuer = issuer.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? issuer
            queryParts.append("issuer=\(encodedIssuer)")
        }
        
        if digits != 6 {
            queryParts.append("digits=\(digits)")
        }
        
        if period != 30 {
            queryParts.append("period=\(period)")
        }
        
        if algorithm != .sha1 {
            queryParts.append("algorithm=\(algorithm.rawValue)")
        }
        
        let queryString = queryParts.joined(separator: "&")
        return "otpauth://totp/\(encodedLabel)?\(queryString)"
    }
    
    /// Generate CLI command for this token
    var cliCommand: String {
        // Use issuer:account format if both exist, otherwise just issuer or account
        let identifier: String
        if !issuer.isEmpty && !account.isEmpty {
            identifier = "\(issuer):\(account)"
        } else if !issuer.isEmpty {
            identifier = issuer
        } else if !account.isEmpty {
            identifier = account
        } else {
            identifier = displayName
        }
        
        // Escape special characters and wrap in quotes if needed
        let needsQuotes = identifier.contains(" ") || identifier.contains("\"") || identifier.contains("'")
        let escaped = identifier.replacingOccurrences(of: "\"", with: "\\\"")
        
        if needsQuotes {
            return "keyden get \"\(escaped)\""
        } else {
            return "keyden get \(identifier)"
        }
    }
    
    // Handle migration from old format without isPinned
    enum CodingKeys: String, CodingKey {
        case id, issuer, account, label, secret, digits, period, algorithm, sortOrder, isPinned, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        issuer = try container.decode(String.self, forKey: .issuer)
        account = try container.decode(String.self, forKey: .account)
        label = try container.decode(String.self, forKey: .label)
        secret = try container.decode(String.self, forKey: .secret)
        digits = try container.decode(Int.self, forKey: .digits)
        period = try container.decode(Int.self, forKey: .period)
        algorithm = try container.decode(TOTPAlgorithm.self, forKey: .algorithm)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

/// Vault structure containing all tokens and metadata
struct Vault: Codable, Equatable {
    var tokens: [Token]
    var vaultVersion: Int
    var schemaVersion: Int
    var updatedAt: Date
    
    static let currentSchemaVersion = 1
    
    init(tokens: [Token] = [], vaultVersion: Int = 1) {
        self.tokens = tokens
        self.vaultVersion = vaultVersion
        self.schemaVersion = Self.currentSchemaVersion
        self.updatedAt = Date()
    }
    
    mutating func incrementVersion() {
        vaultVersion += 1
        updatedAt = Date()
    }
}

/// Encrypted vault file structure
struct EncryptedVault: Codable {
    let version: Int
    let salt: Data
    let iterations: Int
    let nonce: Data
    let ciphertext: Data
    let tag: Data
    
    static let currentVersion = 1
    static let defaultIterations = 100_000
}

/// Parsed OTPAuth URL
struct OTPAuthURL {
    var type: String = "totp"
    var issuer: String = ""
    var account: String = ""
    var secret: String = ""
    var digits: Int = 6
    var period: Int = 30
    var algorithm: TOTPAlgorithm = .sha1
    
    /// Clean string by removing control characters (newlines, tabs, etc.)
    private static func cleanString(_ str: String) -> String {
        str.trimmingCharacters(in: .whitespacesAndNewlines)
           .replacingOccurrences(of: "\n", with: "")
           .replacingOccurrences(of: "\r", with: "")
           .replacingOccurrences(of: "\t", with: " ")
    }
    
    /// Parse otpauth:// URL
    static func parse(_ urlString: String) -> OTPAuthURL? {
        guard let url = URL(string: urlString),
              url.scheme == "otpauth",
              url.host == "totp" || url.host == "hotp" else {
            return nil
        }
        
        var result = OTPAuthURL()
        result.type = url.host ?? "totp"
        
        // Parse label (path component)
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.contains(":") {
            let parts = path.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count >= 2 {
                let rawIssuer = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                let rawAccount = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                result.issuer = cleanString(rawIssuer)
                result.account = cleanString(rawAccount)
            } else if parts.count == 1 {
                // Only one part (e.g., "issuer:" or ":account")
                let rawAccount = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                result.account = cleanString(rawAccount)
            }
        } else {
            let rawAccount = path.removingPercentEncoding ?? path
            result.account = cleanString(rawAccount)
        }
        
        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        for item in queryItems {
            switch item.name.lowercased() {
            case "secret":
                result.secret = item.value?.uppercased().replacingOccurrences(of: " ", with: "") ?? ""
            case "issuer":
                if result.issuer.isEmpty {
                    result.issuer = cleanString(item.value ?? "")
                }
            case "digits":
                result.digits = Int(item.value ?? "6") ?? 6
            case "period":
                result.period = Int(item.value ?? "30") ?? 30
            case "algorithm":
                switch item.value?.uppercased() {
                case "SHA256":
                    result.algorithm = .sha256
                case "SHA512":
                    result.algorithm = .sha512
                default:
                    result.algorithm = .sha1
                }
            default:
                break
            }
        }
        
        guard !result.secret.isEmpty else {
            return nil
        }
        
        return result
    }
    
    /// Convert to Token
    func toToken() -> Token {
        Token(
            issuer: issuer,
            account: account,
            label: "",
            secret: secret,
            digits: digits,
            period: period,
            algorithm: algorithm
        )
    }
}
