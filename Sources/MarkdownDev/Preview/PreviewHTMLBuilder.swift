import Foundation

enum PreviewHTMLBuilder {
  static func shellHTML() throws -> String {
    let url = try shellURL()

    return try String(contentsOf: url, encoding: .utf8)
  }

  static func shellURL() throws -> URL {
    let url = Bundle.module.url(
      forResource: "preview-shell",
      withExtension: "html",
      subdirectory: "Preview"
    ) ?? Bundle.module.url(forResource: "preview-shell", withExtension: "html")

    guard let url else {
      throw CocoaError(.fileNoSuchFile)
    }

    return url
  }

  static func resourceReadAccessURL(forShellAt shellURL: URL) -> URL {
    shellURL.deletingLastPathComponent()
  }

  static func bundledScriptURL(forSource source: String) -> URL? {
    let scriptURL = URL(fileURLWithPath: source)
    let resourceName = scriptURL.deletingPathExtension().lastPathComponent
    let resourceExtension = scriptURL.pathExtension

    return Bundle.module.url(forResource: resourceName, withExtension: resourceExtension)
  }
}
