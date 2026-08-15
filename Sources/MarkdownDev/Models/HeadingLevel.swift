enum HeadingLevel: Int, CaseIterable, Codable, Hashable, Comparable {
  case h1 = 1
  case h2 = 2
  case h3 = 3
  case h4 = 4
  case h5 = 5
  case h6 = 6

  static func < (lhs: HeadingLevel, rhs: HeadingLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
