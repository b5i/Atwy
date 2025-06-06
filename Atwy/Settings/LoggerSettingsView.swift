//
//  LoggerSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 07.03.2024.
//  Copyright © 2024-2025 Antoine Bollengier. All rights reserved.
//  

import SwiftUI
import UniformTypeIdentifiers
import YouTubeKit

struct LoggerSettingsView: View {
    static let maxCacheLimitDefaultValue: Int = 5
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var logger = YouTubeModelLogger.shared
    
    var body: some View {
        SettingsMenu(title: "Logger") { geometry in
            SettingsSection(title: "Logger") {
                Setting(
                    textDescription: nil,
                    action: try! SAToggle(PSMType: .isLoggerActivated,
                                          title: "Activate Logger")
                    .setCallback { newValue in
                        if newValue {
                            YTM.logger?.startLogging()
                        } else {
                            YTM.logger?.stopLogging()
                        }
                    }
                )
                let cacheLimitEnabledBinding = Binding(get: {
                    self.logger.maximumCacheSize != nil
                }, set: { newValue in
                    self.logger.setCacheSize(newValue ? Self.maxCacheLimitDefaultValue : nil)
                })
                Setting(textDescription: "Setting a cache limit for the logger will avoid having a lot of RAM consumed to store all the requests. The logger will only keep the n last logs in memory, the rest will be deleted. " + (cacheLimitEnabledBinding.wrappedValue ? "" : "The default value for the cache limit is \(Self.maxCacheLimitDefaultValue), if you activate it, only the \(Self.maxCacheLimitDefaultValue) more recent logs will be kept."), action: CustomSettingToggle(title: "Logger Cache Limit", binding: cacheLimitEnabledBinding))
                Setting(textDescription: nil, action:
                            try! SAStepper(valueType: Int.self, PSMType: .loggerCacheLimit, title: "Limit")
                    .setAction { newValue in
                        self.logger.setCacheSize(max(newValue, 0))
                        return max(newValue, 0)
                    }, hidden: self.logger.maximumCacheSize == nil)
                Setting(textDescription: "Exported logs can contain cookies and therefore make sure that you trust who's going to have access to them. Disabling this option will hide the credentials in the UI and in log exports.", action: try! SAToggle(PSMType: .showCredentials, title: "Show credentials"))
                Setting(textDescription: nil, action: SACustomAction(title: "Logs", actionView: {
                    VStack {
                        Text("Logs")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        List {
                            ForEach(logger.logs, id: \.id) { log in
                                LogView(log: log, showCredentials: PSM.showCredentials)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            logger.clearLogWithId(log.id)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                })
                            }
                        }
                        .frame(height: geometry.size.height * 0.35)
                    }
                }))
                Setting(textDescription: "Delete all the log entries from the above list.", action: SATextButton(title: "", buttonLabel: "Clear logs", action: { _ in
                    withAnimation {
                        self.logger.clearLogs()
                    }
                }))
                Setting(textDescription: "Delete all the zip-exported log entries.", action: SATextButton(title: "", buttonLabel: "Clear log files", action: { _ in
                    self.logger.clearLocalLogFiles()
                }))
            }
        }
    }
    
    struct LogView: View {
        @ObservedObject private var logger = YouTubeModelLogger.shared
        
        let log: any GenericRequestLog
        let showCredentials: Bool
        var body: some View {
            HStack {
                Text("\(String(describing: log.expectedResultType)) at \(log.date.formatted(date: .numeric, time: .standard))")
                Spacer()
                ShareButtonView(onTap: {
                    self.showShareLogSheet()
                })
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                self.showDetailsSheet()
            }
        }
        
        private func showShareLogSheet() {
            guard let url = logger.exportLog(withId: log.id, showCredentials: showCredentials) else { return }
            let vc = UIActivityViewController(
                activityItems: [LogShareSource(archiveURL: url)],
                applicationActivities: nil
            )
            SheetsModel.shared.showSuperSheet(withViewController: vc)
        }
        
        private func showDetailsSheet() {
            let vc = UIHostingController(rootView: DetailledLogView(log: self.log, showCredentials: self.showCredentials))
            SheetsModel.shared.showSuperSheet(withViewController: vc)
        }
    }
    
    struct DetailledLogView: View {
        let log: any GenericRequestLog
        let showCredentials: Bool
        
        @State private var currentCategory: YouTubeModelLogger.LogCategory = .baseInfos
        var body: some View {
            VStack {
                HStack {
                    Picker("", selection: self.$currentCategory) {
                        Text("Base infos")
                            .tag(YouTubeModelLogger.LogCategory.baseInfos)
                        Text("Request infos")
                            .tag(YouTubeModelLogger.LogCategory.requestInfos)
                        Text("Response data")
                            .tag(YouTubeModelLogger.LogCategory.responseData)
                        Text("Response result")
                            .tag(YouTubeModelLogger.LogCategory.response)
                    }
                    .pickerStyle(.menu)
                    Spacer()
                    CopyToClipboardView(textToCopy: {
                        YouTubeModelLogger.getTextForSelection(log: log, category: currentCategory, showCredentials: showCredentials)
                    })
                    .id(self.currentCategory)
                }
                .padding()
                ScrollView {
                    Text(YouTubeModelLogger.getTextForSelection(log: log, category: currentCategory, showCredentials: showCredentials))
                }
                .padding()
            }
        }
    }
}

class LogShareSource: NSObject, UIActivityItemSource {
    let archiveURL: URL
    
    init(archiveURL: URL) {
        self.archiveURL = archiveURL
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return archiveURL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return archiveURL
    }
        
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return archiveURL.lastPathComponent
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.zip.identifier
    }
}
