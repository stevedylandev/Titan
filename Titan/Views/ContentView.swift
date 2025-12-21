//
//  ContentView.swift
//  Titan
//

import SwiftUI

struct ContentView: View {
    @State private var urlText = "gemini://geminiprotocol.net/"
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
            ScrollViewReader { proxy in
                ScrollView {
                    TitanContentView(content: responseText, baseURL: urlText, onLinkTap: { url in
                        navigateTo(url)
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .id("top")
                }
                .onChange(of: responseText) {
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .contentMargins(.top, 60, for: .scrollContent)
            }

            HStack(spacing: 20) {
                // Back button
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .padding(.leading, 6)
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
                            .foregroundColor(.orange)
                    }
                }
                .disabled(isLoading || urlText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .onAppear {
            navigateTo(urlText)
        }
        .ignoresSafeArea(edges: .top)
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

        let encoded = inputValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inputValue
        let urlWithQuery = pendingInputURL + "?" + encoded
        inputValue = ""

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

                if finalURL != urlText {
                    urlText = finalURL
                }

                switch response.statusCategory {
                case .success:
                    responseText = response.bodyText ?? "(empty response)"
                    if addToHistory {
                        history.append(finalURL)
                        historyIndex = history.count - 1
                    }
                case .input:
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

    private func fetchWithRedirects(urlString: String, redirectCount: Int) async throws -> (TitanResponse, String) {
        guard let url = URL(string: urlString),
              let host = url.host else {
            throw TitanError.invalidURL
        }

        let client = TitanClient(rejectUnauthorized: false)
        let port = url.port ?? 1965
        let response = try await client.connect(
            hostname: host,
            port: port,
            urlString: urlString
        )

        if response.statusCategory == .redirect {
            guard redirectCount < maxRedirects else {
                return (response, urlString)
            }

            let redirectTarget: String
            if response.meta.hasPrefix("gemini://") {
                redirectTarget = response.meta
            } else {
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
