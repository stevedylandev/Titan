//
//  TitanApp.swift
//  Titan
//
//  Created by Steve Simkins on 12/20/25.
//

import SwiftUI

@main
struct TitanApp: App {
    @StateObject private var themeSettings = ThemeSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.themeSettings, themeSettings)
                .environmentObject(themeSettings)
                .preferredColorScheme(themeSettings.appearanceMode.colorScheme)
        }
    }
}
