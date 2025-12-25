//
//  SettingsView.swift
//  Titan
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeSettings: ThemeSettings
    @Environment(\.dismiss) private var dismiss

    @State private var homePageText: String = ""
    @State private var selectedAccentColor: Color = .blue
    @State private var selectedBackgroundColor: Color = Color(UIColor.systemBackground)
    @State private var selectedTextColor: Color = Color(UIColor.label)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Home Page URL", text: $homePageText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)
                } header: {
                    Text("Home Page")
                } footer: {
                    Text("The page that loads when you open the app or tap the Home button.")
                }

                Section {
                    ColorPicker("Accent Color", selection: $selectedAccentColor, supportsOpacity: false)
                    ColorPicker("Background Color", selection: $selectedBackgroundColor, supportsOpacity: false)
                    ColorPicker("Text Color", selection: $selectedTextColor, supportsOpacity: false)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Customize the colors of your browser interface.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        themeSettings.homePage = homePageText
                        themeSettings.setAllAccentColors(selectedAccentColor)
                        themeSettings.setBackgroundColor(selectedBackgroundColor)
                        themeSettings.setTextColor(selectedTextColor)
                        dismiss()
                    }
                }
            }
            .onAppear {
                homePageText = themeSettings.homePage
                selectedAccentColor = themeSettings.accentColor
                selectedBackgroundColor = themeSettings.backgroundColor
                selectedTextColor = themeSettings.textColor
            }
        }
    }
}

#Preview {
    SettingsView()
}
