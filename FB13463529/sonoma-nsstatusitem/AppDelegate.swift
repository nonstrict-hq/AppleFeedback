//
//  AppDelegate.swift
//  sonoma-nsstatusitem
//
//  Created by Mathijs Kadijk on 12/12/2023.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!
    var statusBarItem: NSStatusItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let menu = NSMenu(title: "NSStatusItem")
        let menuItem = NSMenuItem(title: "Open Window", action: #selector(openWindow), keyEquivalent: "")
        menuItem.target = self
        menu.addItem(menuItem)

        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.title = "NSStatusItem"
        statusBarItem?.menu = menu

        window.orderOut(nil)
    }

    @objc
    func openWindow() {
        window.makeKeyAndOrderFront(nil)

        if #available(macOS 14.0, *) {
            NSApp.activate()

            // Workaround:
            // NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

