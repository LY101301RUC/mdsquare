import Foundation

struct HeadingExtractor {
  static func extract(from text: String) -> [Heading] {
    var headings: [Heading] = []
    var slugger = HeadingSlugger()
    var fence: Fence?
    var pendingSetextLine: SetextLine?
    var lineNumber = 1
    var lineStart = text.startIndex

    while lineStart < text.endIndex {
      let lineEnd = text[lineStart...].firstIndex(of: "\n") ?? text.endIndex
      let line = text[lineStart..<lineEnd]

      if let openFence = fence {
        if isClosingFence(line, for: openFence) {
          fence = nil
        }
        pendingSetextLine = nil
      } else if let openingFence = openingFence(in: line) {
        fence = openingFence
        pendingSetextLine = nil
      } else if let level = setextUnderlineLevel(in: line), let setextLine = pendingSetextLine {
        let slug = slugger.slug(for: setextLine.title)
        headings.append(
          Heading(
            level: level,
            title: setextLine.title,
            slug: slug,
            sourceRange: setextLine.sourceRange,
            lineNumber: setextLine.lineNumber
          )
        )
        pendingSetextLine = nil
      } else if let parsedHeading = parseHeading(in: line) {
        let slug = slugger.slug(for: parsedHeading.title)
        headings.append(
          Heading(
            level: parsedHeading.level,
            title: parsedHeading.title,
            slug: slug,
            sourceRange: lineStart..<lineEnd,
            lineNumber: lineNumber
          )
        )
        pendingSetextLine = nil
      } else {
        pendingSetextLine = setextLine(
          in: line,
          sourceRange: lineStart..<lineEnd,
          lineNumber: lineNumber
        )
      }

      lineNumber += 1

      guard lineEnd < text.endIndex else {
        break
      }

      lineStart = text.index(after: lineEnd)
    }

    return headings
  }

  private struct Fence {
    let marker: Character
    let length: Int
  }

  private struct SetextLine {
    let title: String
    let sourceRange: Range<String.Index>
    let lineNumber: Int
  }

  private static func openingFence(in line: Substring) -> Fence? {
    fence(in: line)
  }

  private static func isClosingFence(_ line: Substring, for openFence: Fence) -> Bool {
    guard let closingFence = fence(in: line) else {
      return false
    }

    return closingFence.marker == openFence.marker && closingFence.length >= openFence.length
  }

  private static func fence(in line: Substring) -> Fence? {
    guard leadingSpaceCount(in: line) <= 3 else {
      return nil
    }

    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard let marker = trimmed.first, marker == "`" || marker == "~" else {
      return nil
    }

    let length = trimmed.prefix(while: { $0 == marker }).count
    guard length >= 3 else {
      return nil
    }

    return Fence(marker: marker, length: length)
  }

  private static func parseHeading(in line: Substring) -> (level: HeadingLevel, title: String)? {
    var index = line.startIndex
    var indentation = 0

    while index < line.endIndex, line[index] == " " {
      indentation += 1
      guard indentation <= 3 else {
        return nil
      }

      index = line.index(after: index)
    }

    var markerCount = 0

    while index < line.endIndex, line[index] == "#", markerCount < 7 {
      markerCount += 1
      index = line.index(after: index)
    }

    guard (1...6).contains(markerCount),
          index < line.endIndex,
          line[index].isWhitespace,
          let level = HeadingLevel(rawValue: markerCount) else {
      return nil
    }

    let contentStart = line.index(after: index)
    let title = strippedClosingMarkers(from: line[contentStart..<line.endIndex])
    guard !title.isEmpty else {
      return nil
    }

    return (level, title)
  }

  private static func setextLine(
    in line: Substring,
    sourceRange: Range<String.Index>,
    lineNumber: Int
  ) -> SetextLine? {
    guard leadingSpaceCount(in: line) <= 3 else {
      return nil
    }

    let title = line.trimmingCharacters(in: .whitespaces)
    guard !title.isEmpty, setextUnderlineLevel(in: line) == nil else {
      return nil
    }

    return SetextLine(title: title, sourceRange: sourceRange, lineNumber: lineNumber)
  }

  private static func setextUnderlineLevel(in line: Substring) -> HeadingLevel? {
    guard leadingSpaceCount(in: line) <= 3 else {
      return nil
    }

    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard let marker = trimmed.first, marker == "=" || marker == "-" else {
      return nil
    }

    guard trimmed.allSatisfy({ $0 == marker }) else {
      return nil
    }

    return marker == "=" ? .h1 : .h2
  }

  private static func leadingSpaceCount(in line: Substring) -> Int {
    line.prefix { $0 == " " }.count
  }

  private static func strippedClosingMarkers(from content: Substring) -> String {
    var end = content.endIndex

    while content.startIndex < end, content[content.index(before: end)].isWhitespace {
      end = content.index(before: end)
    }

    var hashStart = end
    while content.startIndex < hashStart, content[content.index(before: hashStart)] == "#" {
      hashStart = content.index(before: hashStart)
    }

    if hashStart < end,
       content.startIndex < hashStart,
       content[content.index(before: hashStart)].isWhitespace {
      end = hashStart
    }

    let stripped = content[..<end].trimmingCharacters(in: .whitespaces)
    return stripped
  }
}
