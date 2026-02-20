//
//  PrivacyPolicyWebView.swift
//  Veil
//
//  Created by Codex on 2/20/26.
//

import SwiftUI
import WebKit

struct PrivacyPolicyWebView: View {

    var body: some View {
        WebContentView(url: Self.privacyPolicyURL)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebContentView: UIViewRepresentable {

    final class Coordinator {
        var loadedURL: URL?
    }

    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        webView.load(URLRequest(url: url))
    }
}

private extension PrivacyPolicyWebView {
    static let privacyPolicyURL = URL(string: "https://example.com/veil/privacy-policy")!
}

#Preview {
    NavigationStack {
        PrivacyPolicyWebView()
    }
}
