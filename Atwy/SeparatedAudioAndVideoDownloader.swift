//
//  SeparatedAudioAndVideoDownloader.swift
//  Atwy
//
//  Created by Antoine Bollengier on 03.11.2024.
//  Copyright © 2024-2026 Antoine Bollengier (github.com/b5i). All rights reserved.
//

import Foundation
import OSLog
import AVFoundation

class SeparatedAudioAndVideoDownloader {
    let audioURL: URL
    let videoURL: URL
    let downloadInfo: HLSDownloader.DownloadInfo
    
    weak private var downloader: HLSDownloader?
    
    private var audioTask: URLSessionDownloadTask?
    private var videoTask: URLSessionDownloadTask?
    
    private let audioDownloader = Downloader()
    private let videoDownloader = Downloader()
            
    private var audioLocation: URL?
    private var videoLocation: URL?
    
    private var endOfDownload: (Result<URL, Error>) -> Void
        
    init(audioURL: URL, videoURL: URL, downloadInfo: HLSDownloader.DownloadInfo, downloader: HLSDownloader, endOfDownload: @escaping (Result<URL, Error>) -> Void) {
        self.audioURL = audioURL
        self.videoURL = videoURL
        self.downloadInfo = downloadInfo
        self.downloader = downloader
        self.endOfDownload = endOfDownload
    }
    
    private class Downloader: NSObject, URLSessionDownloadDelegate {
        var finishHandler: ((Result<URL, Error>) -> Void)?
        var progressHandler: (() -> Void)?
        private(set) var totalBytesToReceive: Int?
        private(set) var percentComplete: Double = 0.0
        private(set) var downloadLocation: URL?
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                self.finishHandler?(.failure("Couldn't get document directory"))
                return
            }
            
            guard let finalURL = URL(string: "\(docDir.absoluteString)\(UUID().uuidString).mp4") else {
                self.finishHandler?(.failure("Couldn't create final URL"))
                return
            }
            
            do {
                try FileManager.default.copyItem(at: location, to: finalURL)
            } catch {
                self.finishHandler?(.failure(error))
            }
            
            self.finishHandler?(.success(finalURL))
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            guard totalBytesExpectedToWrite != 0 else { return }
            DispatchQueue.main.async {
                self.percentComplete = max(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite), self.percentComplete)
                self.totalBytesToReceive = Int(totalBytesExpectedToWrite)
                self.progressHandler?()
            }
        }
        
        func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
            self.finishHandler?(.failure(error ?? "Unknown error"))
        }
    }
    
    func start() {
        guard self.audioTask == nil && self.videoTask == nil else {
            // resume
            
            self.audioTask?.resume()
            self.videoTask?.resume()
            return
        }
        
        var audioRequest = URLRequest(url: audioURL)
        audioRequest.setValue("bytes=0-", forHTTPHeaderField: "Range")
        self.audioTask = URLSession.shared.downloadTask(with: audioRequest)
        self.audioTask?.delegate = self.audioDownloader
        
        var videoRequest = URLRequest(url: videoURL)
        videoRequest.setValue("bytes=0-", forHTTPHeaderField: "Range")
        self.videoTask = URLSession.shared.downloadTask(with: videoRequest)
        self.videoTask?.delegate = self.videoDownloader
        
        self.audioDownloader.finishHandler = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let location):
                self.audioLocation = location
                self.finish()
            case .failure(let error):
                self.videoTask?.cancel()
                self.endOfDownload(.failure("Failed to download audio: \(error.localizedDescription)"))
                return
            }
        }
            
        self.videoDownloader.finishHandler = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let location):
                self.videoLocation = location
                self.finish()
            case .failure(let error):
                self.audioTask?.cancel()
                self.endOfDownload(.failure("Failed to download video: \(error.localizedDescription)"))
                return
            }
        }
        
        self.audioDownloader.progressHandler = { [weak self] in
            guard let self = self else { return }
            self.updatePercentage()
        }
        
        self.videoDownloader.progressHandler = { [weak self] in
            guard let self = self else { return }
            self.updatePercentage()
        }
        
        self.audioTask?.resume()
        self.videoTask?.resume()
    }
    
    func pause() {
        self.audioTask?.suspend()
        self.videoTask?.suspend()
    }
    
    func cancel() {
        self.audioTask?.cancel()
        self.videoTask?.cancel()
        
        do {
            if let audioLocation = self.audioLocation {
                try? FileManager.default.removeItem(at: audioLocation)
            }
            
            if let videoLocation = self.videoLocation {
                try? FileManager.default.removeItem(at: videoLocation)
            }
        } catch {
            Logger.atwyLogs.simpleLog("Error removing audio or video file: \(error.localizedDescription)")
        }        
    }
    
    private func updatePercentage() {
        guard let audioTotalBytes = self.audioDownloader.totalBytesToReceive, let videoTotalBytes = self.videoDownloader.totalBytesToReceive else {
            Logger.atwyLogs.simpleLog("Couldn't update percentage, one of the totalBytes is nil")
            return
        }
           
        let totalBytes = audioTotalBytes + videoTotalBytes
        
        guard totalBytes != 0 else {
            Logger.atwyLogs.simpleLog("Couldn't update percentage, totalBytes is 0")
            return
        }
        
        let audioSizePercentage = Double(audioTotalBytes) / Double(totalBytes)
        let videoSizePercentage = Double(videoTotalBytes) / Double(totalBytes)
        
        DispatchQueue.main.async {
            self.downloader?.percentComplete = (self.videoDownloader.percentComplete * videoSizePercentage) + (self.audioDownloader.percentComplete * audioSizePercentage)
        }
    }
    
    private func finish() {
        guard let audioLocation = self.audioLocation, let videoLocation = self.videoLocation else {
            if self.audioLocation == nil && self.videoLocation == nil {
                self.endOfDownload(.failure("Both audio and video download locations are nil"))
                return
            }
                
            print("Audio or video download location is nil, waiting for both to finish")
            return
        }
        
        Task {
            guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                self.endOfDownload(.failure("Couldn't get document directory"))
                return
            }
            
            // merge audio and video
            
            let assetComposition = AVMutableComposition()
            let audioAsset = AVURLAsset(url: audioLocation)
            let videoAsset = AVURLAsset(url: videoLocation)
            
            let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            do {
                var minDuration = try await min(audioAsset.load(.duration), videoAsset.load(.duration))
                minDuration.timescale *= 2 // duration is two times it actually is, so we need to divide it by 2
                
                guard let audioCompositionTrack = audioCompositionTrack, let videoCompositionTrack = videoCompositionTrack else {
                    self.endOfDownload(.failure("Audio or video composition track is nil"))
                    return
                }
                
                guard let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first, let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else {
                    self.endOfDownload(.failure("Couldn't get audio or video track"))
                    return
                }
                
                try audioCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: minDuration), of: audioTrack, at: .zero)
                try videoCompositionTrack.insertTimeRange(CMTimeRange(start: .zero, duration: minDuration), of: videoTrack, at: .zero)
                
                let exportSession = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPresetHighestQuality)
                
                guard let exportSession = exportSession else {
                    self.endOfDownload(.failure("Couldn't create export session"))
                    return
                }
                
                exportSession.outputFileType = .mp4
                
                let finalURL = URL(string: "\(docDir.absoluteString)\(self.downloadInfo.video.videoId).mp4")!
                
                exportSession.outputURL = finalURL
                
                exportSession.exportAsynchronously {
                    if let error = exportSession.error {
                        self.endOfDownload(.failure("Error exporting video (merging audio and video): \(error.localizedDescription)"))
                        return
                    }
                            
                    do {
                        try FileManager.default.removeItem(at: audioLocation)
                        try FileManager.default.removeItem(at: videoLocation)
                    } catch {
                        Logger.atwyLogs.simpleLog("Error removing audio or video file: \(error.localizedDescription)")
                    }
                                        
                    self.endOfDownload(.success(finalURL))
                }
            } catch {
                self.endOfDownload(.failure("Error merging audio and video: \(error.localizedDescription)"))
                return
            }
        }
    }
}
