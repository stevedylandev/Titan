//
//  SettingsView.swift
//  Titan
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.themeSettings) private var themeSettings
    @Environment(\.dismiss) private var dismiss

    @State private var homePageText: String = ""

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
                        dismiss()
                    }
                }
            }
            .onAppear {
                homePageText = themeSettings.homePage
            }
        }
    }
}

#Preview {
    SettingsView()
}
