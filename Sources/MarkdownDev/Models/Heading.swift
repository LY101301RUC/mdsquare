import Foundation

struct Heading: Identifiable, Equatable, Hashable {
  let id: String
  let level: HeadingLevel
  let title: String
  let slug: String
  let sourceRange: Range<String.Index>
  let lineNumber: Int

  init(level: HeadingLevel, title: String, slug: String, sourceRange: Range<String.Index>, lineNumber: Int) {
    self.id = "\(lineNumber)-\(slug)"
    self.level = level
    self.title = title
    self.slug = slug
    self.sourceRange = sourceRange
    self.lineNumber = lineNumber
  }
}
