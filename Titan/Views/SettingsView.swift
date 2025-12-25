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
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Changes the color of links, buttons, and other interactive elements.")
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
                        themeSettings.setAllColors(selectedAccentColor)
                        dismiss()
                    }
                }
            }
            .onAppear {
                homePageText = themeSettings.homePage
                selectedAccentColor = themeSettings.accentColor
            }
        }
    }
}

#Preview {
    SettingsView()
}
