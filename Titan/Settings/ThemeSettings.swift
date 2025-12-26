//
//  ThemeSettings.swift
//  Titan
//

import SwiftUI
import Combine

/// Available font design options for the browser
enum FontDesignOption: String, CaseIterable, Identifiable {
    case system = "System"
    case monospaced = "Monospaced"
    case serif = "Serif"
    case rounded = "Rounded"

    var id: String { rawValue }

    var fontDesign: Font.Design {
        switch self {
        case .system: return .default
        case .monospaced: return .monospaced
        case .serif: return .serif
        case .rounded: return .rounded
        }
    }
}

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

    /// The background color for the main content area
    @Published var backgroundColor: Color = Color(UIColor.systemBackground)

    /// The text color for content
    @Published var textColor: Color = Color(UIColor.label)

    /// The font design for content
    @Published var fontDesign: FontDesignOption = .monospaced

    /// The home page URL that the browser navigates to on launch and when pressing Home
    @AppStorage("homePage") var homePage: String = "gemini://geminiprotocol.net/"

    /// Key for persisting accent color hex value
    private static let accentColorKey = "accentColorHex"
    private static let backgroundColorKey = "backgroundColorHex"
    private static let textColorKey = "textColorHex"
    private static let fontDesignKey = "fontDesign"

    init() {
        if let hex = UserDefaults.standard.string(forKey: Self.accentColorKey),
           let color = Color(hex: hex) {
            setAllAccentColors(color)
        }
        if let hex = UserDefaults.standard.string(forKey: Self.backgroundColorKey),
           let color = Color(hex: hex) {
            backgroundColor = color
        }
        if let hex = UserDefaults.standard.string(forKey: Self.textColorKey),
           let color = Color(hex: hex) {
            textColor = color
        }
        if let fontRaw = UserDefaults.standard.string(forKey: Self.fontDesignKey),
           let font = FontDesignOption(rawValue: fontRaw) {
            fontDesign = font
        }
    }

    /// Sets all accent colors to the given color and persists the choice
    func setAllAccentColors(_ color: Color) {
        accentColor = color
        progressBarColor = color
        linkColor = color
        mediaAccentColor = color
        toolbarButtonColor = color

        if let hex = color.toHex() {
            UserDefaults.standard.set(hex, forKey: Self.accentColorKey)
        }
    }

    /// Sets the background color and persists the choice
    func setBackgroundColor(_ color: Color) {
        backgroundColor = color
        if let hex = color.toHex() {
            UserDefaults.standard.set(hex, forKey: Self.backgroundColorKey)
        }
    }

    /// Sets the text color and persists the choice
    func setTextColor(_ color: Color) {
        textColor = color
        if let hex = color.toHex() {
            UserDefaults.standard.set(hex, forKey: Self.textColorKey)
        }
    }

    /// Sets the font design and persists the choice
    func setFontDesign(_ font: FontDesignOption) {
        fontDesign = font
        UserDefaults.standard.set(font.rawValue, forKey: Self.fontDesignKey)
    }
}

// MARK: - Color Hex Conversion

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0

        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
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
