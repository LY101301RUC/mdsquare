import Foundation
import Testing
@testable import MarkdownDev

@MainActor
@Suite("DraftRecoveryController")
struct DraftRecoveryControllerTests {
  @Test("builds a draft record for a file backed document")
  func buildsDraftRecordForFileBackedDocument() throws {
    let fileURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("plan.md")
    let record = DraftRecoveryController.record(
      text: "# Unsaved",
      fileURL: fileURL,
      updatedAt: Date(timeIntervalSince1970: 10)
    )

    #expect(record?.filePath == fileURL.path)
    #expect(record?.displayName == "plan.md")
    #expect(record?.text == "# Unsaved")
  }

  @Test("does not build empty drafts")
  func doesNotBuildEmptyDrafts() {
    #expect(DraftRecoveryController.record(text: "", fileURL: nil, updatedAt: Date()) == nil)
    #expect(DraftRecoveryController.record(text: "   \n", fileURL: nil, updatedAt: Date()) == nil)
  }
}
