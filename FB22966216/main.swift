//
//  main.swift
//  FB22966216 — AVAssetWriter finishWriting hangs forever when a large CMSampleBuffer is appended.
//
//  Appending a single audio CMSampleBuffer of >= 2^27 frames (134,217,728) to an AAC
//  AVAssetWriterInput makes finishWriting() never return — the audio-compression thread spins at
//  100% CPU. Running this hangs (the final print is never reached).
//
//  Run:  swift main.swift
//  Change (1 << 27) to (1 << 27) - 1 and it finalizes in ~2 seconds instead.
//

import AVFoundation

let frames = AVAudioFrameCount(1 << 27) // 2^27 = 134,217,728 frames — the encoder hangs at/above this

// One silent PCM buffer (48 kHz mono Float32) of `frames` frames.
let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
pcm.frameLength = frames // AVAudioPCMBuffer is zero-filled => digital silence

var formatDescription: CMAudioFormatDescription?
CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault, asbd: format.streamDescription,
    layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil, extensions: nil,
    formatDescriptionOut: &formatDescription)

var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 48_000),
    presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
var sampleBuffer: CMSampleBuffer?
CMSampleBufferCreate(allocator: kCFAllocatorDefault, dataBuffer: nil, dataReady: false,
    makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDescription,
    sampleCount: CMItemCount(frames), sampleTimingEntryCount: 1, sampleTimingArray: &timing,
    sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &sampleBuffer)
CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer!, blockBufferAllocator: kCFAllocatorDefault,
    blockBufferMemoryAllocator: kCFAllocatorDefault, flags: 0, bufferList: pcm.audioBufferList)

// AAC .m4a writer.
let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("aac-hang.m4a")
try? FileManager.default.removeItem(at: url)
let writer = try! AVAssetWriter(url: url, fileType: .m4a)
let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVNumberOfChannelsKey: 1,
    AVSampleRateKey: 48_000,
])
input.expectsMediaDataInRealTime = true
writer.add(input)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

print("append(\(frames) frames) returned:", input.append(sampleBuffer!))
input.markAsFinished()

print("calling finishWriting() — never returns at or above 2^27 frames …")
await writer.finishWriting() // hangs here forever (encoder thread at 100% CPU)
print("finishWriting() completed") // never reached
