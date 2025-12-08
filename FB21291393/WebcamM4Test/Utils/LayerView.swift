//
//  LayerView.swift
//  WebcamM4Test
//
//  Created by Nonstrict on 2025-11-17.
//

import SwiftUI
import AppKit

struct LayerView: NSViewRepresentable {
    let layer: CALayer

    func makeNSView(context: Context) -> some NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer = layer
        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {
        if nsView.layer != layer {
            nsView.layer = layer
        }
    }
}
