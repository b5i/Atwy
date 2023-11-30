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
                getUserInfos { result in
                    DispatchQueue.main.async {
                        withAnimation {
                            if !(result?.isDisconnected ?? true) {
                                self.userAccount = result
                                NotificationCenter.default.post(name: Notification.Name("CookiesSetUp"), object: nil)
                            } else {
                                self.userAccount = nil
                            }
                        }
                    }
                }
            }
        }
    }
    @Published var userAccount: AccountInfosResponse?

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
        AccountInfosResponse.sendRequest(youtubeModel: YTM, data: [:], result: { accountInfos, error in
            if let error = error {
                print("Couldn't get account infos, error: \(error).")
            }
            result(accountInfos)
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
}
