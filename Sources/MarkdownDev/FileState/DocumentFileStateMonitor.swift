import Foundation

struct DocumentFileStateMonitor {
  func state(
    for fileURL: URL?,
    documentText: String,
    knownDiskText: String? = nil,
    previousModificationDate: Date?
  ) -> DocumentFileState {
    guard let fileURL else {
      return .healthy
    }

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return .missing
    }

    guard FileManager.default.isWritableFile(atPath: fileURL.path) else {
      return .readOnly
    }

    guard let previousModificationDate,
          let currentModificationDate = modificationDate(for: fileURL),
          currentModificationDate > previousModificationDate else {
      return .healthy
    }

    let diskText = text(for: fileURL)
    if diskText == documentText || diskText == knownDiskText {
      return .healthy
    }

    return .externallyModified
  }

  func modificationDate(for fileURL: URL?) -> Date? {
    guard let fileURL,
          let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) else {
      return nil
    }

    return attributes[.modificationDate] as? Date
  }

  func text(for fileURL: URL?) -> String? {
    guard let fileURL else {
      return nil
    }

    return try? String(contentsOf: fileURL, encoding: .utf8)
  }
}
