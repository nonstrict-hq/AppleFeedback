//
//  AVCaptureSessionWrongFormatApp.swift
//  AVCaptureSessionWrongFormat
//
//  Created by Nonstrict on 2025-02-07.
//

import SwiftUI
import AVKit

@main
struct AVCaptureSessionWrongFormatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


struct Recording: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let bitrates: Set<UInt32>
    var corrupt: Bool { bitrates.count != 1 }
}

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    @AppStorage("microphoneID") var microphoneID: AVCaptureDevice.ID?
    @AppStorage("autoStop") var autoStop = true
    @State var recording: Recording?

    var activeFormatDescription: String {
        guard
            let microphone = viewModel.microphones.first(where: { $0.uniqueID == microphoneID }),
            let acbd = microphone.activeFormat.formatDescription.audioStreamBasicDescription
        else { return "-" }

        return String(describing: acbd)
    }

    var body: some View {
        VStack {
            Picker("Microphone", selection: $microphoneID) {
                Text("None").tag(nil as AVCaptureDevice.ID?)
                ForEach(viewModel.microphones) { microphone in
                    Text(microphone.localizedName).tag(microphone.id)
                }
            }
            HStack {
                Text("Active ASBD:")
                Text("\(activeFormatDescription)").textSelection(.enabled)
                Spacer()
            }

            Toggle("Auto stop recording", isOn: $autoStop)
            Button("Start recording") {
                if let microphoneID {
                    Task {
                        let microphone = AVCaptureDevice(uniqueID: microphoneID)!
                        try viewModel.startRecording(microphone: microphone, autoStop: autoStop)
                    }
                }
            }
            .disabled(microphoneID == nil || viewModel.recordingSession != nil)

            Button("Stop recording") {
                Task {
                    await viewModel.stopRecording()
                }
            }
            .disabled(viewModel.recordingSession == nil)

            Text("Recordings: \(viewModel.recordings.count)")
            List(selection: $recording) {
                ForEach(viewModel.recordings) { recording in
                    HStack {
                        Text(recording.url.lastPathComponent)
                        Spacer()
                        if recording.corrupt {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                        Text("Recorded bitrates:").foregroundStyle(.secondary).font(.caption)
                        Text(recording.bitrates.sorted().map(\.description).joined(separator: ", "))
                    }
                    .tag(recording)
                }
            }

            HStack {
                Text("\(recording?.url.path() ?? "")").textSelection(.enabled)
                Button("Open Dir") {
                    guard let dir = recording?.url.deletingLastPathComponent() else { return }
                    NSWorkspace.shared.open(dir)
                }
                .disabled(recording?.url == nil)
            }
            VStack {
                if let url = recording?.url {
                    AudioPlayerView(url: url)
                }
            }.frame(height: 44)
        }
        .padding()
    }
}

struct AudioPlayerView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> AVPlayerView {
        let player = AVPlayer(playerItem: context.coordinator.playerItem(url: url))
        context.coordinator.playerErrorObservation = player.observe(\.error) { player, _ in
            guard let error = player.error as? NSError else { return }
            print("AVPlayer error", error.debugDescription)
        }
        let view = AVPlayerView()
        view.player = player
        return view
    }

    func updateNSView(_ view: AVPlayerView, context: NSViewRepresentableContext<Self>) {
        if url != (view.player?.currentItem?.asset as? AVURLAsset)?.url {
            view.player?.replaceCurrentItem(with: context.coordinator.playerItem(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var playerErrorObservation: NSKeyValueObservation?
        var itemErrorObservation: NSKeyValueObservation?

        func playerItem(url: URL) -> AVPlayerItem {
            let playerItem = AVPlayerItem(url: url)
            itemErrorObservation = playerItem.observe(\.error) { playerItem, _ in
                guard let error = playerItem.error as? NSError else { return }
                print("AVPlayerItem error", error.debugDescription)
            }

            return playerItem
        }
    }
}

extension AVCaptureDevice: @retroactive Identifiable {
    public var id: String { self.uniqueID }
}

@MainActor class ViewModel: ObservableObject {
    @Published var microphones: [AVCaptureDevice] = []
    @Published var isRecording = false
    @Published var recordings: [Recording] = []

    private let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified)
    private var deviceObservation: NSKeyValueObservation?

    init() {
        deviceObservation = discovery.observe(\.devices, options: [.initial, .new]) { [weak self]  discovery, change in
            DispatchQueue.main.async {
                self?.microphones = discovery.devices
            }
        }
    }

    @Published var recordingSession: RecordingSession?
    func startRecording(microphone: AVCaptureDevice, autoStop: Bool) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("audio-\(Date.now.ISO8601Format()).m4a")

        recordingSession = try RecordingSession(url: url, captureDevice: microphone)
        recordingSession?.start()

        print(">> Started recording", url.lastPathComponent)

        if autoStop {
            Task {
                try await Task.sleep(for: .seconds(1))
                await self.stopRecording()
            }
        }
    }

    func stopRecording() async {
        guard let recordingSession else { return }
        await recordingSession.stop()
        recordings.append(Recording(url: recordingSession.url, bitrates: recordingSession.bitrates))

        print(">> Stopped recording", recordingSession.url.lastPathComponent)
        print()

        self.recordingSession = nil
    }

    class RecordingSession: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
        let url: URL
        var bitrates: Set<UInt32> = []

        private let myQueue = DispatchQueue(label: "AudioQueue")
        private var notificationObserver: NSObjectProtocol
        private let captureSession = AVCaptureSession()
//        private let audioOutput = AVCaptureAudioDataOutput()

        private var assetWriter: AVAssetWriter
        private var assetWriterInput: AVAssetWriterInput

        init(url: URL, captureDevice: AVCaptureDevice) throws {
            self.url = url

            // Setup Asset Writer:
            let assistant = AVOutputSettingsAssistant(preset: .preset1920x1080)!
            assistant.sourceAudioFormat = captureDevice.activeFormat.formatDescription

//            let outputSettings = assistant.audioSettings
            let outputSettings: [String : Any]? = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 160000,
            ]

            self.assetWriter = try AVAssetWriter(url: url, fileType: .m4a)

            // Set sourceFormatHint:
//            self.assetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings, sourceFormatHint: formatDescription)

            // Without sourceFormatHint:
            self.assetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings, sourceFormatHint: nil)
            assetWriterInput.expectsMediaDataInRealTime = true

            assetWriter.add(assetWriterInput)

            notificationObserver = NotificationCenter.default.addObserver(forName: .AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: nil) { notification in
                guard let port = notification.object as? AVCaptureInput.Port else { return }
                print("AVCaptureInputPortFormatDescriptionDidChange", port.formatDescription?.audioStreamBasicDescription?.mBitsPerChannel.description ?? "")
            }

            super.init()

            // Setup Audio capture
            let audioInput = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(audioInput)

            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.setSampleBufferDelegate(self, queue: myQueue)
            captureSession.addOutput(audioOutput)
        }

        func start() {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMClock.hostTimeClock.time)

            captureSession.startRunning()
        }

        func stop() async {
            assetWriterInput.markAsFinished()
            await assetWriter.finishWriting()
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard assetWriterInput.isReadyForMoreMediaData else {
                print("Not ready for data, dropping sample buffer")
                return
            }

//            print("Sample buffer data length", sampleBuffer.dataBuffer?.dataLength as Any)

            let sampleBufferFormat = sampleBuffer.formatDescription!.audioStreamBasicDescription!
            let inputPortFormat = connection.inputPorts.first!.formatDescription!.audioStreamBasicDescription!

            // Log all ASDB formats that we see
            bitrates.insert(sampleBufferFormat.mBitsPerChannel)

            let inconsistentFormat = sampleBufferFormat.mBitsPerChannel != inputPortFormat.mBitsPerChannel

            guard assetWriter.status == .writing else {
                if let error = assetWriter.error as? NSError {
                    let underlyingError = error.underlyingErrors.first as? NSError
                    if let underlyingError, underlyingError.code == kCMSampleBufferError_ArrayTooSmall {
                        print("AssetWriter has error kCMSampleBufferError_ArrayTooSmall", error.debugDescription)
                    } else {
                        print("AssetWriter has error", error.debugDescription)
                    }
                } else if inconsistentFormat {
                    print("INCONSISTENT FORMAT, but not yet started writing", sampleBufferFormat.mBitsPerChannel, inputPortFormat.mBitsPerChannel)
                } else {
                    print("Sample buffer, but not yet started writing")
                }
                return
            }

            if inconsistentFormat {
                print("INCONSISTENT FORMAT, attempt to append sample buffer anyway", sampleBufferFormat.mBitsPerChannel, inputPortFormat.mBitsPerChannel)
            } else {
//                print("Appending sample buffer", sampleBufferFormat)
            }
            assetWriterInput.append(sampleBuffer)
        }
    }
}
