import AppKit
import SwiftUI
import WebKit

struct WebPreviewRenderer: NSViewRepresentable {
  let snapshot: MarkdownSnapshot
  let scrollTargetSlug: String?

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
    configuration.websiteDataStore = .nonPersistent()

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = context.coordinator
    context.coordinator.webView = webView
    context.coordinator.loadShell()
    return webView
  }

  func updateNSView(_ webView: WKWebView, context: Context) {
    context.coordinator.webView = webView
    context.coordinator.render(snapshot)

    if let scrollTargetSlug {
      context.coordinator.scrollToHeading(slug: scrollTargetSlug)
    }
  }

  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate {
    weak var webView: WKWebView?
    private var shellLoaded = false
    private var pendingSnapshot: MarkdownSnapshot?
    private var pendingScrollTargetSlug: String?
    private var lastRenderedSnapshot: MarkdownSnapshot?

    func loadShell() {
      do {
        let shellURL = try PreviewHTMLBuilder.shellURL()
        webView?.loadFileURL(
          shellURL,
          allowingReadAccessTo: PreviewHTMLBuilder.resourceReadAccessURL(forShellAt: shellURL)
        )
      } catch {
        let message = "Unable to load markdown preview resources."
        webView?.loadHTMLString("<!doctype html><meta charset=\"utf-8\"><p>\(message)</p>", baseURL: nil)
      }
    }

    func render(_ snapshot: MarkdownSnapshot) {
      guard shellLoaded else {
        pendingSnapshot = snapshot
        return
      }

      guard Self.shouldRender(snapshot, after: lastRenderedSnapshot) else {
        return
      }

      do {
        webView?.evaluateJavaScript(try Self.renderScript(for: snapshot))
        lastRenderedSnapshot = snapshot
      } catch {
        assertionFailure("Failed to encode markdown preview payload: \(error)")
      }
    }

    func scrollToHeading(slug: String) {
      guard shellLoaded else {
        pendingScrollTargetSlug = slug
        return
      }

      do {
        webView?.evaluateJavaScript(try Self.scrollScript(forSlug: slug))
      } catch {
        assertionFailure("Failed to encode markdown preview scroll target: \(error)")
      }
    }

    nonisolated static func renderScript(for snapshot: MarkdownSnapshot) throws -> String {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys]
      let markdownData = try encoder.encode(snapshot.text)
      let headingData = try encoder.encode(snapshot.headings.map {
        HeadingPayload(slug: $0.slug, level: $0.level.rawValue)
      })
      let imageData = try encoder.encode(snapshot.localImages)
      let markdown = String(decoding: markdownData, as: UTF8.self)
      let headings = String(decoding: headingData, as: UTF8.self)
      let images = String(decoding: imageData, as: UTF8.self)
      return "window.MarkdownDevPreview.render(\(markdown), \(headings), \(images));"
    }

    nonisolated static func shouldRender(_ snapshot: MarkdownSnapshot, after previous: MarkdownSnapshot?) -> Bool {
      previous != snapshot
    }

    nonisolated static func scrollScript(forSlug slug: String) throws -> String {
      let data = try JSONEncoder().encode(slug)
      let json = String(decoding: data, as: UTF8.self)
      return "window.MarkdownDevPreview.scrollToHeading(\(json));"
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      shellLoaded = true

      if let pendingSnapshot {
        self.pendingSnapshot = nil
        render(pendingSnapshot)
      }

      if let pendingScrollTargetSlug {
        self.pendingScrollTargetSlug = nil
        scrollToHeading(slug: pendingScrollTargetSlug)
      }
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
      guard let url = navigationAction.request.url else {
        decisionHandler(.allow)
        return
      }

      if navigationAction.navigationType == .linkActivated {
        if PreviewSecurityPolicy.isAllowedExternalURL(url) {
          NSWorkspace.shared.open(url)
        }
        decisionHandler(.cancel)
        return
      }

      if url.isFileURL || url.scheme?.lowercased() == "about" {
        decisionHandler(.allow)
        return
      }

      decisionHandler(.cancel)
    }
  }
}

private struct HeadingPayload: Encodable {
  let slug: String
  let level: Int
}
