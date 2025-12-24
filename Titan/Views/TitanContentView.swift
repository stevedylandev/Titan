//
//  TitanContentView.swift
//  Titan
//

import SwiftUI

struct TitanContentView: View {
    let content: String
    let baseURL: String
    let onLinkTap: (String) -> Void

    init(content: String, baseURL: String = "", onLinkTap: @escaping (String) -> Void) {
        self.content = content
        self.baseURL = baseURL
        self.onLinkTap = onLinkTap
    }

    var body: some View {
        let lines = TitanParser.parse(content, baseURL: baseURL)

        LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                lineView(for: line)
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private func lineView(for line: TitanLine) -> some View {
        switch line {
        case .text(let text):
            Text(text)
                .font(.system(.body, design: .monospaced))

        case .link(let url, let label):
            Button(action: { onLinkTap(url) }) {
                HStack(alignment:.top, spacing: 4) {
                    Text(label)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 14, design: .monospaced))
                }
            }
            .foregroundColor(.orange)
            .padding(.vertical, 6)

        case .heading1(let text):
            Text(text)
                .font(.system(.title, design: .monospaced))
                .fontWeight(.bold)
                .padding(.top, 8)

        case .heading2(let text):
            Text(text)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.semibold)
                .padding(.top, 6)

        case .heading3(let text):
            Text(text)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.medium)
                .padding(.top, 4)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("\u{2022}")
                Text(text)
            }
            .font(.system(.body, design: .monospaced))

        case .quote(let text):
            Text(text)
                .font(.system(.body, design: .monospaced))
                .italic()
                .foregroundColor(.secondary)
                .padding(.leading, 12)

        case .preformattedBlock(let text, _):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, 4)
        }
    }
}
