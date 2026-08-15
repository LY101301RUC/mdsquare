import AppKit
import Foundation

struct HighlightRange: Equatable {
  let level: HeadingLevel
  let range: NSRange
}

struct ColorHighlightRange: Equatable {
  let color: MarkdownTextColor
  let range: NSRange
}

enum MarkdownColorSpanScanner {
  static func colorRanges(in text: String) -> [ColorHighlightRange] {
    MarkdownTextColor.allCases.flatMap { color in
      ranges(for: color, in: text)
    }
    .sorted { $0.range.location < $1.range.location }
  }

  private static func ranges(
    for color: MarkdownTextColor,
    in text: String
  ) -> [ColorHighlightRange] {
    let pattern = NSRegularExpression.escapedPattern(for: color.openingTag)
      + #"([\s\S]*?)"#
      + NSRegularExpression.escapedPattern(for: color.closingTag)
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      return []
    }

    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.matches(in: text, range: range).compactMap { match in
      guard match.numberOfRanges >= 2 else {
        return nil
      }

      return ColorHighlightRange(color: color, range: match.range(at: 1))
    }
  }
}

enum HeadingSyntaxHighlighter {
  static func headingLineRanges(in text: String) -> [HighlightRange] {
    HeadingExtractor.extract(from: text).map { heading in
      HighlightRange(level: heading.level, range: NSRange(heading.sourceRange, in: text))
    }
  }

  static func apply(
    to textStorage: NSTextStorage,
    palette: HeadingColorPalette = .default
  ) {
    let text = textStorage.string
    let fullRange = NSRange(location: 0, length: (text as NSString).length)
    let baseFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    guard fullRange.length > 0 else {
      return
    }

    textStorage.beginEditing()
    defer {
      textStorage.endEditing()
    }

    textStorage.setAttributes(
      [
        .font: baseFont,
        .foregroundColor: NSColor.labelColor
      ],
      range: fullRange
    )

    for highlightRange in headingLineRanges(in: text) {
      textStorage.addAttributes(
        [
          .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
          .foregroundColor: palette.nsColor(for: highlightRange.level)
        ],
        range: highlightRange.range
      )
    }

    for colorRange in MarkdownColorSpanScanner.colorRanges(in: text) {
      textStorage.addAttribute(
        .foregroundColor,
        value: colorRange.color.nsColor,
        range: colorRange.range
      )
    }
  }
}

private extension MarkdownTextColor {
  var nsColor: NSColor {
    switch self {
    case .red:
      NSColor.systemRed
    case .blue:
      NSColor.systemBlue
    }
  }
}
