//
//  ContentView.swift
//  Gemini
//
//  Created by Steve Simkins on 12/20/25.
//

// ContentView.swift (or your main view file)
import SwiftUI

// MARK: - Gemini Content Parser

enum GeminiLine {
    case text(String)
    case link(url: String, label: String)
    case heading1(String)
    case heading2(String)
    case heading3(String)
    case listItem(String)
    case quote(String)
    case preformattedToggle(alt: String)
    case preformatted(String)
}

struct GeminiParser {
    static func parse(_ content: String, baseURL: String) -> [GeminiLine] {
        var lines: [GeminiLine] = []
        var inPreformatted = false

        for line in content.components(separatedBy: .newlines) {
            if line.hasPrefix("```") {
                inPreformatted.toggle()
                let alt = String(line.dropFirst(3))
                lines.append(.preformattedToggle(alt: alt))
                continue
            }

            if inPreformatted {
                lines.append(.preformatted(line))
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

        return lines
    }

    private static func parseLink(_ content: String, baseURL: String) -> (url: String, label: String) {
        // Split on any whitespace (spaces, tabs, etc.)
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        let components = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        let rawURL = components.first ?? ""
        let label = components.count > 1 ? components.dropFirst().joined(separator: " ") : rawURL

        // Resolve relative URLs
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

// MARK: - Gemini Content View

struct GeminiContentView: View {
    let content: String
    let baseURL: String
    let onLinkTap: (String) -> Void

    init(content: String, baseURL: String = "", onLinkTap: @escaping (String) -> Void) {
        self.content = content
        self.baseURL = baseURL
        self.onLinkTap = onLinkTap
    }

    var body: some View {
        let lines = GeminiParser.parse(content, baseURL: baseURL)

        LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                lineView(for: line)
            }
        }
        .padding(8)
    }

    @ViewBuilder
    private func lineView(for line: GeminiLine) -> some View {
        switch line {
        case .text(let text):
            Text(text)
                .font(.system(.body, design: .monospaced))

        case .link(let url, let label):
            Button(action: { onLinkTap(url) }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.system(.caption, design: .monospaced))
                    Text(label)
                        .multilineTextAlignment(.leading)
                        .font(.system(.caption, design: .monospaced))
                }
            }
            .foregroundColor(.blue)

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

        case .preformattedToggle:
            EmptyView()

        case .preformatted(let text):
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var urlText = "gemini://gemini.circumlunar.space/"
    @State private var responseText = ""
    @State private var isLoading = false

    // Input prompt state
    @State private var showInputPrompt = false
    @State private var inputPromptText = ""
    @State private var inputValue = ""
    @State private var inputIsSensitive = false
    @State private var pendingInputURL = ""

    // Navigation history
    @State private var history: [String] = []
    @State private var historyIndex = -1

    private let maxRedirects = 5

    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                GeminiContentView(content: responseText, baseURL: urlText, onLinkTap: { url in
                    navigateTo(url)
                })
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                // Back button
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                }
                .disabled(!canGoBack || isLoading)

                // Forward button
                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                }
                .disabled(!canGoForward || isLoading)

                TextField("Enter Gemini URL", text: $urlText)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .onSubmit {
                        navigateTo(urlText)
                    }

                Button(action: { navigateTo(urlText) }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title2)
                    }
                }
                .disabled(isLoading || urlText.isEmpty)
            }
        }
        .padding()
        .alert("Input Required", isPresented: $showInputPrompt) {
            if inputIsSensitive {
                SecureField("Enter input", text: $inputValue)
            } else {
                TextField("Enter input", text: $inputValue)
            }
            Button("Cancel", role: .cancel) {
                inputValue = ""
            }
            Button("Submit") {
                submitInput()
            }
        } message: {
            Text(inputPromptText)
        }
    }

    private func submitInput() {
        guard !inputValue.isEmpty else { return }

        // URL-encode the input (spaces become %20, etc.)
        let encoded = inputValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inputValue

        // Append query string to URL
        let urlWithQuery = pendingInputURL + "?" + encoded
        inputValue = ""

        // Fetch with the input
        navigateTo(urlWithQuery)
    }

    // MARK: - Navigation History

    private var canGoBack: Bool {
        historyIndex > 0
    }

    private var canGoForward: Bool {
        historyIndex < history.count - 1
    }

    private func navigateTo(_ url: String) {
        // Remove forward history when navigating to new page
        if historyIndex < history.count - 1 {
            history = Array(history.prefix(historyIndex + 1))
        }

        urlText = url
        fetchContent(addToHistory: true)
    }

    private func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        urlText = history[historyIndex]
        fetchContent(addToHistory: false)
    }

    private func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        urlText = history[historyIndex]
        fetchContent(addToHistory: false)
    }

    private func fetchContent(addToHistory: Bool = true) {
        isLoading = true
        Task {
            do {
                let (response, finalURL) = try await fetchWithRedirects(urlString: urlText, redirectCount: 0)

                // Update URL bar if we followed redirects
                if finalURL != urlText {
                    urlText = finalURL
                }

                switch response.statusCategory {
                case .success:
                    responseText = response.bodyText ?? "(empty response)"
                    // Add to history on successful navigation
                    if addToHistory {
                        history.append(finalURL)
                        historyIndex = history.count - 1
                    }
                case .input:
                    // Show input prompt
                    pendingInputURL = finalURL
                    inputPromptText = response.meta
                    inputIsSensitive = response.statusCode == 11
                    showInputPrompt = true
                case .redirect:
                    responseText = "Too many redirects"
                case .temporaryFailure:
                    responseText = "Temporary failure (\(response.statusCode)): \(response.meta)"
                case .permanentFailure:
                    responseText = "Error (\(response.statusCode)): \(response.meta)"
                case .clientCertificate:
                    responseText = "Client certificate required: \(response.meta)"
                }
            } catch {
                responseText = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func fetchWithRedirects(urlString: String, redirectCount: Int) async throws -> (GeminiResponse, String) {
        guard let url = URL(string: urlString),
              let host = url.host else {
            throw GeminiError.invalidURL
        }

        let client = GeminiClient(rejectUnauthorized: false)
        let port = url.port ?? 1965
        let response = try await client.connect(
            hostname: host,
            port: port,
            urlString: urlString
        )

        // Handle redirects
        if response.statusCategory == .redirect {
            guard redirectCount < maxRedirects else {
                return (response, urlString)
            }

            // Resolve relative URLs against current URL
            let redirectTarget: String
            if response.meta.hasPrefix("gemini://") {
                redirectTarget = response.meta
            } else {
                // Relative URL - resolve against current
                if let baseURL = URL(string: urlString),
                   let resolved = URL(string: response.meta, relativeTo: baseURL) {
                    redirectTarget = resolved.absoluteString
                } else {
                    redirectTarget = response.meta
                }
            }

            print("↪️ Redirecting to: \(redirectTarget)")
            return try await fetchWithRedirects(urlString: redirectTarget, redirectCount: redirectCount + 1)
        }

        return (response, urlString)
    }
}

#Preview {
    ContentView()
}
