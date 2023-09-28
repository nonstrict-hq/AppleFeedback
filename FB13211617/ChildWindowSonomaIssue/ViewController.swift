//
//  ViewController.swift
//  ChildWindowSonomaIssue
//
//  Created by Tom Lokhorst on 28/09/2023.
//

import Cocoa
import OSLog

let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ViewController")

class ViewController: NSViewController {

    let panel = NSPanel(contentRect: .zero, styleMask: [.titled], backing: .buffered, defer: true)
//    let panel = NSPanel(contentRect: .zero, styleMask: [.utilityWindow,.titled], backing: .buffered, defer: true)

    override func viewDidLoad() {
        super.viewDidLoad()

        panel.setFrame(.init(x: 40, y: 40, width: 200, height: 300), display: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            logger.log("Adding Child")
            self.view.window!.addChildWindow(self.panel, ordered: .above)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            logger.log("Closing child")
            self.panel.orderOut(nil)
            logger.log("Closed child")
        }
    }

}
