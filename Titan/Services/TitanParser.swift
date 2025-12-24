//
//  TitanParser.swift
//  Titan
//

import Foundation

struct TitanParser {
    static func parse(_ content: String, baseURL: String) -> [TitanLine] {
        var lines: [TitanLine] = []
        var inPreformatted = false
        var preformattedLines: [String] = []
        var preformattedAlt = ""

        for line in content.components(separatedBy: .newlines) {
            if line.hasPrefix("```") {
                if inPreformatted {
                    // End of preformatted block - emit the collected lines
                    let blockContent = preformattedLines.joined(separator: "\n")
                    lines.append(.preformattedBlock(blockContent, alt: preformattedAlt))
                    preformattedLines = []
                    preformattedAlt = ""
                } else {
                    // Start of preformatted block
                    preformattedAlt = String(line.dropFirst(3))
                }
                inPreformatted.toggle()
                continue
            }

            if inPreformatted {
                preformattedLines.append(line)
                continue
            }

            if line.hasPrefix("###") {
                lines.append(.heading3(String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("##") {
                lines.append(.heading2(String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("#") {
                lines.append(.heading1(String(line.dropFirst(1)).trimmingCharacters(in: .whitespaces)))
            } else if line.hasPrefix("=>") {
                let linkContent = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                let (url, label) = parseLink(linkContent, baseURL: baseURL)
                lines.append(.link(url: url, label: label))
            } else if line.hasPrefix("* ") {
                lines.append(.listItem(String(line.dropFirst(2))))
            } else if line.hasPrefix(">") {
                lines.append(.quote(String(line.dropFirst(1))))
            } else {
                lines.append(.text(line))
            }
        }

        // Handle unclosed preformatted block
        if !preformattedLines.isEmpty {
            let blockContent = preformattedLines.joined(separator: "\n")
            lines.append(.preformattedBlock(blockContent, alt: preformattedAlt))
        }

        return lines
    }

    private static func parseLink(_ content: String, baseURL: String) -> (url: String, label: String) {
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        let rawURL = components.first ?? ""
        let label = components.count > 1 ? components.dropFirst().joined(separator: " ") : rawURL

        let resolvedURL: String
        if rawURL.contains("://") {
            resolvedURL = rawURL
        } else if let base = URL(string: baseURL),
                  let resolved = URL(string: rawURL, relativeTo: base) {
            resolvedURL = resolved.absoluteString
        } else {
            resolvedURL = rawURL
        }

        return (resolvedURL, label)
    }
}
