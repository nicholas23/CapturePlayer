//
//  CapturePlayerApp.swift
//  CapturePlayer
//
//  Created by Chaoshen Hsu on 2025/8/3.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}

@main
struct CapturePlayerApp: App {
    @NSApplicationDelegateAdaptor((AppDelegate).self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.defaultSize(width: 1920, height: 1080)
    }
}


