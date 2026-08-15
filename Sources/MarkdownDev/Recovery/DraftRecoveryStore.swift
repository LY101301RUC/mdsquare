import Foundation

struct DraftRecoveryStore {
  static let shared = DraftRecoveryStore(
    directoryURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("MdSquare", isDirectory: true)
      .appendingPathComponent("Drafts", isDirectory: true)
  )

  let directoryURL: URL

  static func identity(for fileURL: URL?) -> String {
    guard let fileURL else {
      return "untitled"
    }

    let path = fileURL.standardizedFileURL.path
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
    return path.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? UUID().uuidString
  }

  func save(_ record: DraftRecoveryRecord) throws {
    try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    let data = try JSONEncoder.draftRecovery.encode(record)
    try data.write(to: url(for: record.id), options: .atomic)
  }

  func delete(id: String) throws {
    let draftURL = url(for: id)
    guard FileManager.default.fileExists(atPath: draftURL.path) else {
      return
    }

    try FileManager.default.removeItem(at: draftURL)
  }

  func loadAll() throws -> [DraftRecoveryRecord] {
    guard FileManager.default.fileExists(atPath: directoryURL.path) else {
      return []
    }

    let urls = try FileManager.default.contentsOfDirectory(
      at: directoryURL,
      includingPropertiesForKeys: nil
    )

    return try urls
      .filter { $0.pathExtension == "json" }
      .map { try Data(contentsOf: $0) }
      .map { try JSONDecoder.draftRecovery.decode(DraftRecoveryRecord.self, from: $0) }
      .sorted { $0.updatedAt > $1.updatedAt }
  }

  func recoverableDrafts() throws -> [DraftRecoveryRecord] {
    try loadAll().filter { record in
      guard let filePath = record.filePath else {
        return !record.text.isEmpty
      }

      let fileURL = URL(fileURLWithPath: filePath)
      guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let modificationDate = attributes[.modificationDate] as? Date else {
        return !record.text.isEmpty
      }

      return record.updatedAt > modificationDate
    }
  }

  private func url(for id: String) -> URL {
    directoryURL.appendingPathComponent(id).appendingPathExtension("json")
  }
}

private extension JSONEncoder {
  static var draftRecovery: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }
}

private extension JSONDecoder {
  static var draftRecovery: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
