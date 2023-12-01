//
//  WebView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 30.12.22.
//

import WebKit
import SwiftUI
import YouTubeKit

#if canImport(UIKit)
import UIKit

struct WebViewUI: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> WebView {
        NotificationCenter.default.addObserver(forName: .atwyCookiesSetUp, object: nil, queue: nil, using: { _ in
            dismiss()
        })
        return WebView()
    }

    func updateUIViewController(_ uiViewController: WebView, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
}

class WebView: UIViewController {
    
    private lazy var url = URL(string: "https://accounts.google.com/ServiceLogin?passive=true&continue=https%3A%2F%2Fwww.youtube.com")!
    private weak var webView: WKWebView?
    
    func initWebView(configuration: WKWebViewConfiguration) {
        NotificationCenter.default.addObserver(forName: .atwyGetCookies, object: nil, queue: nil, using: { _ in
            self.webView?.getCookies(completion: { cookies in
                sendAndProcessCookies(cookies: cookies)
            })
        })
        if webView != nil { return }
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.uiDelegate = self
        webView.addObserver(self, forKeyPath: "URL", context: nil)
        view.addSubview(webView)
        self.webView = webView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if webView == nil { initWebView(configuration: WKWebViewConfiguration()) }
        webView?.load(url: url)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let key = change?[.newKey] {
            print(key)
        }
    }
}

extension WebView: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}

extension WebView: WKUIDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // push new screen to the navigation controller when need to open url in another "tab"
        if let url = navigationAction.request.url, navigationAction.targetFrame == nil {
            let viewController = WebView()
            viewController.initWebView(configuration: configuration)
            viewController.url = url
            DispatchQueue.main.async { [weak self] in
                self?.navigationController?.pushViewController(viewController, animated: true)
            }
            return viewController.webView
        }
        return nil
    }
}

extension WKWebView {

    func load(urlString: String) {
        if let url = URL(string: urlString) { load(url: url) }
    }

    func load(url: URL) { load(URLRequest(url: url)) }
}

extension WKWebView {

    private var httpCookieStore: WKHTTPCookieStore { return WKWebsiteDataStore.default().httpCookieStore }

    func getCookies(for domain: String? = nil, completion: @escaping (String) -> Void) {
//        var cookieDict = [String : AnyObject]()
        httpCookieStore.getAllCookies { cookies in
            completion("\(cookies)")
        }
    }
}
#endif

func sendAndProcessCookies(cookies: String) {
    let potential1PSID = cookies.components(separatedBy: "domain:.youtube.com\n\tpartition:none\n\tsameSite:none\n\tpath:/\n\tisSecure:FALSE\n path:\"/\" isSecure:FALSE>, <NSHTTPCookie\n\tversion:1\n\tname:__Secure-1PSID\n\t")
    let potential1PSID2 = cookies.components(separatedBy: "domain:.youtube.com\n\tpartition:none\n\tsameSite:none\n\tpath:/\n\tisSecure:TRUE\n\tisHTTPOnly: YES\n path:\"/\" isSecure:TRUE isHTTPOnly: YES>, <NSHTTPCookie\n\tversion:1\n\tname:__Secure-1PSID\n\t")
    var PSID1: String?
    if var potentialPSID = (potential1PSID.count > 1 ? potential1PSID : potential1PSID2.count > 1 ? potential1PSID2 : nil) {
        potentialPSID = potentialPSID[1].components(separatedBy: "value:")
        potentialPSID = potentialPSID[1].components(separatedBy: "\n\texpiresDate")
        PSID1 = String(potentialPSID[0])
    } else { return }
    
    var potential1PAPISID = cookies.components(separatedBy: "domain:.youtube.com\n\tpartition:none\n\tsameSite:none\n\tpath:/\n\tisSecure:TRUE\n path:\"/\" isSecure:TRUE>, <NSHTTPCookie\n\tversion:1\n\tname:__Secure-1PAPISID\n\t")
    var PAPISID: String?
    if potential1PAPISID.count > 1 {
        potential1PAPISID = potential1PAPISID[1].components(separatedBy: "value:")
        potential1PAPISID = potential1PAPISID[1].components(separatedBy: "\n\texpiresDate")
        PAPISID = String(potential1PAPISID[0])
    } else { return }
    
    var potentialSAPISID = cookies.components(separatedBy: "domain:.youtube.com\n\tpartition:none\n\tsameSite:none\n\tpath:/\n\tisSecure:FALSE\n path:\"/\" isSecure:FALSE>, <NSHTTPCookie\n\tversion:1\n\tname:SAPISID\n\t")
    var SAPISID: String?
    if potentialSAPISID.count > 1 {
        potentialSAPISID = potentialSAPISID[1].components(separatedBy: "value:")
        potentialSAPISID = potentialSAPISID[1].components(separatedBy: "\n\texpiresDate")
        SAPISID = String(potentialSAPISID[0])
    } else { return }

    if let PSID1 = PSID1, let PAPISID = PAPISID, let SAPISID = SAPISID {
        let finalString = "SAPISID=\(SAPISID); __Secure-1PAPISID=\(PAPISID); __Secure-1PSID=\(PSID1)"
        let cookies = finalString.data(using: .utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrType as String: "Cookies",
                                    kSecAttrService as String: "YouTube",
                                    kSecValueData as String: cookies]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { print("Failed to add cookies in the Keychain, error: \(status)"); return }
        DispatchQueue.main.async {
            APIKeyModel.shared.googleCookies = finalString
        }
    } else {
        print("Could not get cookies")
    }
}
