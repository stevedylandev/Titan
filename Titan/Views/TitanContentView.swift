//
//  TitanContentView.swift
//  Titan
//

import SwiftUI

struct PreformattedBlockView: View {
    let text: String
    let baseFontSize: CGFloat

    private var maxFontSize: CGFloat { baseFontSize * 0.75 }
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

    @EnvironmentObject private var themeSettings: ThemeSettings

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

    private var fontSize: CGFloat { themeSettings.baseFontSize }
    private var heading1Size: CGFloat { fontSize * 1.75 }
    private var heading2Size: CGFloat { fontSize * 1.5 }
    private var heading3Size: CGFloat { fontSize * 1.25 }

    @ViewBuilder
    private func lineView(for line: TitanLine) -> some View {
        switch line {
        case .text(let text):
            Text(text)
                .font(.system(size: fontSize, design: themeSettings.fontDesign.fontDesign))
                .foregroundColor(themeSettings.textColor)

        case .link(let url, let label):
            Button(action: { onLinkTap(url) }) {
                HStack(alignment:.top, spacing: 4) {
                    Text(label)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: fontSize, design: themeSettings.fontDesign.fontDesign))
                }
            }
            .foregroundColor(themeSettings.linkColor)
            .padding(.vertical, 6)

        case .heading1(let text):
            Text(text)
                .font(.system(size: heading1Size, design: themeSettings.fontDesign.fontDesign))
                .fontWeight(.bold)
                .foregroundColor(themeSettings.textColor)
                .padding(.top, 8)

        case .heading2(let text):
            Text(text)
                .font(.system(size: heading2Size, design: themeSettings.fontDesign.fontDesign))
                .fontWeight(.semibold)
                .foregroundColor(themeSettings.textColor)
                .padding(.top, 6)

        case .heading3(let text):
            Text(text)
                .font(.system(size: heading3Size, design: themeSettings.fontDesign.fontDesign))
                .fontWeight(.medium)
                .foregroundColor(themeSettings.textColor)
                .padding(.top, 4)

        case .listItem(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("\u{2022}")
                Text(text)
            }
            .font(.system(size: fontSize, design: themeSettings.fontDesign.fontDesign))
            .foregroundColor(themeSettings.textColor)

        case .quote(let text):
            Text(text)
                .font(.system(size: fontSize, design: themeSettings.fontDesign.fontDesign))
                .italic()
                .foregroundColor(.secondary)
                .padding(.leading, 12)

        case .preformattedBlock(let text, _):
            PreformattedBlockView(text: text, baseFontSize: fontSize)
                .padding(.vertical, 4)
        }
    }
}
