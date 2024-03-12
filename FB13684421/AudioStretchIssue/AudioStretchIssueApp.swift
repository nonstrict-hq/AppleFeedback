//
//  AudioStretchIssueApp.swift
//  Untitled 1
//
//  Created by Nonstrict on 2024-02-26.
//

import SwiftUI
import AVFoundation

@main
struct AudioStretchIssueApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

let original10min = Bundle.main.url(forResource: "AudioStretchTest-10min", withExtension: "m4a")!
let original90min = Bundle.main.url(forResource: "AudioStretchTest-90min", withExtension: "m4a")!

let originalURL = original90min

struct ContentView: View {
    @State var isActive = false
    @State var originalURL = original10min

    var body: some View {
        VStack {
            Picker("Input", selection: $originalURL) {
                Text("10 min example").tag(original10min)
                Text("90 min example").tag(original90min)
            }

            HStack {
                Text("Input file:")
                Button("\(originalURL.lastPathComponent)") {
                    Task {
                        NSWorkspace.shared.open(originalURL)
                    }
                }
            }
            Divider()

            HStack {
                Text("No shrink:")
                Button("Copy unchanged") {
                    Task {
                        await modify(removing: CMTime.zero, originalURL: originalURL)
                    }
                }
            }

            HStack {
                Text("Broken:")
                Button("Adding by 8 seconds") {
                    Task {
                        await modify(adding: CMTime(value: 8, timescale: 1), originalURL: originalURL)
                    }
                }
            }

            HStack {
                Text("Broken:")
                Button("Shrink by 8 seconds") {
                    Task {
                        await modify(removing: CMTime(value: 8, timescale: 1), originalURL: originalURL)
                    }
                }
            }

        }
        .padding()
    }

    private func modify(removing diff: CMTime, originalURL: URL) async {
        isActive = true
        defer { isActive = false }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(Date().timeIntervalSinceReferenceDate).m4a")
        let asset = AVURLAsset(url: originalURL)

        do {
            let duration = try await asset.load(.duration) - diff
            try await stretch(inputURL: originalURL, to: duration, outputURL: outputURL)
            NSWorkspace.shared.open(outputURL)
        } catch let error as NSError {
            print(error.debugDescription)
            fatalError(error.debugDescription)
        }
    }

    private func modify(adding diff: CMTime, originalURL: URL) async {
        isActive = true
        defer { isActive = false }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(Date().timeIntervalSinceReferenceDate).m4a")
        let asset = AVURLAsset(url: originalURL)

        do {
            let duration = try await asset.load(.duration) + diff
            try await stretch(inputURL: originalURL, to: duration, outputURL: outputURL)
            NSWorkspace.shared.open(outputURL)
        } catch let error as NSError {
            print(error.debugDescription)
            fatalError(error.debugDescription)
        }
    }
}


private func stretch(inputURL: URL, to targetDuration: CMTime, outputURL: URL) async throws {
    let inputAudioAsset = AVAsset(url: inputURL)
    let inputAudioTrack = inputAudioAsset.tracks(withMediaType: .audio).first!

    let composition = AVMutableComposition()
    let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!

    let audioTimeRange = CMTimeRange(start: .zero, duration: inputAudioAsset.duration)
    try audioTrack.insertTimeRange(audioTimeRange, of: inputAudioTrack, at: .zero)

    composition.scaleTimeRange(audioTimeRange, toDuration: targetDuration)

    let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
    exportSession.outputURL = outputURL
    exportSession.outputFileType = .m4a
    await exportSession.export()

    if let error = exportSession.error {
        throw error
    }
    guard exportSession.status == .completed else {
        fatalError("Not completed")
    }
}
