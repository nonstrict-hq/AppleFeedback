//
//  ContentView.swift
//  NestedFileImporter
//
//  Created by Mathijs Kadijk on 23/06/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showFileImporterForImages = false
    @State private var showFileImporterForMovies = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            Button("Import Image (Works)") {
                showFileImporterForImages = true
            }

            Button("Import Movie (Broken)") {
                showFileImporterForMovies = true
            }
            // This file importer is failing to show without any warning or notice
            .fileImporter(isPresented: $showFileImporterForMovies, allowedContentTypes: [.audiovisualContent]) { _ in
                // Not relevant
            }
        }
        // This file importer is working
        .fileImporter(isPresented: $showFileImporterForImages, allowedContentTypes: [.image]) { _ in
            // Not relevant
        }
    }
}

#Preview {
    ContentView()
}
