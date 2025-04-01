//
//  StudioDisplayCameraTestApp.swift
//
//  Created by Nonstrict on 2025-03-28.
//

import SwiftUI
import AVFoundation

@main
struct StudioDisplayCameraTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .external], mediaType: .video, position: .unspecified)

struct ContentView: View {
    @State var iteration = 0
    @State var displayError: Error?

    var body: some View {
        VStack {
            Text("Available Devices: \(discovery.devices.map(\.localizedName))")
                .padding(.bottom)

            Button("Start looping") {
                guard let device = discovery.devices.first(where: { $0.localizedName == "Studio Display Camera" }) else {
                    fatalError("Example project requires a Studio Display Camera to run")
                }

                Task {
                    iteration = 0
                    displayError = nil

                    while displayError == nil {
                        do {
                            iteration += 1
                            try await Task.sleep(for: .seconds(1))
                            let recorder = Recorder(device: device, iteration: iteration)
                            try await recorder.start()
                            try await Task.sleep(for: .seconds(1))
                        } catch {
                            displayError = error
                        }
                    }
                }
            }

            Text("Iteration: \(iteration)")

            if let displayError = displayError as NSError? {
                Text("❌ \(displayError.debugDescription)")
            }
        }
        .padding()
    }
}


class Recorder: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let device: AVCaptureDevice
    let iteration: Int

    init(device: AVCaptureDevice, iteration: Int) {
        self.device = device
        self.iteration = iteration
    }

    private let queue = DispatchQueue(label: "videoQueue")
    var onSampleBuffer: ((CMSampleBuffer) -> Void)?

    func start() async throws {

        let input = try AVCaptureDeviceInput(device: device)
        let output = AVCaptureVideoDataOutput()

        output.setSampleBufferDelegate(self, queue: queue)

        let session = AVCaptureSession()
        session.addInput(input)
        session.addOutput(output)

        let sampleBuffer = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CMSampleBuffer, Error>) in
            let timeout = Task {
                try await Task.sleep(for: .seconds(3))
                print("TIMEOUT")
                // This commented out workaround appears to work!
//                if device.activeFormat.isCenterStageSupported && !device.isCenterStageActive {
//                    print("Toggling center stage")
//                    AVCaptureDevice.centerStageControlMode = .cooperative
//                    AVCaptureDevice.isCenterStageEnabled.toggle()
//                    AVCaptureDevice.isCenterStageEnabled.toggle()
//                    try await Task.sleep(for: .seconds(3))
//                } else {
//                    print("Nothing to do")
//                }
                print("THROWING")
                continuation.resume(throwing: TimeoutError(errorDescription: "No sample buffer received within 3 seconds"))
            }

            onSampleBuffer = { sampleBuffer in
                timeout.cancel()
                continuation.resume(returning: sampleBuffer)
            }

            session.startRunning()
        }
        print(iteration, "Sample buffer: \(sampleBuffer.presentationTimeStamp)")
        session.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onSampleBuffer?(sampleBuffer)
        onSampleBuffer = nil
    }
}

struct TimeoutError: LocalizedError {
    var errorDescription: String?
}
