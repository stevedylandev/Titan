//
//  ThemeSettings.swift
//  Titan
//

import SwiftUI
import Combine

/// Observable object that manages theme customization settings.
/// This provides centralized accent color management that views can subscribe to.
class ThemeSettings: ObservableObject {
    /// The primary accent color used for interactive elements like links and buttons
    @Published var accentColor: Color = .blue

    /// The color used specifically for the loading progress bar
    @Published var progressBarColor: Color = .blue

    /// The color used for link text in Gemini content
    @Published var linkColor: Color = .blue

    /// The color used for media player controls (play button, slider, etc.)
    @Published var mediaAccentColor: Color = .blue

    /// The color used for toolbar buttons (navigation, menu, etc.)
    @Published var toolbarButtonColor: Color = .blue
}

// MARK: - Environment Key

private struct ThemeSettingsKey: EnvironmentKey {
    static let defaultValue = ThemeSettings()
}

extension EnvironmentValues {
    var themeSettings: ThemeSettings {
        get { self[ThemeSettingsKey.self] }
        set { self[ThemeSettingsKey.self] = newValue }
    }
}
