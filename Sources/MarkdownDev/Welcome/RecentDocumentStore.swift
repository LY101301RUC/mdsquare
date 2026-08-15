import Foundation

@MainActor
struct RecentDocumentStore {
  static let shared = RecentDocumentStore()

  private let userDefaults: UserDefaults
  private let limit: Int
  private let key = "MdSquare.recentDocuments"

  init(userDefaults: UserDefaults = .standard, limit: Int = 6) {
    self.userDefaults = userDefaults
    self.limit = limit
  }

  var recentDocuments: [RecentDocument] {
    guard let data = userDefaults.data(forKey: key),
          let documents = try? JSONDecoder().decode([RecentDocument].self, from: data) else {
      return []
    }

    return documents
  }

  func record(_ url: URL, openedAt date: Date = Date()) {
    let normalizedURL = url.standardizedFileURL
    let newDocument = RecentDocument(url: normalizedURL, lastOpened: date)
    let documents = ([newDocument] + recentDocuments.filter { $0.url.standardizedFileURL != normalizedURL })
      .prefix(limit)

    if let data = try? JSONEncoder().encode(Array(documents)) {
      userDefaults.set(data, forKey: key)
    }
  }

  func pruneMissingFiles() {
    let documents = recentDocuments
    let existingDocuments = documents.filter {
      FileManager.default.fileExists(atPath: $0.url.path)
    }

    guard existingDocuments != documents else {
      return
    }

    if let data = try? JSONEncoder().encode(existingDocuments) {
      userDefaults.set(data, forKey: key)
    }
  }
}
