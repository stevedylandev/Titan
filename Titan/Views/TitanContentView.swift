//
//  TitanContentView.swift
//  Titan
//

import SwiftUI

struct PreformattedBlockView: View {
    let text: String

    private let maxFontSize: CGFloat = 12
    private let charWidthRatio: CGFloat = 0.6 // Monospace char width ≈ 0.6 * font size
    private let lineHeightRatio: CGFloat = 1.2

    private var lines: [String] {
        text.components(separatedBy: .newlines)
    }

    private var maxLineLength: Int {
        lines.map { $0.count }.max() ?? 1
    }

    private func fontSize(for width: CGFloat) -> CGFloat {
        let ideal = width / (CGFloat(maxLineLength) * charWidthRatio)
        return min(ideal, maxFontSize)
    }

    private func blockHeight(fontSize: CGFloat) -> CGFloat {
        CGFloat(lines.count) * fontSize * lineHeightRatio
    }

    var body: some View {
        GeometryReader { geometry in
            let size = fontSize(for: geometry.size.width)

            Text(text)
                .font(.system(size: size, design: .monospaced))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(height: blockHeight(fontSize: estimatedFontSize))
    }

    // Estimate based on typical screen width (~350pt usable)
    private var estimatedFontSize: CGFloat {
        fontSize(for: 350)
    }
}

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
            PreformattedBlockView(text: text)
                .padding(.vertical, 4)
        }
    }
}
