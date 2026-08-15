import Foundation

struct HeadingSlugger {
  private var usedSlugs: Set<String> = []

  mutating func slug(for title: String) -> String {
    let baseSlug = Self.baseSlug(for: title)
    var candidate = baseSlug
    var suffix = 1

    while usedSlugs.contains(candidate) {
      candidate = "\(baseSlug)-\(suffix)"
      suffix += 1
    }

    usedSlugs.insert(candidate)
    return candidate
  }

  private static func baseSlug(for title: String) -> String {
    var scalars: [UnicodeScalar] = []
    var previousWasHyphen = false

    for scalar in title.lowercased().unicodeScalars {
      if CharacterSet.alphanumerics.contains(scalar) {
        scalars.append(scalar)
        previousWasHyphen = false
      } else if !previousWasHyphen {
        scalars.append("-")
        previousWasHyphen = true
      }
    }

    let trimmed = String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return trimmed.isEmpty ? "section" : trimmed
  }
}
