//
//  ShortformBeGoneApp.swift
//  ShortformBeGone
//
//  Created by James Hartt on 15/11/2026.
//

import SwiftUI

@main
struct ShortformBeGoneApp: App {
    init() {
        #if DEBUG
        // UI tests pass `-resetSetupProgress YES` to start from a clean slate.
        if UserDefaults.standard.bool(forKey: "resetSetupProgress") {
            UserDefaults.standard.removeObject(forKey: "completedSetupSteps")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
