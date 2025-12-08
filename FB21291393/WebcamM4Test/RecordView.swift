//
//  RecordView.swift
//  WebcamM4Test
//
//  Created by Nonstrict on 2025-11-17.
//

import SwiftUI
import AVFoundation
import ScreenCaptureKit
import OSLog

private let logger = Logger()

struct RecordView: View {
    @State private var viewModel: ViewModel = .init()
    @State private var presentError: Error?

    var body: some View {
        VStack {
            LayerView(layer: viewModel.previewLayer)
            Text(viewModel.selectedCamera?.localizedName ?? "No camera")

            Divider()

            HStack {
                Picker("Camera", selection: $viewModel.selectedCamera) {
                    ForEach(viewModel.availableCameras, id: \.uniqueID) { camera in
                        Text("\(camera.localizedName)").tag(Optional(camera))
                    }
                }

                Picker("Format", selection: $viewModel.selectedFormat) {
                    ForEach(viewModel.availableFormats, id: \.formatDescription) { format in
                        Text("\(format.debugDescription)").tag(Optional(format))
                    }
                }
                .task(id: viewModel.selectedFormat?.debugDescription ?? "") {
                    guard let selectedFormat = viewModel.selectedFormat else { return }
                    do {
                        try await Task.sleep(for: .seconds(0.1))
                        try viewModel.selectedCamera?.lockForConfiguration()
                        viewModel.selectedCamera?.activeFormat = selectedFormat
                        viewModel.selectedCamera?.unlockForConfiguration()
                    } catch is CancellationError {
                    } catch {
                        presentError = error
                    }
                }
            }

            HStack {
                Picker("Display", selection: $viewModel.selectedDisplay) {
                    ForEach(viewModel.availableDisplays, id: \.displayID) { display in
                        Text("\(display.localizedName ?? "Display #\(display.displayID)")").tag(Optional(display))
                    }
                }
                Picker("Resolution", selection: $viewModel.selectedResolution) {
                    ForEach(viewModel.availableResolutions, id: \.debugDescription) { resolution in
                        Text("\(Int(resolution.width))ｘ\(Int(resolution.height))").tag(resolution)
                    }
                }
            }
            
            HStack {
                Picker("Microphone", selection: $viewModel.selectedMicrophone) {
                    Text("None").tag(nil as AVCaptureDevice?)
                    ForEach(viewModel.availableMicrophones, id: \.uniqueID) { microphone in
                        Text("\(microphone.localizedName)").tag(Optional(microphone))
                    }
                }
            }

            if viewModel.isRecording {
                Button("Stop recording", systemImage: "stop.circle") {
                    Task {
                        do {
                            try await viewModel.stopRecording()
                        } catch {
                            presentError = error
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(.systemRed))
            } else {
                Button("Start recording", systemImage: "record.circle") {
                    Task {
                        do {
                            try await viewModel.startRecording()
                        } catch {
                            presentError = error
                        }
                    }
                }
            }

            HStack {
                TimelineView(.animation) { context in
                    if (Int(context.date.timeIntervalSince1970 * 1000) % 2) == 1 {
                        Color.red
                    } else {
                        Color.yellow
                    }
                }
                .frame(width: 10, height: 10)
                Text("Move mouse over display being recorded to trigger ScreenCaptureKit updates")
            }
            .opacity(viewModel.isRecording ? 1 : 0)
        }
        .padding()
        .errorAlert(error: $presentError)
        .task {
            do {
                try await viewModel.setup()
            } catch {
                presentError = error
            }
        }
    }
}

@Observable
class ViewModel: NSObject {
    let session = AVCaptureSession()

    let previewLayer: AVCaptureVideoPreviewLayer
    private(set) var isRecording = false

    var formatObservation: NSKeyValueObservation?

    var availableCameras: [AVCaptureDevice] = []
    var selectedCamera: AVCaptureDevice? {
        didSet {
            selectedCameraInput = try? selectedCamera.map { try AVCaptureDeviceInput(device: $0) }
            availableFormats = selectedCamera?.formats ?? []
            formatObservation = selectedCamera?.observe(\.activeFormat, options: [.initial, .new], changeHandler: { [weak self] _, change in
                self?.selectedFormat = change.newValue
            })
        }
    }
    private var selectedCameraInput: AVCaptureDeviceInput? {
        didSet {
            if let oldValue {
                session.removeInput(oldValue)
            }
            if let selectedCameraInput {
                session.addInput(selectedCameraInput)
            }
        }
    }

    var availableFormats: [AVCaptureDevice.Format] = []
    var selectedFormat: AVCaptureDevice.Format?

    var availableDisplays: [SCDisplay] = []
    var selectedDisplay: SCDisplay? {
        didSet {
            guard let selectedDisplay else { return }
            availableResolutions = [
                CGSize(width: Double(selectedDisplay.width) * 0.5, height: Double(selectedDisplay.height) * 0.5),
                CGSize(width: Double(selectedDisplay.width) * 0.75, height: Double(selectedDisplay.height) * 0.75),
                CGSize(width: Double(selectedDisplay.width), height: Double(selectedDisplay.height)),
            ]
            selectedResolution = availableResolutions[2]
        }
    }

    var availableResolutions: [CGSize] = [CGSize(width: 1920, height: 1080)]
    var selectedResolution: CGSize = CGSize(width: 1920, height: 1080)
    
    var availableMicrophones: [AVCaptureDevice] = []
    var selectedMicrophone: AVCaptureDevice?

    var screenRecorder: ScreenRecorder?
    var webcamRecorder: WebcamRecorder?

    override init() {
        previewLayer = .init(session: session)
        super.init()
    }

    func setup() async throws {

        // Cameras
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        self.availableCameras = discovery.devices
        self.selectedCamera = availableCameras.first { $0.localizedName.contains("MacBook") } ?? availableCameras.first
        
        // Microphones
        let micDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone, .external], mediaType: .audio, position: .unspecified)
        self.availableMicrophones = micDiscovery.devices
        self.selectedMicrophone = availableMicrophones.first { $0.localizedName.contains("MacBook") } ?? availableMicrophones.first

        // Displays
        let sharableContent = try await SCShareableContent.current
        let displays = sharableContent.displays
            .sorted(by: { $0.height > $1.height ? $0.width == $1.width ? $0.displayID < $1.displayID : $0.width > $1.width : $0.height > $1.height })

        self.availableDisplays = displays
        selectedDisplay = displays.first { $0.localizedName?.contains("Built-in") ?? false } ?? displays.first { $0.displayID == CGMainDisplayID() } ?? displays.first

        session.startRunning()
    }


    func startRecording() async throws {
        let webcamURL = FileManager.default.temporaryDirectory.appendingPathComponent("webcam.mov")
        let screenURL = FileManager.default.temporaryDirectory.appendingPathComponent("screen.mov")

        try? FileManager.default.removeItem(at: webcamURL)
        try? FileManager.default.removeItem(at: screenURL)

        guard let selectedDisplay else {
            throw RecordError("No display selected")
        }

        guard let selectedCamera else {
            throw RecordError("No camera selected")
        }

        if selectedDisplay.width < 1800 {
            throw RecordError("Display resolution should be at least 1800 width (More Space) to trigger the issue")
        }

        // Use WebcamRecorder
        webcamRecorder = try await WebcamRecorder(url: webcamURL, captureDevice: selectedCamera, microphoneDevice: selectedMicrophone)
        try await webcamRecorder?.start()

        // Use existing ScreenRecorder
        screenRecorder = try await ScreenRecorder(url: screenURL, displayID: selectedDisplay.displayID, cropRect: nil, mode: .h264_sRGB)
        try await screenRecorder?.start()

        isRecording = true
        logger.debug("Started recording!")
    }

    func stopRecording() async throws {
        try await webcamRecorder?.stop()
        try await screenRecorder?.stop()

        NSWorkspace.shared.open(FileManager.default.temporaryDirectory)

        isRecording = false
        logger.debug("Stopped recording!")
    }
}

struct RecordError: LocalizedError {
    var errorDescription: String?

    init(_ errorDescription: String) {
        self.errorDescription = errorDescription
    }
}

extension SCDisplay {
    var localizedName: String? {
        NSScreen.screens.first(where: { $0.displayID == displayID })?.localizedName
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else {
            fatalError("Can't find NSScreenNumber as CGDirectDisplayID in deviceDescription")
        }
        return screenNumber
    }
}
