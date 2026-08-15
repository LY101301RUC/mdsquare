import Foundation
import Testing
@testable import MarkdownDev

@Suite("PreviewSecurityPolicy")
struct PreviewSecurityPolicyTests {
  @Test("allows external links with web and mail schemes")
  func allowsExpectedExternalSchemes() throws {
    #expect(PreviewSecurityPolicy.isAllowedExternalURL(try #require(URL(string: "https://example.com"))))
    #expect(PreviewSecurityPolicy.isAllowedExternalURL(try #require(URL(string: "http://example.com"))))
    #expect(PreviewSecurityPolicy.isAllowedExternalURL(try #require(URL(string: "mailto:hello@example.com"))))
  }

  @Test("rejects script and local file schemes")
  func rejectsUnsafeSchemes() throws {
    #expect(!PreviewSecurityPolicy.isAllowedExternalURL(try #require(URL(string: "javascript:alert(1)"))))
    #expect(!PreviewSecurityPolicy.isAllowedExternalURL(try #require(URL(string: "file:///tmp/x.png"))))
  }

  @Test("matches schemes case insensitively")
  func matchesSchemesCaseInsensitively() throws {
    #expect(PreviewSecurityPolicy.isAllowedExternalURL(try #require(URL(string: "HTTPS://example.com"))))
    #expect(!PreviewSecurityPolicy.isAllowedExternalURL(try #require(URL(string: "JAVASCRIPT:alert(1)"))))
  }

  @Test("loads bundled preview shell")
  func loadsBundledPreviewShell() throws {
    let html = try PreviewHTMLBuilder.shellHTML()

    #expect(html.contains("preview-renderer.js"))
    #expect(html.contains("markdown-it.min.js"))
    #expect(!html.contains("https://"))
    #expect(!html.contains("http://"))
  }

  @Test("bundled preview shell scripts resolve in resource bundle")
  func bundledPreviewShellScriptsResolveInResourceBundle() throws {
    let html = try PreviewHTMLBuilder.shellHTML()
    let scriptSources = try scriptSources(in: html)

    #expect(scriptSources == ["markdown-it.min.js", "preview-renderer.js"])

    for scriptSource in scriptSources {
      #expect(PreviewHTMLBuilder.bundledScriptURL(forSource: scriptSource) != nil)
    }
  }

  @Test("bundled preview shell URL grants web view read access to scripts")
  func bundledPreviewShellURLGrantsWebViewReadAccessToScripts() throws {
    let html = try PreviewHTMLBuilder.shellHTML()
    let shellURL = try PreviewHTMLBuilder.shellURL()
    let readAccessURL = PreviewHTMLBuilder.resourceReadAccessURL(forShellAt: shellURL)

    #expect(shellURL.isFileURL)
    #expect(readAccessURL.isFileURL)

    for scriptSource in try scriptSources(in: html) {
      let scriptURL = readAccessURL.appendingPathComponent(scriptSource)
      #expect(FileManager.default.fileExists(atPath: scriptURL.path))
    }
  }

  private func scriptSources(in html: String) throws -> [String] {
    let pattern = #"<script\s+src="([^"]+)""#
    let regex = try NSRegularExpression(pattern: pattern)
    let range = NSRange(html.startIndex..<html.endIndex, in: html)

    return regex.matches(in: html, range: range).compactMap { match in
      guard let sourceRange = Range(match.range(at: 1), in: html) else { return nil }
      return String(html[sourceRange])
    }
  }
}
