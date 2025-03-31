//
//  HLSDownloaderRessourceLoader.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.11.2024.
//  Copyright © 2024-2025 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import AVFoundation

class HLSDownloaderRessourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    let defaultLocaleCode: String
    
    init(defaultLocaleCode: String) {
        self.defaultLocaleCode = defaultLocaleCode
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForResponseTo authenticationChallenge: URLAuthenticationChallenge) -> Bool {
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        let url = loadingRequest.request.url!
        
        let components = NSURLComponents.init(url: url, resolvingAgainstBaseURL: true)
        components?.scheme = "https"
        
        var newRequest = URLRequest(url: components!.url!)
        newRequest.httpMethod = loadingRequest.request.httpMethod
        newRequest.httpBody = loadingRequest.request.httpBody
        newRequest.allHTTPHeaderFields = loadingRequest.request.allHTTPHeaderFields
        newRequest.timeoutInterval = loadingRequest.request.timeoutInterval
        let task = URLSession.shared.dataTask(with: newRequest) { (data, response, error) in
            guard error == nil,
                let manifestData = data else {
                loadingRequest.finishLoading(with: error)
                    return
            }
            //print(String(decoding: manifestData, as: UTF8.self))
            
            let manifestString = String(decoding: manifestData, as: UTF8.self)
            
            if manifestString.contains("YT-EXT-AUDIO-CONTENT-ID") {
                var newManifestString = ""
                var nextLineSafe = false
                var nextLineUnsafe = false
                manifestString.split(separator: "\n").forEach { line in
                    if nextLineSafe {
                        newManifestString += line + "\n"
                        nextLineSafe = false
                    } else if nextLineUnsafe {
                        nextLineUnsafe = false
                        return
                    } else if line.contains("YT-EXT-AUDIO-CONTENT-ID") {
                        if line.contains(#"YT-EXT-AUDIO-CONTENT-ID="\#(self.defaultLocaleCode)""#) {
                            newManifestString += line + "\n"
                            nextLineSafe = true
                        } else {
                            nextLineUnsafe = true
                        }
                    } else {
                        newManifestString += line + "\n"
                    }
                }
                
                loadingRequest.dataRequest?.respond(with: newManifestString.data(using: .utf8)!)
                loadingRequest.finishLoading()
            } else {
                loadingRequest.dataRequest?.respond(with: manifestData)
                loadingRequest.finishLoading()
            }
        }
        task.resume()
        return true
    }
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return true
    }
}
