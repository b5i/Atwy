//
//  GetImage.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.10.2023.
//

import Foundation

func getImage(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
    URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
}

func getImage(from url: URL) async -> Data? {
    await withCheckedContinuation({ result in
        getImage(from: url, completion: { data, _ , _ in
            result.resume(returning: data)
        })
    })
}
