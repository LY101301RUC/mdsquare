import Foundation

struct RecoveredDraftFileWriter {
  let directoryURL: URL

  init(
    directoryURL: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent("MdSquare", isDirectory: true)
      .appendingPathComponent("RecoveredDrafts", isDirectory: true)
  ) {
    self.directoryURL = directoryURL
  }

  func write(_ record: DraftRecoveryRecord) throws -> URL {
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

    let fileURL = directoryURL
      .appendingPathComponent(fileName(for: record), isDirectory: false)
      .appendingPathExtension("md")
    try record.text.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL
  }

  private func fileName(for record: DraftRecoveryRecord) -> String {
    let displayName = URL(fileURLWithPath: record.displayName)
      .deletingPathExtension()
      .lastPathComponent
    let baseName = sanitized(displayName.isEmpty ? "draft" : displayName)
    let suffix = sanitized(String(record.id.prefix(12)))

    if suffix.isEmpty {
      return "\(baseName)-recovered"
    }

    return "\(baseName)-recovered-\(suffix)"
  }

  private func sanitized(_ text: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    let characters = text.unicodeScalars.map { scalar in
      allowed.contains(scalar) ? Character(scalar) : "-"
    }
    let collapsed = String(characters)
      .split(separator: "-", omittingEmptySubsequences: true)
      .joined(separator: "-")

    return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
  }
}
