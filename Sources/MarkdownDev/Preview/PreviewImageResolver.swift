import Foundation

struct PreviewImageResolver {
  let baseDirectory: URL?
  let maxBytes: Int

  private let mimeTypes = [
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "gif": "image/gif",
    "webp": "image/webp"
  ]

  init(baseDirectory: URL?, maxBytes: Int = 5 * 1024 * 1024) {
    self.baseDirectory = baseDirectory
    self.maxBytes = maxBytes
  }

  func resolve(in markdown: String) -> [String: String] {
    guard let baseDirectory else {
      return [:]
    }

    let pattern = #"!\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      return [:]
    }

    let nsRange = NSRange(markdown.startIndex..<markdown.endIndex, in: markdown)
    var images: [String: String] = [:]

    for match in regex.matches(in: markdown, range: nsRange) {
      guard let range = Range(match.range(at: 1), in: markdown) else {
        continue
      }

      let source = String(markdown[range])
      guard let dataURL = dataURL(for: source, baseDirectory: baseDirectory) else {
        continue
      }

      images[source] = dataURL
    }

    return images
  }

  private func dataURL(for source: String, baseDirectory: URL) -> String? {
    guard !source.contains("://"),
          !source.hasPrefix("data:"),
          !source.hasPrefix("file:") else {
      return nil
    }

    let imageURL = baseDirectory.appendingPathComponent(source).standardizedFileURL
    let baseURL = baseDirectory.standardizedFileURL
    let basePath = baseURL.path
    guard imageURL.path.hasPrefix(basePath + "/") else {
      return nil
    }

    let ext = imageURL.pathExtension.lowercased()
    guard let mimeType = mimeTypes[ext],
          let data = try? Data(contentsOf: imageURL),
          data.count <= maxBytes else {
      return nil
    }

    return "data:\(mimeType);base64,\(data.base64EncodedString())"
  }
}
