//
//  DownloadImageOperation.swift
//  Atwy
//
//  Created by Antoine Bollengier on 12.11.2023.
//  Copyright © 2023-2025 Antoine Bollengier. All rights reserved.
//

import Foundation

final class DownloadImageOperation: Operation {
    let imageURL: URL
    var imageData: Data? = nil
    
    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init()
    }
    
    override func main() {
        guard !isCancelled else { return }
        let semaphore = DispatchSemaphore(value: 0)
        getImage(from: imageURL, completion: { data, response, error in
            if let data = data {
                self.imageData = data
            }
            semaphore.signal()
        })
        semaphore.wait()
    }
}
