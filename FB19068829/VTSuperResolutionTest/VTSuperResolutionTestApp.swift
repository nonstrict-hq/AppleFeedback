//
//  VTSuperResolutionTestApp.swift
//  Untitled 1
//
//  Created by Nonstrict on 2025-07-23.
//

import SwiftUI
import CoreMedia
import VideoToolbox

@main
struct VTSuperResolutionTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

var processors = [VTFrameProcessor]()

struct ContentView: View {
    @State var errorMessage: String?
    @AppStorage("endPrevious") var endPrevious: Bool = false

    var body: some View {
        VStack {
            Text("App crashes when starting multiple VTFrameProcessor sessions when using VTSuperResolutionScalerConfiguration.")
                .font(.headline)

            Toggle("End previous sessions", isOn: $endPrevious)

            Button("Create session") {
                Task {
                    do {
                        errorMessage = nil
                        let id = processors.count
                        print(id, "Before createSession")
                        try await createSession(id: id, endPrevious: endPrevious)
                        print(id, "After createSession")
                        print()
                    } catch let error as NSError {
                        print("ERROR", error.debugDescription)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func createSession(id: Int, endPrevious: Bool) async throws {

        guard VTSuperResolutionScalerConfiguration.isSupported else {
            print("VTSuperResolutionScalerConfiguration is not supported.")
            return
        }

        let scaleFactor = 4

        guard VTSuperResolutionScalerConfiguration.supportedScaleFactors.contains(scaleFactor) else {
            print("Unsupported scale factor: \(scaleFactor).")
            return
        }

        let configuration: VTFrameProcessorConfiguration?

        let width = 1440
        let height = 1080


        print("SCALE FACTORS", VTSuperResolutionScalerConfiguration.supportedScaleFactors)
        print("LOWLATENCY", VTLowLatencySuperResolutionScalerConfiguration.supportedScaleFactors(frameWidth: 720, frameHeight: 540))

//        configurtion = VTLowLatencySuperResolutionScalerConfiguration(frameWidth: width, frameHeight: height, scaleFactor: scaleFactor)

        // Try to create configuration with original dimensions
        configuration = VTSuperResolutionScalerConfiguration(
            frameWidth: width,
            frameHeight: height,
            scaleFactor: scaleFactor,
            inputType: .video,
            usePrecomputedFlow: false,
            qualityPrioritization: .normal,
            revision: .revision1
        )
//        configuration = VTTemporalNoiseFilterConfiguration(frameWidth: width, frameHeight: height)

        guard let configuration else {
            print("Could not create configuration.")
            return
        }

        if let configuration = configuration as? VTSuperResolutionScalerConfiguration {
            switch configuration.configurationModelStatus {
            case .downloadRequired:
                print("Start downloading configuration model...")
                try await configuration.downloadConfigurationModel()
            case .downloading:
                print("Downloading configuration model...")
                return
            case .ready: break
            @unknown default: break
            }
        }

        print(id, "Existing processors: \(processors.count)")
        if endPrevious {
            for (ix, processor) in processors.enumerated() {
                print(id, "Ending session \(ix)...")
                processor.endSession()
                print(id, "Ended session \(ix).")
            }
        }


        do {
            let processor = VTFrameProcessor()
            processors.append(processor)
            print(id, "Starting session...")
            try processor.startSession(configuration: configuration)
            print(id, "Done starting session.")
        } catch let error as NSError {
            assertionFailure(error.debugDescription)
        }
    }
}
