//
//  LoggerSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 07.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import SwiftUI
import UniformTypeIdentifiers
import YouTubeKit

struct LoggerSettingsView: View {
    static let maxCacheLimitDefaultValue: Int = 5
    
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var logger = YouTubeModelLogger.shared
    
    @State private var showCredentials: Bool
    
    init() {
        /// Maybe using AppStorage would be better
        if let state = PreferencesStorageModel.shared.propetriesState[.showCredentials] as? Bool {
            self._showCredentials = State(wrappedValue: state)
        } else {
            self._showCredentials = State(wrappedValue: false)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            List {
                Section("Logger") {
                    let loggerActivatedBinding: Binding<Bool> = Binding(get: {
                        return self.logger.isLogging
                    }, set: { newValue in
                        if newValue {
                            self.logger.startLogging()
                        } else {
                            self.logger.stopLogging()
                        }
                    })
                    HStack {
                        Toggle(isOn: loggerActivatedBinding, label: {
                            Text("Activate Logger")
                        })
                    }
                    VStack {
                        let cacheLimitEnabledBinding: Binding<Bool> = Binding(get: {
                            self.logger.maximumCacheSize != nil
                        }, set: { newValue in
                            self.logger.setCacheSize(newValue ? Self.maxCacheLimitDefaultValue : nil)
                        })
                        Toggle(isOn: cacheLimitEnabledBinding, label: {
                            Text("Logger Cache Limit")
                        })
                        Text("Setting a cache limit for the logger will avoid having a lot of RAM consumed to store all the requests. The logger will only keep the n last logs in memory, the rest will be deleted. " + (cacheLimitEnabledBinding.wrappedValue ? "" : "The default value for the cache limit is \(Self.maxCacheLimitDefaultValue), if you activate it, only the \(Self.maxCacheLimitDefaultValue) more recent logs will be kept."))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if self.logger.maximumCacheSize != nil {
                        VStack {
                            let cacheLimitBinding: Binding<Int> = Binding(get: {
                                self.logger.maximumCacheSize ?? 5
                            }, set: { newValue in
                                self.logger.setCacheSize(max(newValue, 0))
                            })
                            Stepper(value: cacheLimitBinding, step: 1, label: {
                                HStack {
                                    Text("Limit")
                                    Spacer()
                                    Text(String(cacheLimitBinding.wrappedValue))
                                }
                            })
                        }
                    }
                    VStack {
                        let showCredentialsBinding: Binding<Bool> = Binding(get: {
                            return self.showCredentials
                        }, set: { newValue in
                            self.showCredentials = newValue
                            self.PSM.setNewValueForKey(.showCredentials, value: newValue)
                        })
                        Toggle(isOn: showCredentialsBinding, label: {
                            Text("Show credentials")
                        })
                        Text("Exported logs can contain cookies and therefore make sure that you trust who's going to have access to them. Disabling this option will hide the credentials in the UI and in log exports.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    VStack {
                        Text("Logs")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        List {
                            ForEach(logger.logs, id: \.id) { log in
                                LogView(log: log, showCredentials: showCredentials)
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
                    VStack {
                        Button {
                            withAnimation {
                                self.logger.clearLogs()
                            }
                        } label: {
                            Text("Clear logs")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text("Delete all the log entries from the above list.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    VStack {
                        Button {
                            self.logger.clearLocalLogFiles()
                        } label: {
                            Text("Clear log files")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text("Delete all the zip-exported log entries.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .onAppear {
                    if let state = self.PSM.propetriesState[.showCredentials] as? Bool {
                        self.showCredentials = state
                    } else {
                        self.showCredentials = false
                    }
                }
            }
        }
        .navigationTitle("Logger")
    }
    
    struct LogView: View {
        @ObservedObject private var logger = YouTubeModelLogger.shared
        
        let log: any GenericRequestLog
        let showCredentials: Bool
        var body: some View {
            HStack {
                Text("\(String(describing: log.expectedResultType)) at \(log.date.formatted(date: .numeric, time: .standard))")
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.showShareLogSheet()
                    }
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
            let vc = UIActivityViewController(
                activityItems: [DetailledLogView(log: self.log, showCredentials: self.showCredentials)],
                applicationActivities: nil
            )
            SheetsModel.shared.showSuperSheet(withViewController: vc)
        }
    }
    
    struct DetailledLogView: View {
        let log: any GenericRequestLog
        let showCredentials: Bool
                
        @State private var copiedToClipboard: Bool = false {
            didSet {
                if self.copiedToClipboard {
                    self.resetClipboardIconTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { timer in
                        self.copiedToClipboard = false
                    })
                }
            }
        }
        
        @State private var resetClipboardIconTimer: Timer? = nil
        
        @State private var currentCategory: YouTubeModelLogger.LogCategory = .baseInfos
        var body: some View {
            VStack {
                HStack {
                    let categoryBinding: Binding<YouTubeModelLogger.LogCategory> = Binding(get: {
                        return self.currentCategory
                    }, set: { newValue in
                        if self.currentCategory != newValue {
                            self.resetClipboardIconTimer?.invalidate()
                            self.copiedToClipboard = false
                        }
                        self.currentCategory = newValue
                    })
                    Picker("", selection: categoryBinding) {
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
                    Image(systemName: copiedToClipboard ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                        .resizable()
                        .scaledToFit()
                        .animation(.default, value: copiedToClipboard)
                        .onTapGesture {
                            UIPasteboard.general.string = YouTubeModelLogger.getTextForSelection(log: log, category: currentCategory, showCredentials: showCredentials)
                            self.copiedToClipboard = true
                        }
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
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
