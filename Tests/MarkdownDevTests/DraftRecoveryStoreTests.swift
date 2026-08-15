import Foundation
import Testing
@testable import MarkdownDev

@Suite("DraftRecoveryStore")
struct DraftRecoveryStoreTests {
  @Test("saves and loads a file backed draft")
  func savesAndLoadsFileBackedDraft() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("DraftRecoveryStoreTests-\(UUID().uuidString)")
    let store = DraftRecoveryStore(directoryURL: directory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let fileURL = directory.appendingPathComponent("note.md")

    let record = DraftRecoveryRecord(
      id: DraftRecoveryStore.identity(for: fileURL),
      filePath: fileURL.path,
      displayName: "note.md",
      text: "# Draft\nUnsaved",
      updatedAt: Date(timeIntervalSince1970: 100)
    )

    try store.save(record)

    #expect(try store.loadAll() == [record])
  }

  @Test("deletes a saved draft")
  func deletesSavedDraft() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("DraftRecoveryStoreTests-\(UUID().uuidString)")
    let store = DraftRecoveryStore(directoryURL: directory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let id = "untitled-test"
    let record = DraftRecoveryRecord(
      id: id,
      filePath: nil,
      displayName: "未命名文档",
      text: "hello",
      updatedAt: Date(timeIntervalSince1970: 1)
    )

    try store.save(record)
    try store.delete(id: id)

    #expect(try store.loadAll().isEmpty)
  }

  @Test("filters file backed drafts older than the file on disk")
  func filtersFileBackedDraftsOlderThanDiskFile() throws {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("DraftRecoveryStoreTests-\(UUID().uuidString)")
    let store = DraftRecoveryStore(directoryURL: directory)
    defer { try? FileManager.default.removeItem(at: directory) }
    let fileURL = directory.appendingPathComponent("saved.md")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try "# Saved".write(to: fileURL, atomically: true, encoding: .utf8)
    let oldDraft = DraftRecoveryRecord(
      id: DraftRecoveryStore.identity(for: fileURL),
      filePath: fileURL.path,
      displayName: "saved.md",
      text: "# Old Draft",
      updatedAt: Date(timeIntervalSince1970: 1)
    )

    try store.save(oldDraft)

    #expect(try store.recoverableDrafts().isEmpty)
  }
}
