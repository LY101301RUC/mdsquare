import Foundation

struct DraftRecoveryRecord: Codable, Equatable, Identifiable {
  let id: String
  let filePath: String?
  let displayName: String
  let text: String
  let updatedAt: Date
}
