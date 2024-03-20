//
//  APIKeyModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 22.01.23.
//

import Foundation
import SwiftUI
import YouTubeKit
import Security

class APIKeyModel: ObservableObject {
    static let shared = APIKeyModel()

    @Published var googleCookies: String = "" {
        didSet {
            if googleCookies == "" {
                YTM.cookies = ""
                YTM.alwaysUseCookies = false
                DispatchQueue.main.async {
                    self.userAccount = nil
                }
            } else {
                YTM.cookies = googleCookies
                YTM.alwaysUseCookies = true
                DispatchQueue.main.async {
                    self.isFetchingAccountInfos = true
                }
                getUserInfos { result in
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
                    }
                }
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

    func getUserInfos(result: @escaping (AccountInfosResponse?) -> Void) {
        AccountInfosResponse.sendRequest(youtubeModel: YTM, data: [:], result: { responseResult in
            switch responseResult {
            case .success(let response):
                result(response)
            case .failure(let error):
                print("Couldn't get account infos, error: \(error).")
                result(nil)
            }
        })
    }

    func deleteAccount() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrType as String: "Cookies",
                                    kSecAttrService as String: "YouTube"]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { print("Couldn't delete cookies from Keychain, error: \(status)"); return }
        self.googleCookies = ""
    }
    
    func sendAndProcessCookies(cookies: String) -> Bool {
        func extractCookie(withName name: String, from cookiesString: String) -> String? {
            let potentialCookie = cookiesString.components(separatedBy: "domain:.youtube.com\n\tpartition:none\n\tsameSite:none\n\tpath:/\n\tisSecure:TRUE\n path:\"/\" isSecure:TRUE>, <NSHTTPCookie\n\tversion:1\n\tname:\(name)\n\t")
            let potentialCookie2 = cookiesString.components(separatedBy: "domain:.youtube.com\n\tpartition:none\n\tsameSite:none\n\tpath:/\n\tisSecure:TRUE\n\tisHTTPOnly: YES\n path:\"/\" isSecure:TRUE isHTTPOnly: YES>, <NSHTTPCookie\n\tversion:1\n\tname:\(name)\n\t")
            let potentialCookie3 = cookiesString.components(separatedBy: "domain:.youtube.com\n\tpartition:none\n\tsameSite:none\n\tpath:/\n\tisSecure:FALSE\n path:\"/\" isSecure:FALSE>, <NSHTTPCookie\n\tversion:1\n\tname:\(name)\n\t")
            var cookie: String?
            if var potentialCookie = (potentialCookie.count > 1 ? potentialCookie : potentialCookie2.count > 1 ? potentialCookie2 : potentialCookie3.count > 1 ? potentialCookie3 : nil) { // The cookie can take multiple forms, this operation checks with 3 potentials forms.
                potentialCookie = potentialCookie[1].components(separatedBy: "value:")
                potentialCookie = potentialCookie[1].components(separatedBy: "\n\texpiresDate")
                cookie = String(potentialCookie[0])
            } else { print("Could not extract cookie with name: \(name)."); return nil }
            
            return cookie
        }
        
        guard let PSID1: String = extractCookie(withName: "__Secure-1PSID", from: cookies) else { return false }
        guard let PAPISID: String = extractCookie(withName: "__Secure-1PAPISID", from: cookies) else { return false }
        guard let SAPISID: String = extractCookie(withName: "SAPISID", from: cookies) else { return false }
        
        let finalString = "SAPISID=\(SAPISID); __Secure-1PAPISID=\(PAPISID); __Secure-1PSID=\(PSID1)"
        let cookies = finalString.data(using: .utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrType as String: "Cookies",
                                    kSecAttrService as String: "YouTube",
                                    kSecValueData as String: cookies]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { print("Failed to add cookies in the Keychain, error: \(status)"); return false }
        DispatchQueue.main.async {
            self.googleCookies = finalString
        }
        return true
    }
}
