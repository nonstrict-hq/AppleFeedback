//
//  AppDelegate.swift
//
//  Created by Nonstrict on 08/02/2023.
//

import Cocoa
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

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Starting recording")
        Task {
            let videoDevice = AVCaptureDevice.default(for: .video)!
            let videoInput = try! AVCaptureDeviceInput(device: videoDevice)
            let audioDevice = AVCaptureDevice.default(for: .audio)!
            let audioInput = try! AVCaptureDeviceInput(device: audioDevice)

            print("AUDIO:", audioDevice.localizedName, AVCaptureDevice.activeMicrophoneMode == .voiceIsolation ? "Voice Isolation enabled" : "no voice isolation")

            captureSession.addInput(videoInput)
            captureSession.addInput(audioInput)
            captureSession.addOutput(fileOutput)
            captureSession.startRunning()
            
            fileOutput.startRecording(to: url, recordingDelegate: delegate) // Note: potentially throws NSException
        }
    }
    
    @IBAction func buttonPressed(_ sender: NSButton) {
        print("Ending recording")
        Task {
            await withCheckedContinuation { continuation in
                delegate.finishedContinuation = continuation
                fileOutput.stopRecording()
            }
            
            captureSession.stopRunning()
            print("Recording ended, opening video")
            NSWorkspace.shared.open(url)
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

