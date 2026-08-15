import Foundation

@MainActor
final class DraftRecoveryController {
  private let store: DraftRecoveryStore
  private let fileURL: URL?
  private var pendingTask: Task<Void, Never>?

  init(store: DraftRecoveryStore = .shared, fileURL: URL?) {
    self.store = store
    self.fileURL = fileURL
  }

  func scheduleSave(text: String) {
    pendingTask?.cancel()
    pendingTask = Task { @MainActor [store, fileURL] in
      do {
        try await Task.sleep(for: .milliseconds(900))
      } catch {
        return
      }

      guard let record = Self.record(text: text, fileURL: fileURL, updatedAt: Date()) else {
        return
      }

      try? store.save(record)
    }
  }

  func cancel() {
    pendingTask?.cancel()
    pendingTask = nil
  }

  static func record(text: String, fileURL: URL?, updatedAt: Date) -> DraftRecoveryRecord? {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }

    return DraftRecoveryRecord(
      id: DraftRecoveryStore.identity(for: fileURL),
      filePath: fileURL?.standardizedFileURL.path,
      displayName: fileURL?.lastPathComponent ?? "未命名文档",
      text: text,
      updatedAt: updatedAt
    )
  }
}
