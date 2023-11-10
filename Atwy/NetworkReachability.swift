//
//  NetworkReachability.swift
//  Atwy
//
//  Created by Antoine Bollengier on 02.12.22.
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
                if VideoPlayerModel.shared.video != nil, VideoPlayerModel.shared.isFetchingMoreVideoInfos == nil, VideoPlayerModel.shared.moreVideoInfos == nil {
                    VideoPlayerModel.shared.fetchMoreInfosForVideo()
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
