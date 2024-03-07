//
//  LoggerSettingsView.swift
//  Atwy
//
//  Created by Antoine Bollengier on 07.03.2024.
//  Copyright © 2024 Antoine Bollengier. All rights reserved.
//  

import SwiftUI
import UniformTypeIdentifiers

struct LoggerSettingsView: View {
    @ObservedObject private var PSM = PreferencesStorageModel.shared
    @ObservedObject private var logger = YouTubeModelLogger.shared
    
    @State private var performanceChoice: PreferencesStorageModel.Properties.PerformanceModes
    
    init() {
        /// Maybe using AppStorage would be better
        if let state = PreferencesStorageModel.shared.propetriesState[.performanceMode] as? PreferencesStorageModel.Properties.PerformanceModes {
            self._performanceChoice = State(wrappedValue: state)
        } else {
            self._performanceChoice = State(wrappedValue: .full)
        }
    }
    
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
                        Text("Logs")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Exported logs can contain cookies and therefore make sure that you trust who's going to have access to them.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.caption)
                            .foregroundStyle(.gray)
                        List {
                            ForEach(logger.logs, id: \.id) { log in
                                HStack {
                                    Text("\(String(describing: log.expectedResultType)) at \(log.date.formatted())")
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            Task {
                                                guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene, let source =  scene.keyWindow?.rootViewController else { return }
                                                if let url = logger.exportLog(withId: log.id) {
                                                    let vc = UIActivityViewController(
                                                        activityItems: [LogShareSource(archiveURL: url)],
                                                        applicationActivities: nil
                                                    )
                                                    
                                                    // https://forums.developer.apple.com/forums/thread/45898?answerId=134244022#134244022
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
                        .listStyle(.plain)
                        .frame(height: geometry.size.height * 0.35)
                    }
                    HStack {
                        Button {
                            logger.clearLocalLogFiles()
                        } label: {
                            Text("Clear log files")
                                .frame(alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    HStack {
                        Button {
                            withAnimation {
                                logger.clearLogs()
                            }
                        } label: {
                            Text("Clear logs")
                                .frame(alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    /*
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.ultraThickMaterial)
                        HStack {
                            if performanceChoice == .limited {
                                Spacer()
                            }
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.orange)
                                .frame(width: geometry.size.width * 0.28, height: geometry.size.height * 0.08)
                                .padding(.horizontal)
                            if performanceChoice != .limited {
                                Spacer()
                            }
                        }
                        HStack {
                            HStack {
                                Spacer()
                                Text("Full")
                                Image(systemName: "hare.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                Spacer()
                            }
                            .onTapGesture {
                                withAnimation(.spring) {
                                    performanceChoice = .full
                                    PSM.setNewValueForKey(.performanceMode, value: PreferencesStorageModel.Properties.PerformanceModes.full)
                                }
                            }
                            Spacer()
//                            RoundedRectangle(cornerRadius: 50)
//                                .frame(width: 2)
//                                .foregroundStyle(.thickMaterial)
//                                .padding(.vertical)
//                            Spacer()
                            HStack {
                                Spacer()
                                Text("Limited")
                                Image(systemName: "tortoise.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                Spacer()
                            }
                            .onTapGesture {
                                withAnimation(.spring) {
                                    performanceChoice = .limited
                                    PSM.setNewValueForKey(.performanceMode, value: PreferencesStorageModel.Properties.PerformanceModes.limited)
                                }
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.7, height: geometry.size.height * 0.10)
                    .centered()
                    Text("Enabling the limited performance mode will use less CPU and RAM while using the app. It will use other UI components that could make your experience a bit more laggy if the app was working smoothly before but it could make it more smooth if the app was very laggy before.")
                        .foregroundStyle(.gray)
                        .font(.caption)
                     */
                }
                .onAppear {
                    if let state = PreferencesStorageModel.shared.propetriesState[.performanceMode] as? PreferencesStorageModel.Properties.PerformanceModes {
                        self.performanceChoice = state
                    } else {
                        self.performanceChoice = .full
                    }
                }
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
