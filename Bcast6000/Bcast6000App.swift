//
//  Bcast6000App.swift
//  Bcast6000
//
//  Created by Douglas Adams on 6/8/23.
//

import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@main
struct Bcast6000App: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  var appDelegate

  var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
