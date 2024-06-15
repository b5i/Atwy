//
//  ShazamProcessing.swift
//  Atwy
//
//  Created by Antoine Bollengier on 21.01.23.
//

import Foundation
import ShazamKit
import OSLog

class ShazamProcessing: NSObject, ObservableObject, SHSessionDelegate {
    private var session: SHSession?

    func match(buffer: AVAudioPCMBuffer, audioTime: AVAudioTime) throws {
        session = SHSession()
        session!.delegate = self
        session!.matchStreamingBuffer(buffer, at: audioTime)
    }

    func session(_ session: SHSession, didFind match: SHMatch) {
        Logger.atwyLogs.simpleLog("\(String(describing: match))")
    }

    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature, error: Error?) {
        Logger.atwyLogs.simpleLog("Did not find match")
    }
}

let shazamProcessing = ShazamProcessing()

// https://stackoverflow.com/questions/69908897/how-to-create-avaudiopcmbuffer-with-cmsamplebuffer
extension AVAudioPCMBuffer {
    static func create(from sampleBuffer: CMSampleBuffer) -> AVAudioPCMBuffer? {

        guard let description: CMFormatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let sampleRate: Float64 = description.audioStreamBasicDescription?.mSampleRate,
              let channelsPerFrame: UInt32 = description.audioStreamBasicDescription?.mChannelsPerFrame /*,
                                                                                                         let numberOfChannels = description.audioChannelLayout?.numberOfChannels */
        else { return nil }

        guard let blockBuffer: CMBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return nil
        }

        let samplesCount = CMSampleBufferGetNumSamples(sampleBuffer)

        // let length: Int = CMBlockBufferGetDataLength(blockBuffer)

        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: AVAudioChannelCount(1), interleaved: false)

        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: AVAudioFrameCount(samplesCount))!
        buffer.frameLength = buffer.frameCapacity

        // GET BYTES
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: nil, dataPointerOut: &dataPointer)

        guard var channel: UnsafeMutablePointer<Float> = buffer.floatChannelData?[0],
              let data = dataPointer else { return nil }

        var data16 = UnsafeRawPointer(data).assumingMemoryBound(to: Int16.self)

        for _ in 0...samplesCount - 1 {
            channel.pointee = Float32(data16.pointee) / Float32(Int16.max)
            channel += 1
            for _ in 0...channelsPerFrame - 1 {
                data16 += 1
            }

        }

        return buffer
    }
}
