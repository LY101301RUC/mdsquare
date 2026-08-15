import Foundation
import Testing
@testable import MarkdownDev

@Suite("RecoveredDraftFileWriter")
struct RecoveredDraftFileWriterTests {
  @Test("writes a recovered markdown file with a stable readable name")
  func writesRecoveredMarkdownFile() throws {
    let directoryURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("RecoveredDraftFileWriterTests-\(UUID().uuidString)", isDirectory: true)
    let writer = RecoveredDraftFileWriter(directoryURL: directoryURL)
    let record = DraftRecoveryRecord(
      id: "draft-1",
      filePath: directoryURL.appendingPathComponent("note.md").path,
      displayName: "note.md",
      text: "# Unsaved",
      updatedAt: Date(timeIntervalSince1970: 10)
    )

    let fileURL = try writer.write(record)

    #expect(fileURL.lastPathComponent.contains("note-recovered"))
    #expect(fileURL.pathExtension == "md")
    #expect(try String(contentsOf: fileURL, encoding: .utf8) == "# Unsaved")
  }
}
