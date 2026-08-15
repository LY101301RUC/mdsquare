import Foundation

enum PreviewSecurityPolicy {
  static let allowedSchemes: Set<String> = ["http", "https", "mailto"]

  static func isAllowedExternalURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased() else { return false }
    return allowedSchemes.contains(scheme)
  }
}
