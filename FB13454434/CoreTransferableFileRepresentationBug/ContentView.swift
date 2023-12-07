//
//  ContentView.swift
//  CoreTransferableFileRepresentationBug
//
//  Created by Mathijs Kadijk on 07/12/2023.
//

import SwiftUI

struct ContentView: View {
    let imageFromBundle = ImageFromBundle(url: Bundle.main.url(forResource: "daniel-tuttle-vNbmBnQRsSI-unsplash", withExtension: "jpg")!)

    var body: some View {
        VStack(spacing: 8) {
            // Draggable using my own type conforming to Transferable with only a FileRepresentation, you can't drop this on Finder and most other apps.
            Image(nsImage: imageFromBundle.nsImage)
                .draggable(imageFromBundle)
            
            Text("Drag the image above or below to Finder")

            // Draggable using a NSImage, you can't drop this on Finder and most other apps.
            Image(.steveJohnsonWpw8SHoBtSYUnsplash)
                .draggable(NSImage(resource: .steveJohnsonWpw8SHoBtSYUnsplash))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
