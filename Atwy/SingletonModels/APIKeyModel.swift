//
//  APIKeyModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//  Copyright © 2023-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import SwiftUI
import YouTubeKit
import Security
import OSLog

final class APIKeyModel: ObservableObject {
    static let shared = APIKeyModel()

    @Published var googleCookies: String = "" {
        didSet {
            if self.googleCookies == "" {
                YTM.cookies = ""
                YTM.alwaysUseCookies = false
                DispatchQueue.main.async {
                    self.userAccount = nil
                }
            } else {
                self.updateAccount()
            }
        }
    }
    @Published private(set) var userAccount: AccountInfosResponse?
    @Published private(set) var isFetchingAccountInfos: Bool = false

    init() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrType as String: "Cookies",
                                    kSecAttrService as String: "YouTube",
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        _ = SecItemCopyMatching(query as CFDictionary, &item)
        let existingItem = item as? [String: Any]
        if let cookiesData = existingItem?[kSecValueData as String] as? Data {
            self.googleCookies = String(data: cookiesData, encoding: .utf8) ?? ""
        }
    }
    
    func updateAccount() {
        guard self.googleCookies != "" && !self.isFetchingAccountInfos else { return }
        YTM.cookies = self.googleCookies
        YTM.alwaysUseCookies = true
        DispatchQueue.main.safeSync {
            self.isFetchingAccountInfos = true
        }
        self.getUserInfos { result in
            DispatchQueue.main.async {
                self.isFetchingAccountInfos = false
                withAnimation {
                    if !(result?.isDisconnected ?? true) {
                        self.userAccount = result
                        NotificationCenter.default.post(name: .atwyCookiesSetUp, object: nil)
                    } else {
                        self.userAccount = nil
                    }
                }
                SearchView.Model.shared.getVideos()
            }
        }
    }

    private func getUserInfos(result: @escaping (AccountInfosResponse?) -> Void) {
        AccountInfosResponse.sendNonThrowingRequest(youtubeModel: YTM, data: [:], result: { responseResult in
            switch responseResult {
            case .success(let response):
                result(response)
            case .failure(let error):
                Logger.atwyLogs.simpleLog("Couldn't get account infos, error: \(error).")
                result(nil)
            }
        })
    }

    func deleteAccount() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrType as String: "Cookies",
                                    kSecAttrService as String: "YouTube"]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { Logger.atwyLogs.simpleLog("Couldn't delete cookies from Keychain, error: \(status)"); return }
        self.googleCookies = ""
    }
    
    func sendAndProcessCookies(cookies: String) -> Bool {
        func extractCookie(withName name: String, from cookiesString: String) -> String? {
            return cookiesString.ytkFirstGroupMatch(for: "domain:\\.youtube\\.com[^<]*<NSHTTPCookie\\\n\\\tversion:1\\\n\\\tname:\(name)\\\n\\\tvalue:([^\\\\\\n]*)")
        }
        
        guard let PSID1: String = extractCookie(withName: "__Secure-1PSID", from: cookies) else { Logger.atwyLogs.simpleLog("Could not extract cookie __Secure-1PSID"); return false }
        guard let PAPISID1: String = extractCookie(withName: "__Secure-1PAPISID", from: cookies) else { Logger.atwyLogs.simpleLog("Could not extract cookie __Secure-1PAPISID"); return false }
        guard let SAPISID: String = extractCookie(withName: "SAPISID", from: cookies) else { Logger.atwyLogs.simpleLog("Could not extract cookie SAPISID"); return false }

        
        let finalString = "SAPISID=\(SAPISID); __Secure-1PAPISID=\(PAPISID1); __Secure-1PSID=\(PSID1)"
        let cookies = finalString.data(using: .utf8)!
        
        deleteAccount()
        
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrType as String: "Cookies",
                                    kSecAttrService as String: "YouTube",
                                    kSecValueData as String: cookies]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { Logger.atwyLogs.simpleLog("Failed to add cookies in the Keychain, error: \(status)"); return false }
        DispatchQueue.main.async {
            self.googleCookies = finalString
        }
        return true
    }
}
