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
    
    private lazy var url = URL(string: "https://accounts.google.com/ServiceLogin?passive=true&continue=https%3A%2F%2Fm.youtube.com")!
    private weak var webView: WKWebView?
        
    func initWebView(configuration: WKWebViewConfiguration) {
        NotificationCenter.default.addObserver(forName: .atwyGetCookies, object: nil, queue: nil, using: { _ in
            self.webView?.getCookies(completion: { cookies in
                if APIKeyModel.shared.sendAndProcessCookies(cookies: cookies) {
                    self.webView?.resetCookies()
                }
            })
        })
        NotificationCenter.default.addObserver(forName: .atwyResetCookies, object: nil, queue: nil, using: { _ in
            self.webView?.resetCookies()
            self.webView?.load(url: self.url)
        })
        if webView != nil { return }
        let webView = WKWebView(frame: UIScreen.main.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.uiDelegate = self
        view.addSubview(webView)
        self.webView = webView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if webView == nil { initWebView(configuration: WKWebViewConfiguration()) }
        webView?.load(url: url)
    }
}

extension WebView: WKNavigationDelegate {
    /* to be activated (block redirections in other apps) https://stackoverflow.com/a/76948270/16456439
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           url.scheme != "https" && url.scheme != "http" {
            Logger.atwyLogs.simpleLog("Blocked redirection at \(url)")
            decisionHandler(.cancel)
            webView.load(navigationAction.request)
            return
        }
        decisionHandler(.allow)
        Logger.atwyLogs.simpleLog("Allowed redirection at \(url)")
    }
     */
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

    func resetCookies() {
        httpCookieStore.getAllCookies({ cookies in
            for cookie in cookies {
                self.httpCookieStore.delete(cookie)
            }
        })
    }
    
    func getCookies(for domain: String? = nil, completion: @escaping (String) -> Void) {
        httpCookieStore.getAllCookies { cookies in
            completion("\(cookies)")
        }
    }
}
#endif
