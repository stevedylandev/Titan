//
//  TabsListView.swift
//  Titan
//

import SwiftUI

struct TabsListView: View {
    @Bindable var tabManager: TabManager
    let onSelect: (Tab) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(tabManager.tabs) { tab in
                    Button {
                        onSelect(tab)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tab.title.isEmpty ? (tab.url.isEmpty ? "New Tab" : tab.url) : tab.title)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                if !tab.url.isEmpty && !tab.title.isEmpty {
                                    Text(tab.url)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)

                            Spacer()

                            if tab.id == tabManager.activeTabId {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let tab = tabManager.tabs[index]
                        tabManager.closeTab(id: tab.id)
                    }
                }
            }
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                if tabManager.tabs.count > 1 {
                    ToolbarItem(placement: .primaryAction) {
                        EditButton()
                    }
                }
            }
        }
    }
}
