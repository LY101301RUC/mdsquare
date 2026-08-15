import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MarkdownDev

@Suite("MarkdownDocument")
struct MarkdownDocumentTests {
  @Test("decodes UTF-8")
  func decodesUTF8() throws {
    let data = Data("# Title\nBody".utf8)

    #expect(try MarkdownDocument.decodeMarkdownText(from: data) == "# Title\nBody")
  }

  @Test("decodes UTF-8 BOM")
  func decodesUTF8BOM() throws {
    var data = Data([0xEF, 0xBB, 0xBF])
    data.append(Data("# Title".utf8))

    #expect(try MarkdownDocument.decodeMarkdownText(from: data) == "# Title")
  }

  @Test("rejects non UTF-8")
  func rejectsNonUTF8() {
    let data = Data([0xFF, 0xFE, 0x00, 0x00])

    #expect(throws: CocoaError.self) {
      _ = try MarkdownDocument.decodeMarkdownText(from: data)
    }
  }

  @Test("writes UTF-8 markdown")
  func writesUTF8() throws {
    let document = MarkdownDocument(text: "# Saved\n")
    let data = document.encodedMarkdownData()

    #expect(String(data: data, encoding: .utf8) == "# Saved\n")
  }
}
