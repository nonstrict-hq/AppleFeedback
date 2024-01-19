//
//  AVCaptureScreenInput-Recording-example
//
//  Created by Tom Lokhorst on 2023-01-18.
//

import AVFoundation
import CoreGraphics
import AppKit

class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    var finishedContinuation: CheckedContinuation<Void, Never>?
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error { fatalError("\(error)") }
        finishedContinuation?.resume()
    }
}

let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("recording-\(Date()).mov")
let delegate = RecordingDelegate()
let captureSession = AVCaptureSession()
let fileOutput = AVCaptureMovieFileOutput()
let videoDevice = AVCaptureDevice.default(for: .video)!
let videoInput = try! AVCaptureDeviceInput(device: videoDevice)
let audioDevice = AVCaptureDevice.default(for: .audio)!
let audioInput = try! AVCaptureDeviceInput(device: audioDevice)

AVCaptureDevice.showSystemUserInterface(.videoEffects)
print("AUDIO:", audioDevice.localizedName, AVCaptureDevice.activeMicrophoneMode == .voiceIsolation ? "Voice Isolation enabled" : "no voice isolation")

print("Starting recording")
captureSession.addInput(videoInput)
captureSession.addInput(audioInput)
captureSession.addOutput(fileOutput)
captureSession.startRunning()
fileOutput.startRecording(to: url, recordingDelegate: delegate) // Note: potentially throws NSException

try await Task.sleep(for: .seconds(10)) // Record 20 seconds
// _ = readLine() // Record until enter is pressed

print("Ending recording")
await withCheckedContinuation { continuation in
    delegate.finishedContinuation = continuation
    fileOutput.stopRecording()
}

captureSession.stopRunning()
print("Recording ended, opening video")
NSWorkspace.shared.open(url)
