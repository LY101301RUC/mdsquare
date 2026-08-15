import Foundation
import Testing
@testable import MarkdownDev

@Suite("DocumentFileStateMonitor")
struct DocumentFileStateMonitorTests {
  @Test("reports missing file")
  func reportsMissingFile() throws {
    let monitor = DocumentFileStateMonitor()
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("md")

    #expect(monitor.state(for: url, documentText: "# Local", previousModificationDate: nil) == .missing)
  }

  @Test("reports externally modified file when disk text differs")
  func reportsExternallyModifiedFileWhenDiskTextDiffers() throws {
    let monitor = DocumentFileStateMonitor()
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("md")
    try "# Disk".write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }
    let oldDate = Date(timeIntervalSince1970: 1)

    #expect(monitor.state(for: url, documentText: "# Local", previousModificationDate: oldDate) == .externallyModified)
  }

  @Test("does not report external modification when only local unsaved text differs")
  func doesNotReportExternalModificationWhenOnlyLocalUnsavedTextDiffers() throws {
    let monitor = DocumentFileStateMonitor()
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("md")
    try "# Saved".write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }
    let oldDate = Date(timeIntervalSince1970: 1)

    #expect(
      monitor.state(
        for: url,
        documentText: "# Saved\nLocal unsaved edit",
        knownDiskText: "# Saved",
        previousModificationDate: oldDate
      ) == .healthy
    )
  }

  @Test("reports external modification when disk text differs from last known disk text")
  func reportsExternalModificationWhenDiskTextDiffersFromLastKnownDiskText() throws {
    let monitor = DocumentFileStateMonitor()
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("md")
    try "# External".write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }
    let oldDate = Date(timeIntervalSince1970: 1)

    #expect(
      monitor.state(
        for: url,
        documentText: "# Original\nLocal unsaved edit",
        knownDiskText: "# Original",
        previousModificationDate: oldDate
      ) == .externallyModified
    )
  }

  @Test("reports healthy when disk text matches document text")
  func reportsHealthyWhenDiskTextMatchesDocumentText() throws {
    let monitor = DocumentFileStateMonitor()
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("md")
    try "# Same".write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }

    #expect(monitor.state(for: url, documentText: "# Same", previousModificationDate: nil) == .healthy)
  }
}
