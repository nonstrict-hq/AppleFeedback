//
//  ContentView.swift
//  Untitled 1
//
//  Created by Nonstrict on 2025-11-17.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var cameraAccess = false
    @State private var screenRecording = false
    var body: some View {
        if !cameraAccess || !screenRecording {
            VStack {
                Text("Allow camera and screen access in Settings")

                Button("Camera Access", systemImage: "camera") {
                    AVCaptureDevice.requestAccess(for: .video) { access in
                        self.cameraAccess = access
                    }
                }.disabled(cameraAccess)

                Button("Screen Recording", systemImage: "display") {
                    CGRequestScreenCaptureAccess()
                }.disabled(screenRecording)
            }
            .onAppear {
                cameraAccess = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
                screenRecording = CGPreflightScreenCaptureAccess()
            }
        } else {
            RecordView()
        }
    }
}

#Preview {
    ContentView()
}
