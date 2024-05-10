//
//  UserPreferenceCircleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 26.01.23.
//

import SwiftUI

struct UserPreferenceCircleView: View {
    @ObservedObject private var APIM = APIKeyModel.shared
    @ObservedObject private var NM = NetworkReachabilityModel.shared
    var body: some View {
        if let account = APIM.userAccount, NM.connected {
            CachedAsyncImage(url: account.avatar.first?.url, content: { image, _ in
                switch image {
                case .success(let imageDisplay):
                    imageDisplay
                        .resizable()
                        .clipShape(Circle())
                default:
                   UnknownAvatarView()
                }
            })
        } else {
            UnknownAvatarView()
        }
    }
}
