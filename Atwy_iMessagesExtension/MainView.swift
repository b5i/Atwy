//
//  MainView.swift
//  Atwy_iMessagesExtension
//
//  Created by Antoine Bollengier on 14.01.23.
//

import Messages
import SwiftUI
import CoreData

struct MainView: View {
    @State var favorites: [FavoriteVideo] = []
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach($favorites, id: \.timestamp) { $favorite in
                        HStack {
                            if let imageData = favorite.thumbnailData {
                                Image(uiImage: UIImage(data: imageData)!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 222, height: 125)
                            } else {
                                Rectangle()
                                    .foregroundColor(.gray)
                                    .frame(width: 222, height: 125)
                            }
                            VStack {
                                Text(favorite.title ?? "Sans titre")
                                Text(favorite.channel?.name ?? "Sans créateur")
                                    .font(.system(size: 12))
                                    .bold()
                            }
                            Button {
                                messageToSendModel.currentMessage = CurrentMessage(title: favorite.title ?? "", url: URL(string: "Atwy://watch?\(favorite.videoId)"), image: favorite.thumbnailData)
                                NotificationCenter.default.post(name: Notification.Name("SendMessage"), object: nil)
                            } label: {
                                Text("Send message")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
        .onAppear {
            let fetchRequest = FavoriteVideo.fetchRequest()
            do {
                let result = try PersistenceModel.shared.context.fetch(fetchRequest)
                favorites = result
            } catch {
                print(error)
                favorites = []
            }
        }
    }
}

struct CurrentMessage {
    var title: String
    var url: URL?
    var image: Data?
}

class MessageToSendModel: ObservableObject {
    @Published var currentMessage: CurrentMessage = CurrentMessage(title: "")

    init() {}
}

let messageToSendModel = MessageToSendModel()
