//
//  NetworkReachabilityModel.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.12.22.
//  Copyright © 2022-2026 Antoine Bollengier. All rights reserved.
//

import Foundation
import Network

class NetworkReachabilityModel: ObservableObject {

    static let shared = NetworkReachabilityModel()

    let monitor: NWPathMonitor
    let queue: DispatchQueue
    @Published private(set) var connected: Bool = true
    init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "Monitor")
        checkConnection()

    }
    func checkConnection() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                for item in VideoPlayerModel.shared.player.items() {
                    guard let item = item as? YTAVPlayerItem else { continue }
                    if item.isFetchingMoreVideoInfos != true, item.moreVideoInfos == nil {
                        item.fetchMoreInfos()
                    }
                }
                if APIKeyModel.shared.userAccount == nil &&
                    !APIKeyModel.shared.isFetchingAccountInfos {
                    APIKeyModel.shared.updateAccount()
                }
                DispatchQueue.main.async {
                    self.connected = true
                }
            } else {
                DispatchQueue.main.async {
                    self.connected = false
                }
            }
        }
        monitor.start(queue: queue)
    }
}
