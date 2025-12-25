//
//  ContentView.swift
//  Titan
//

import SwiftUI

struct IndeterminateProgressBar: View {
    let color: Color

    @State private var animationOffset: CGFloat = -1.0

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(color)
                .frame(width: geometry.size.width * 0.3)
                .offset(x: animationOffset * geometry.size.width)
        }
        .frame(height: 3)
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animationOffset = 1.0
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var themeSettings: ThemeSettings
    @State private var urlText = ""
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

    // Media preview state
    @State private var showMediaPreview = false
    @State private var mediaContent: MediaContent?

    // Current fetch task (for cancellation)
    @State private var currentFetchTask: Task<Void, Never>?

    // Bookmarks
    @State private var bookmarkManager = BookmarkManager()
    @State private var showBookmarks = false

    // History
    @State private var historyManager = HistoryManager()
    @State private var showHistory = false

    // Settings
    @State private var showSettings = false

    // Tabs
    @State private var tabManager = TabManager()
    @State private var showTabs = false

    // URL input focus state
    @FocusState private var isURLFocused: Bool

    private let maxRedirects = 5

    var body: some View {
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
            .contentMargins(.top, 20, for: .scrollContent)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    if isLoading {
                        IndeterminateProgressBar(color: themeSettings.progressBarColor)
                    } else {
                        Color.clear
                            .frame(height: 3)
                    }

                    GlassEffectContainer {
                        HStack(spacing: 12) {
                            // Navigation buttons in a single pill
                            if !isURLFocused {
                                HStack(spacing: 0) {
                                    Button(action: goBack) {
                                        Image(systemName: "chevron.left")
                                            .font(.title2)
                                            .foregroundStyle(canGoBack && !isLoading ? themeSettings.toolbarButtonColor : themeSettings.toolbarButtonColor.opacity(0.3))
                                            .frame(width: 44, height: 44)
                                    }
                                    .disabled(!canGoBack || isLoading)

                                    Divider()
                                        .frame(height: 24)

                                    Button(action: goForward) {
                                        Image(systemName: "chevron.right")
                                            .font(.title2)
                                            .foregroundStyle(canGoForward && !isLoading ? themeSettings.toolbarButtonColor : themeSettings.toolbarButtonColor.opacity(0.3))
                                            .frame(width: 44, height: 44)
                                    }
                                    .disabled(!canGoForward || isLoading)
                                }
                                .glassEffect(.regular.interactive())
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }

                            TextField("Enter Gemini URL", text: $urlText)
                                .focused($isURLFocused)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.URL)
                                .submitLabel(.go)
                                .onSubmit {
                                    isURLFocused = false
                                    navigateTo(urlText)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .glassEffect(.regular, in: .capsule)

                            if isURLFocused {
                                Button {
                                    isURLFocused = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(themeSettings.toolbarButtonColor)
                                        .frame(width: 44, height: 44)
                                }
                                .glassEffect(.regular.interactive())
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            } else {
                                Menu {
                                    Button {
                                        showTabs = true
                                    } label: {
                                        Label("Tabs (\(tabManager.tabs.count))", systemImage: "square.on.square")
                                    }

                                    Button {
                                        saveCurrentTabState()
                                        tabManager.createTab(url: themeSettings.homePage)
                                        loadActiveTabState()
                                        navigateTo(themeSettings.homePage)
                                    } label: {
                                        Label("New Tab", systemImage: "plus")
                                    }

                                    Button {
                                        tabManager.closeTab(id: tabManager.activeTabId)
                                        loadActiveTabState()
                                    } label: {
                                        Label("Close Tab", systemImage: "xmark")
                                    }
                                    .disabled(tabManager.tabs.count <= 1)

                                    Divider()

                                    Button {
                                        showSettings = true
                                    } label: {
                                        Label("Settings", systemImage: "gear")
                                    }

                                    Divider()

                                    Button {
                                        showBookmarks = true
                                    } label: {
                                        Label("Bookmarks", systemImage: "book")
                                    }

                                    Button {
                                        addCurrentPageToBookmarks()
                                    } label: {
                                        if bookmarkManager.isBookmarked(url: urlText) {
                                            Label("Bookmarked", systemImage: "bookmark.fill")
                                        } else {
                                            Label("Add Bookmark", systemImage: "bookmark")
                                        }
                                    }
                                    .disabled(urlText.isEmpty || bookmarkManager.isBookmarked(url: urlText))

                                    Button {
                                        showHistory = true
                                    } label: {
                                        Label("History", systemImage: "clock")
                                    }

                                    Divider()

                                    Button {
                                        navigateTo(themeSettings.homePage)
                                    } label: {
                                        Label("Home", systemImage: "house")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.title2)
                                        .foregroundStyle(themeSettings.toolbarButtonColor)
                                        .frame(width: 44, height: 44)
                                }
                                .glassEffect(.regular.interactive())
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: isURLFocused)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            loadActiveTabState()
            // If this is a fresh tab with no content, navigate to home
            if urlText.isEmpty {
                navigateTo(themeSettings.homePage)
            } else if responseText.isEmpty && !urlText.isEmpty {
                // Tab has URL but no content (restored from persistence)
                navigateTo(urlText)
            }
        }
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
        .fullScreenCover(isPresented: $showMediaPreview) {
            if let media = mediaContent {
                MediaPreviewView(media: media) {
                    showMediaPreview = false
                    mediaContent = nil
                }
            }
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksListView(bookmarkManager: bookmarkManager) { bookmark in
                showBookmarks = false
                navigateTo(bookmark.url)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryListView(historyManager: historyManager) { item in
                showHistory = false
                navigateTo(item.url)
            }
        }
        .sheet(isPresented: $showTabs) {
            TabsListView(tabManager: tabManager) { tab in
                showTabs = false
                saveCurrentTabState()
                tabManager.switchTo(id: tab.id)
                loadActiveTabState()
            }
        }
    }

    // MARK: - Tab State Management

    private func saveCurrentTabState() {
        let title = extractPageTitle() ?? urlText
        tabManager.updateActiveTab(
            url: urlText,
            title: title,
            responseText: responseText,
            history: history,
            historyIndex: historyIndex
        )
    }

    private func loadActiveTabState() {
        guard let tab = tabManager.activeTab else { return }
        urlText = tab.url
        responseText = tab.responseText
        history = tab.history
        historyIndex = tab.historyIndex
    }

    private func submitInput() {
        guard !inputValue.isEmpty else { return }

        let encoded = inputValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? inputValue
        let urlWithQuery = pendingInputURL + "?" + encoded
        inputValue = ""

        navigateTo(urlWithQuery)
    }

    // MARK: - Bookmarks

    private func addCurrentPageToBookmarks() {
        guard !urlText.isEmpty else { return }
        let title = extractPageTitle() ?? urlText
        bookmarkManager.addBookmark(url: urlText, title: title)
    }

    private func extractPageTitle() -> String? {
        let lines = TitanParser.parse(responseText, baseURL: urlText)
        for line in lines {
            switch line {
            case .heading1(let text), .heading2(let text), .heading3(let text):
                return text
            default:
                continue
            }
        }
        return nil
    }

    // MARK: - Navigation History

    private var canGoBack: Bool {
        historyIndex > 0
    }

    private var canGoForward: Bool {
        historyIndex < history.count - 1
    }

    private func navigateTo(_ url: String) {
        // Check if this is an external URL (http, https, mailto)
        if let urlObj = URL(string: url) {
            let scheme = urlObj.scheme?.lowercased() ?? ""
            if scheme == "http" || scheme == "https" || scheme == "mailto" {
                UIApplication.shared.open(urlObj)
                return
            }
        }

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
        // Cancel any pending request before starting a new one
        currentFetchTask?.cancel()

        isLoading = true
        currentFetchTask = Task {
            do {
                let (response, finalURL) = try await fetchWithRedirects(urlString: urlText, redirectCount: 0)

                // Check if task was cancelled during fetch
                if Task.isCancelled { return }

                if finalURL != urlText {
                    urlText = finalURL
                }

                switch response.statusCategory {
                case .success:
                    let mimeType = response.meta

                    if MediaType.isMediaContent(mimeType) {
                        // Handle media content (images, audio)
                        if let body = response.body {
                            mediaContent = MediaContent(
                                data: body,
                                mimeType: mimeType,
                                sourceURL: finalURL
                            )
                            showMediaPreview = true
                        } else {
                            responseText = "(empty media response)"
                        }
                    } else {
                        // Handle text content (text/gemini, text/plain, etc.)
                        responseText = response.bodyText ?? "(empty response)"
                        if addToHistory {
                            history.append(finalURL)
                            historyIndex = history.count - 1

                            // Add to persistent history
                            let title = extractPageTitle() ?? finalURL
                            historyManager.addToHistory(url: finalURL, title: title)
                        }
                        // Save tab state
                        saveCurrentTabState()
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
                isLoading = false
            } catch is CancellationError {
                // Task was cancelled, don't update UI
                return
            } catch let error as TitanError where error == .cancelled {
                // Request was cancelled, don't update UI
                return
            } catch {
                responseText = "Error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    private func fetchWithRedirects(urlString: String, redirectCount: Int) async throws -> (TitanResponse, String) {
        // Check for cancellation before starting
        try Task.checkCancellation()

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

        // Check for cancellation after fetch
        try Task.checkCancellation()

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
