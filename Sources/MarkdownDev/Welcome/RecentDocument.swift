import Foundation

struct RecentDocument: Identifiable, Codable, Equatable {
  let url: URL
  let lastOpened: Date

  var id: String { url.path }
  var displayName: String { url.lastPathComponent }
  var displayPath: String { url.deletingLastPathComponent().path }
}
