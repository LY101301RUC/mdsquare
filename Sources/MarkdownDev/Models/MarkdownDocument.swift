import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.markdownDevMarkdown, .plainText] }
  static var writableContentTypes: [UTType] { [.markdownDevMarkdown] }

  var text: String

  init(text: String = "") {
    self.text = text
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }

    self.text = try Self.decodeMarkdownText(from: data)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = encodedMarkdownData()
    return FileWrapper(regularFileWithContents: data)
  }

  static func decodeMarkdownText(from data: Data) throws -> String {
    let trimmedData: Data
    if data.starts(with: [0xEF, 0xBB, 0xBF]) {
      trimmedData = Data(data.dropFirst(3))
    } else {
      trimmedData = data
    }

    guard let text = String(data: trimmedData, encoding: .utf8) else {
      throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    return text
  }

  func encodedMarkdownData() -> Data {
    Data(text.utf8)
  }
}
