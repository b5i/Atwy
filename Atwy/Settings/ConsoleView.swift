//
//  ConsoleView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 05.12.2024.
//  Copyright © 2024 Antoine Bollengier (github.com/b5i). All rights reserved.
//  

import SwiftUI
import OSLog
import UniformTypeIdentifiers

public struct ConsoleView: View {
    @State private var filter: String = ""
    
    @ObservedObject private var console = ConsoleModel.shared
    public var body: some View {
        VStack {
            if self.console.logs.isEmpty && self.console.isFetching {
                LoadingView(customText: "console logs")
            } else {
                TimelineView(.periodic(from: .now, by: 5), content: { timeline in
                    let displayedLogs = self.console.logs.filter { $0.contains(filter) || filter == "" }
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(Array(displayedLogs.enumerated()), id: \.offset) { log in
                                let log = log.element
                                Text(log)
                                    .castedFontDesign(.monospaced)
                                    .padding(.vertical)
                                    .textSelection(.enabled)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .castedDefaultScrollAnchor(.bottom)
                    .onAppear {
                        self.console.fetchLogs()
                    }
                    .navigationTitle("Logs at \(timeline.date, style: .time)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(content: {
                        ToolbarItem(placement: .topBarTrailing, content: {
                            CopyToClipboardView(textToCopy: {
                                displayedLogs.joined(separator: "\n")
                            })
                            .padding(.trailing)
                        })
                        ToolbarItem(placement: .topBarTrailing, content: {
                            ShareButtonView(onTap: {
                                let vc = UIActivityViewController(
                                    activityItems: [ConsoleLogsShareSource(logs: displayedLogs.joined(separator: "\n"))],
                                    applicationActivities: nil
                                )
                                
                                SheetsModel.shared.showSuperSheet(withViewController: vc)
                            })
                        })
                    })
                })
                .searchable(text: $filter, placement: .navigationBarDrawer(displayMode: .always))
                .castedSearchPresentationToolbarBehavior(avoidHidingContent: true)
            }
        }
    }
    
    class ConsoleModel: ObservableObject {
        static let shared = ConsoleModel()
        
        @Published private(set) var logs: [String] = []
        
        @Published private(set) var isFetching: Bool = false
        
        private var store: OSLogStore? = nil
        
        init() {
            do {
                #if os(macOS)
                self.store = try OSLogStore.local()
                #else
                self.store = try OSLogStore(scope: .currentProcessIdentifier)
                #endif
            } catch {
                Logger.atwyLogs.error("Error while initializing ConsoleModel: \(error)")
                self.logs.append("Error while initializing ConsoleModel: \(error)")
            }
                        
            self.fetchLogs()
        }
        
        func fetchLogs() {
            guard let store = self.store else { return }
            
            Task.detached {
                DispatchQueue.main.safeSync {
                    self.isFetching = true
                }
                
                do {
                    let logs = try store.getEntries(matching: NSPredicate(format: "subsystem == %@", Logger.atwyLogsSubsytsem as CVarArg))
                        .map({
                            $0.date.formatted(date: .abbreviated, time: .complete) + "\n" + $0.composedMessage
                        })
                    
                    DispatchQueue.main.safeSync {
                        self.logs = logs
                    }
                } catch {
                    Logger.atwyLogs.error("Error while fetching logs: \(error)")
                    self.logs.append("Error while fetching logs: \(error)")
                }
                
                DispatchQueue.main.safeSync {
                    self.isFetching = false
                }
            }
        }

    }
}

#Preview {
    NavigationStack {
        ConsoleView()
    }
}

class ConsoleLogsShareSource: NSObject, UIActivityItemSource {
    let logs: String
    
    init(logs: String) {
        self.logs = logs
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return "Atwy's logs"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return logs
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.text.identifier
    }
}
