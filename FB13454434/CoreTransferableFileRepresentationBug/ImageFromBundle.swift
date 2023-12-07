//
//  ImageFromBundle.swift
//  CoreTransferableFileRepresentationBug
//
//  Created by Mathijs Kadijk on 07/12/2023.
//

import Foundation
import AppKit
import CoreTransferable

struct ImageFromBundle: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        // Bug: Dragging a Transferable with just a FileRepresentation won't work to drop it on Finder and most other apps.
        FileRepresentation(exportedContentType: .jpeg) { imageFromBundle in
            SentTransferredFile(imageFromBundle.url)
        }

        // Workaround: If a ProxyRepresentation is available with URL Finder and most other apps do work as expected.
        //ProxyRepresentation { imageFromBundle in imageFromBundle.url }
    }

    let url: URL

    var nsImage: NSImage {
        NSImage(contentsOf: url)!
    }
}
