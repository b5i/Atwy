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
    
    var body: some View {
        GeometryReader { geometry in
            List {
                Section("Logger") {
                    let loggerActivatedBinding: Binding<Bool> = Binding(get: {
                        return logger.isLogging
                    }, set: { newValue in
                        if newValue {
                            logger.startLogging()
                        } else {
                            logger.stopLogging()
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
                    if let maximumCacheSize = self.logger.maximumCacheSize {
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
                        Text("Logs")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Exported logs can contain cookies and therefore make sure that you trust who's going to have access to them.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                        List {
                            ForEach(logger.logs, id: \.id) { log in
                                LogView(log: log)
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
                                logger.clearLogs()
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
                            logger.clearLocalLogFiles()
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
            }
        }
    }
    
    struct LogView: View {
        @ObservedObject private var logger = YouTubeModelLogger.shared
        
        let log: any GenericRequestLog
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
                        Task {
                            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene, let source =  scene.keyWindow?.rootViewController else { return }
                            if let url = logger.exportLog(withId: log.id, showCredentials: true) {
                                let vc = UIActivityViewController(
                                    activityItems: [LogShareSource(archiveURL: url)],
                                    applicationActivities: nil
                                )
                                
                                // https://forums.developer.apple.com/forums/thread/45898?answerId=134244022#134244022
                                // find the controller that is already presenting a sheet and put a sheet onto its sheet
                                var parentController: UIViewController? = source
                                while((parentController?.presentedViewController != nil) &&
                                      parentController != parentController?.presentedViewController){
                                    parentController = parentController?.presentedViewController;
                                }
                                
                                let finalController: UIViewController
                                
                                if let parentController = parentController {
                                    finalController = parentController
                                } else {
                                    finalController = source
                                }
                                DispatchQueue.main.async {
                                    vc.popoverPresentationController?.sourceView = finalController.view
                                    vc.popoverPresentationController?.barButtonItem = finalController.navigationItem.rightBarButtonItem
                                    finalController.present(vc, animated: true)
                                }
                            }
                        }
                    }
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene, let source =  scene.keyWindow?.rootViewController else { return }
                let vc = UIHostingController(rootView: DetailledLogView(log: log))
                
                // https://forums.developer.apple.com/forums/thread/45898?answerId=134244022#134244022
                // find the controller that is already presenting a sheet and put a sheet onto its sheet
                var parentController: UIViewController? = source
                while((parentController?.presentedViewController != nil) &&
                      parentController != parentController?.presentedViewController){
                    parentController = parentController?.presentedViewController;
                }
                
                let finalController: UIViewController
                
                if let parentController = parentController {
                    finalController = parentController
                } else {
                    finalController = source
                }
                DispatchQueue.main.async {
                    vc.popoverPresentationController?.sourceView = finalController.view
                    vc.popoverPresentationController?.barButtonItem = finalController.navigationItem.rightBarButtonItem
                    finalController.present(vc, animated: true)
                }
            }
        }
    }
    
    struct DetailledLogView: View {
        let log: any GenericRequestLog
                
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
        
        @State private var currentCategory: LogCategory = .baseInfos
        var body: some View {
            VStack {
                HStack {
                    let categoryBinding: Binding<LogCategory> = Binding(get: {
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
                            .tag(LogCategory.baseInfos)
                        Text("Request infos")
                            .tag(LogCategory.requestInfos)
                        Text("Response data")
                            .tag(LogCategory.responseData)
                        Text("Response result")
                            .tag(LogCategory.response)
                    }
                    .pickerStyle(.menu)
                    Spacer()
                    Image(systemName: copiedToClipboard ? "doc.on.clipboard.fill" : "doc.on.clipboard")
                        .resizable()
                        .scaledToFit()
                        .animation(.default, value: copiedToClipboard)
                        .onTapGesture {
                            UIPasteboard.general.string = getTextForSelection(category: currentCategory)
                            self.copiedToClipboard = true
                        }
                        .frame(width: 20, height: 20)
                        .contentShape(Rectangle())
                }
                .padding()
                ScrollView {
                    Text(getTextForSelection(category: currentCategory))
                }
                .padding()
            }
        }
        
        func getTextForSelection(category: LogCategory) -> String {
            switch currentCategory {
            case .baseInfos:
                return """
                        id: \(log.id.uuidString)
                        date: \(log.date.formatted())
                        expectedResultType: \(String(describing: log.expectedResultType))
                        providedParameters: \(String(describing: log.providedParameters))
                        """
            case .requestInfos:
                return """
                        url: \(String(describing: log.request?.url))
                        httpFields: \(String(describing: log.request?.allHTTPHeaderFields))
                        httpBody: \(String(decoding: log.request?.httpBody ?? Data(), as: UTF8.self))
                        httpMethod: \(String(describing: log.request?.httpMethod))
                        cachePolicy: \(String(describing: log.request?.cachePolicy.rawValue))
                        """
            case .responseData:
                return String(decoding: log.responseData ?? Data(), as: UTF8.self)
            case .response:
                let newLog = log
                return YouTubeModelLogger.shared.getResultString(fromLog: newLog)
            }
        }
        
        enum LogCategory {
            case baseInfos
            case requestInfos
            case responseData
            case response
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
