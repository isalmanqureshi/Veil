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
        WebContentView(html: Self.privacyPolicyHTML)
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebContentView: UIViewRepresentable {

    final class Coordinator {
        var loadedHTML: String?
    }

    let html: String

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
        guard context.coordinator.loadedHTML != html else { return }
        context.coordinator.loadedHTML = html
        webView.loadHTMLString(html, baseURL: nil)
    }
}

private extension PrivacyPolicyWebView {
    static let privacyPolicyHTML = """
    <!doctype html>
    <html>
      <head>
        <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\" />
        <style>
          :root { color-scheme: light dark; }
          body {
            font-family: -apple-system, BlinkMacSystemFont, \"SF Pro Text\", sans-serif;
            margin: 0;
            padding: 20px 16px 28px;
            line-height: 1.5;
          }
          h1, h2 { line-height: 1.25; margin-top: 0; }
          h2 { margin-top: 20px; }
          p, li { font-size: 16px; }
          ul { padding-left: 20px; }
        </style>
      </head>
      <body>
        <h1>Veil Privacy Policy</h1>
        <p>Veil is built to minimize what we collect and maximize what stays private to you.</p>

        <h2>What Veil does not collect</h2>
        <ul>
          <li>No phone numbers required for account creation.</li>
          <li>No advertising identifiers.</li>
          <li>No third-party tracking scripts.</li>
        </ul>

        <h2>What data stays on your device</h2>
        <ul>
          <li>Your recovery key material and cryptographic secrets remain local.</li>
          <li>Your onboarding seed is used to initialize identity keys on-device.</li>
          <li>Message history in this prototype is mock/local repository data.</li>
        </ul>

        <h2>Security posture</h2>
        <p>Veil is designed around secure defaults, explicit consent, and minimal metadata exposure. Trust warnings are surfaced in-app when potentially sensitive events occur.</p>

        <h2>Contact</h2>
        <p>If this policy changes, updates will appear here inside the app.</p>
      </body>
    </html>
    """
}

#Preview {
    NavigationStack {
        PrivacyPolicyWebView()
    }
}
