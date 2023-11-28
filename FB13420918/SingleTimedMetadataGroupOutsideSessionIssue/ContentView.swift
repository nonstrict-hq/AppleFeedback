//
//  ContentView.swift
//  SingleTimedMetadataGroupOutsideSessionIssue
//
//  Created by Mathijs Kadijk on 28/11/2023.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    enum Scenario {
        case beforeSessionStart
        case insideSession
        case workaround
    }

    @State var output = "No output yet."

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Scenario 1")
                        .font(.title)

                    Text("The only appended timed metadata group starts BEFORE asset writer session start time, no other groups are appended.")
                    Text("**Expected:** 1 group at start 0 with duration 10; Timerange of timed metadata group is adjusted to span the full session and written to the file.")
                    Text("**Actual:** 0 groups; No timed metadata group is written to the file at all.")

                    Button("Run scenario") {
                        output = "Running..."
                        Task {
                            await run(scenario: .beforeSessionStart)
                        }
                    }
                }
                .padding()

                VStack(alignment: .leading, spacing: 24) {
                    Text("Scenario 2")
                        .font(.title)

                    Text("The only appended timed metadata group starts BETWEEN asset writer session start and end time, no other groups appended.")
                    Text("**Expected:** 1 group at start 5 with duration 5; End time of timed metadata group is adjusted so it ends at the session end time and is written to the file.")
                    Text("**Actual:** 1 group at start 5 with duration 0.067; Timed metadata group is written to the file at the correct start time, but with a very short duration.")

                    Button("Run scenario") {
                        output = "Running..."
                        Task {
                            await run(scenario: .insideSession)
                        }
                    }
                }
                .padding()

                VStack(alignment: .leading, spacing: 24) {
                    Text("Workaround")
                        .font(.title)

                    Text("Appending any other timed metadata group fixes the problem.")
                    Text("Since we don't have extra data we can add dummy data after the session ends to get the expected behaviour.")

                    Button("Run scenario") {
                        output = "Running..."
                        Task {
                            await run(scenario: .workaround)
                        }
                    }
                }
                .padding()
            }
            .padding()

            Text("Output")
                .font(.title2)

            Text(output)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize()
        }
    }

    func run(scenario: Scenario) async {
        // Setup a metadata group
        let metadataItem = AVMutableMetadataItem()
        metadataItem.dataType = kCMMetadataBaseDataType_UTF8 as String
        metadataItem.identifier = AVMetadataItem.identifier(forKey: "com.nonstrict.example", keySpace: .quickTimeMetadata)
        metadataItem.value = "example-value" as NSString

        let timedMetadataGroupAtOneSecond = AVTimedMetadataGroup(items: [metadataItem],
                                                                 timeRange: CMTimeRange(start: CMTime(seconds: 1, preferredTimescale: 1000), end: .invalid))
        let timedMetadataGroupAtTenSeconds = AVTimedMetadataGroup(items: [metadataItem],
                                                                  timeRange: CMTimeRange(start: CMTime(seconds: 10, preferredTimescale: 1000), end: .invalid))
        let timedMetadataGroupAtOneMinute = AVTimedMetadataGroup(items: [metadataItem],
                                                                 timeRange: CMTimeRange(start: CMTime(seconds: 60, preferredTimescale: 1000), end: .invalid))

        // Grab a place to write the file to
        let temporaryDirectoryURL = URL(filePath: NSTemporaryDirectory())
        let outputURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString + ".mov", conformingTo: .quickTimeMovie)

        // Setup asset writing
        let metadataInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil, sourceFormatHint: timedMetadataGroupAtOneSecond.copyFormatDescription())
        let metadataInputAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: metadataInput)

        let assetWriter = try! AVAssetWriter(url: outputURL, fileType: .mov)
        assetWriter.add(metadataInput)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime(seconds: 5, preferredTimescale: 1000))

        switch scenario {
        case .beforeSessionStart:
            // SCENARIO 1: The only appended timed metadata group starts BEFORE asset writer session start time, no other groups appended.
            //
            // Expected: Timerange of timed metadata group is adjusted to span the full session and written to the file.
            // Actual: No timed metadata group is written to the file at all.
            metadataInputAdaptor.append(timedMetadataGroupAtOneSecond)

        case .insideSession:
            // SCENARIO 2: The only appended timed metadata group starts BETWEEN asset writer session start and end time, no other groups appended.
            //
            // Expected: End time of timed metadata group is adjusted so it ends at the session end time and is written to the file.
            // Actual: Timed metadata group is written to the file at the correct start time, but with a very short duration (0.67 seconds).
            metadataInputAdaptor.append(timedMetadataGroupAtTenSeconds)

        case .workaround:
            // WORKAROUND: Appending any other timed metadata group fixes the problem.
            // Since we don't have extra data we can add dummy data after the session ends to get the expected behaviour.
            metadataInputAdaptor.append(timedMetadataGroupAtOneSecond)
            metadataInputAdaptor.append(timedMetadataGroupAtOneMinute)
        }

        // Wrap up writing
        assetWriter.endSession(atSourceTime: CMTime(seconds: 15, preferredTimescale: 1000))
        await assetWriter.finishWriting()

        // Setup asset reading
        let asset = AVAsset(url: outputURL)
        let metadataTrack = try! await asset.loadTracks(withMediaType: .metadata).first!
        let reader = try! AVAssetReader(asset: asset)
        let metadataOutput = AVAssetReaderTrackOutput(track: metadataTrack, outputSettings: nil)
        let metadataOutputAdaptor = AVAssetReaderOutputMetadataAdaptor(assetReaderTrackOutput: metadataOutput)
        reader.add(metadataOutput)
        reader.startReading()

        // Grab all timed metadata
        var timedMetadataGroups: [AVTimedMetadataGroup] = []
        while let nextTimedMetadataGroup = metadataOutputAdaptor.nextTimedMetadataGroup() {
            timedMetadataGroups.append(nextTimedMetadataGroup)
        }

        // Print all timings of metadata we found
        output = "Read \(timedMetadataGroups.count) AVTimedMetadataGroups from AVAsset:\n" + timedMetadataGroups.enumerated().map { (idx, group) in
            " - Group \(idx): Start \(group.timeRange.start.seconds) Duration: \(group.timeRange.duration.seconds)"
        }.joined(separator: "\n")
    }
}

#Preview {
    ContentView()
}
