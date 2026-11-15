//
//  ContentView.swift
//  ShortformBeGone
//

import SwiftUI

struct ContentView: View {
    enum Tab: Hashable { case status, rules, setup }

    @State private var tab: Tab = .status
    @State private var filter = FilterStatusModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $tab) {
            StatusView(filter: filter, showSetup: { tab = .setup })
                .tabItem { Label("Status", systemImage: "checkmark.shield") }
                .tag(Tab.status)
            RulesView(filter: filter)
                .tabItem { Label("Rules", systemImage: "list.bullet.rectangle") }
                .tag(Tab.rules)
            SetupView()
                .tabItem { Label("Setup", systemImage: "wrench.and.screwdriver") }
                .tag(Tab.setup)
        }
        .task { await filter.refresh() }
        #if DEBUG
        .task {
            // `-openURL <address>` opens it in Safari, to test the filter from the Mac.
            if let text = UserDefaults.standard.string(forKey: "openURL"), let url = URL(string: text) {
                await UIApplication.shared.open(url)
            }
        }
        #endif
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await filter.refresh() }
            }
        }
    }
}

#Preview {
    ContentView()
}
