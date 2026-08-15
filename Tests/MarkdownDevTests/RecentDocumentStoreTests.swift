import Foundation
import Testing
@testable import MarkdownDev

@MainActor
@Suite("RecentDocumentStore")
struct RecentDocumentStoreTests {
  @Test("records recent documents newest first and deduplicated")
  func recordsRecentDocumentsNewestFirstAndDeduplicated() throws {
    let suiteName = "RecentDocumentStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = RecentDocumentStore(userDefaults: defaults, limit: 3)
    let first = URL(fileURLWithPath: "/tmp/first.md")
    let second = URL(fileURLWithPath: "/tmp/second.md")

    store.record(first)
    store.record(second)
    store.record(first)

    #expect(store.recentDocuments.map(\.url) == [first.standardizedFileURL, second.standardizedFileURL])
  }

  @Test("limits stored recent documents")
  func limitsStoredRecentDocuments() throws {
    let suiteName = "RecentDocumentStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = RecentDocumentStore(userDefaults: defaults, limit: 2)

    store.record(URL(fileURLWithPath: "/tmp/one.md"))
    store.record(URL(fileURLWithPath: "/tmp/two.md"))
    store.record(URL(fileURLWithPath: "/tmp/three.md"))

    #expect(store.recentDocuments.map(\.displayName) == ["three.md", "two.md"])
  }

  @Test("removes recent documents that no longer exist")
  func removesRecentDocumentsThatNoLongerExist() throws {
    let suiteName = "RecentDocumentStoreTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = RecentDocumentStore(userDefaults: defaults, limit: 3)
    let existing = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("md")
    let missing = URL(fileURLWithPath: "/tmp/missing-\(UUID().uuidString).md")
    try "# Existing".write(to: existing, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: existing) }

    store.record(missing)
    store.record(existing)
    store.pruneMissingFiles()

    #expect(store.recentDocuments.map(\.url) == [existing.standardizedFileURL])
  }
}
