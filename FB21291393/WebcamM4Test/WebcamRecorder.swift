//
//  WebcamRecorder.swift
//  WebcamM4Test
//
//  Created by Nonstrict on 2025-11-24.
//

import AVFoundation

struct WebcamRecorder {
    private let videoSampleBufferQueue = DispatchQueue(label: "WebcamRecorder.VideoSampleBufferQueue")
    
    private let assetWriter: AVAssetWriter
    private let videoInput: AVAssetWriterInput
    private let audioInput: AVAssetWriterInput?
    private let coordinator: Coordinator
    private let session: AVCaptureSession
    private let videoOutput: AVCaptureVideoDataOutput
    private let audioOutput: AVCaptureAudioDataOutput?

    init(url: URL, captureDevice: AVCaptureDevice, microphoneDevice: AVCaptureDevice?) async throws {

        // Create AVAssetWriter for a QuickTime movie file
        self.assetWriter = try AVAssetWriter(url: url, fileType: .mov)
        
        // Create capture session
        self.session = AVCaptureSession()
        
        // Add device input
        let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        guard session.canAddInput(deviceInput) else {
            throw RecordingError("Can't add camera input to capture session")
        }
        session.addInput(deviceInput)
        
        // Configure video output
        self.videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        guard session.canAddOutput(videoOutput) else {
            throw RecordingError("Can't add video output to capture session")
        }
        session.addOutput(videoOutput)
        
        // Get video dimensions from the active format
        let formatDescription = captureDevice.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        
        // Configure video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: dimensions.width,
            AVVideoHeightKey: dimensions.height,
            AVVideoColorPropertiesKey: [
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ],
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000, // 10 Mbps
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        // Create AVAssetWriter input
        self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true
        
        // Add input to asset writer
        guard assetWriter.canAdd(videoInput) else {
            throw RecordingError("Can't add input to asset writer")
        }
        assetWriter.add(videoInput)

        // Configure audio if microphone is provided
        if let microphoneDevice = microphoneDevice {
            // Add microphone input
            let audioDeviceInput = try AVCaptureDeviceInput(device: microphoneDevice)
            guard session.canAddInput(audioDeviceInput) else {
                throw RecordingError("Can't add microphone input to capture session")
            }
            session.addInput(audioDeviceInput)

            // Create audio output
            self.audioOutput = AVCaptureAudioDataOutput()
            guard session.canAddOutput(audioOutput!) else {
                throw RecordingError("Can't add audio output to capture session")
            }
            session.addOutput(audioOutput!)

            // Configure audio settings
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000
            ]

            // Create audio input for asset writer
            let audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioWriterInput.expectsMediaDataInRealTime = true
            self.audioInput = audioWriterInput

            guard assetWriter.canAdd(audioWriterInput) else {
                throw RecordingError("Can't add audio input to asset writer")
            }
            assetWriter.add(audioWriterInput)
        } else {
            self.audioOutput = nil
            self.audioInput = nil
        }

        // Create coordinator and set it as the sample buffer delegate
        self.coordinator = Coordinator(assetWriter: assetWriter, videoInput: videoInput)
        videoOutput.setSampleBufferDelegate(coordinator, queue: videoSampleBufferQueue)
        
        // Start writing
        guard assetWriter.startWriting() else {
            if let error = assetWriter.error {
                throw error
            }
            throw RecordingError("Couldn't start writing to AVAssetWriter")
        }
    }
    
    func start() async throws {
        // Start the capture session
        session.startRunning()
        
        // Start the AVAssetWriter session at source time .zero
        assetWriter.startSession(atSourceTime: .zero)
        coordinator.sessionStarted = true
        
    }
    
    func stop() async throws {
        // Stop the capture session
        session.stopRunning()
        
        // End the AVAssetWriter session
        assetWriter.endSession(atSourceTime: coordinator.lastSampleTime)
        
        // Finish writing
        videoInput.markAsFinished()
        await assetWriter.finishWriting()
        
        // Check for errors
        if let error = assetWriter.error {
            throw error
        }
    }
    
    private class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let assetWriter: AVAssetWriter
        let videoInput: AVAssetWriterInput
        var sessionStarted = false
        var firstSampleTime: CMTime = .zero
        var lastSampleTime: CMTime = .zero
        
        init(assetWriter: AVAssetWriter, videoInput: AVAssetWriterInput) {
            self.assetWriter = assetWriter
            self.videoInput = videoInput
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            // Return early if session hasn't started yet
            guard sessionStarted else { return }
            
            // Return early if the video input isn't ready
            guard videoInput.isReadyForMoreMediaData else { return }
            
            // Save the timestamp of the first sample
            if firstSampleTime == .zero {
                firstSampleTime = sampleBuffer.presentationTimeStamp
            }
            
            // Calculate relative time from the first sample
            let relativeTime = sampleBuffer.presentationTimeStamp - firstSampleTime
            lastSampleTime = relativeTime
            
            // Create a new sample buffer with adjusted timing
            let timing = CMSampleTimingInfo(
                duration: sampleBuffer.duration,
                presentationTimeStamp: relativeTime,
                decodeTimeStamp: sampleBuffer.decodeTimeStamp != .invalid ? sampleBuffer.decodeTimeStamp - firstSampleTime : .invalid
            )
            
            if let adjustedBuffer = try? CMSampleBuffer(copying: sampleBuffer, withNewTiming: [timing]) {
                videoInput.append(adjustedBuffer)
            }
        }
        
        func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            print(Date(), "WebcamRecorder. Dropped frame at \(sampleBuffer.presentationTimeStamp.seconds)")
        }
    }
}

