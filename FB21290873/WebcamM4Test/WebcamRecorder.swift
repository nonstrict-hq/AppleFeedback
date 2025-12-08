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
    private let coordinator: Coordinator
    private let session: AVCaptureSession
    private let videoOutput: AVCaptureVideoDataOutput
    
    init(url: URL, captureDevice: AVCaptureDevice) async throws {
        
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
        
        // Create coordinator and set it as the sample buffer delegate
        self.coordinator = Coordinator(videoInput: videoInput)
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
    }
    
    private class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let videoInput: AVAssetWriterInput
        var sessionStarted = false
        var firstSampleTime: CMTime = .zero
        var lastSampleTime: CMTime = .zero
        
        init(videoInput: AVAssetWriterInput) {
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

