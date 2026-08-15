enum MarkdownEditorCommand: Equatable {
  case heading(HeadingLevel)
  case bold
  case italic
  case textColor(MarkdownTextColor)
  case link
  case unorderedList
  case orderedList
  case quote
  case codeBlock
}

struct EditorCommandResult: Equatable {
  let text: String
  let replacementRange: Range<Int>
  let replacementText: String
  let selection: Range<Int>
}

enum EditorCommandHandler {
  static func apply(
    _ command: MarkdownEditorCommand,
    to text: String,
    selection: Range<Int>
  ) -> EditorCommandResult {
    let selection = normalized(selection, in: text)

    switch command {
    case let .heading(level):
      return applyHeading(level, to: text, selection: selection)
    case .bold:
      return wrapInline(
        text,
        selection: selection,
        prefix: "**",
        suffix: "**",
        placeholder: "bold"
      )
    case .italic:
      return wrapInline(
        text,
        selection: selection,
        prefix: "*",
        suffix: "*",
        placeholder: "italic"
      )
    case let .textColor(color):
      return applyTextColor(color, to: text, selection: selection)
    case .link:
      return applyLink(to: text, selection: selection)
    case .unorderedList:
      return prefixLines(in: text, selection: selection) { _ in "- " }
    case .orderedList:
      return prefixLines(in: text, selection: selection) { "\($0 + 1). " }
    case .quote:
      return applyQuote(to: text, selection: selection)
    case .codeBlock:
      return applyCodeBlock(to: text, selection: selection)
    }
  }
}

private extension EditorCommandHandler {
  static func applyHeading(
    _ level: HeadingLevel,
    to text: String,
    selection: Range<Int>
  ) -> EditorCommandResult {
    let lineRange = currentLineRange(in: text, containing: selection.lowerBound)
    let lineStartOffset = offset(of: lineRange.lowerBound, in: text)
    let lineText = String(text[lineRange])
    let marker = String(repeating: "#", count: level.rawValue)

    let transformation = headingLine(from: lineText, marker: marker)
    let replacementRange = lineStartOffset..<(lineStartOffset + lineText.utf16.count)
    var updatedText = text
    updatedText.replaceSubrange(lineRange, with: transformation.text)

    let bodyStart = lineStartOffset + transformation.bodyRange.lowerBound
    let bodyEnd = lineStartOffset + transformation.bodyRange.upperBound
    return EditorCommandResult(
      text: updatedText,
      replacementRange: replacementRange,
      replacementText: transformation.text,
      selection: bodyStart..<bodyEnd
    )
  }

  static func headingLine(from line: String, marker: String) -> (text: String, bodyRange: Range<Int>) {
    let leadingSpaces = line.prefix { $0 == " " }.count
    if leadingSpaces <= 3,
      let markerRange = atxMarkerRange(in: line, afterLeadingSpaces: leadingSpaces) {
      let body = String(line[markerRange.upperBound...]).drop { $0.isWhitespace }
      let prefix = String(repeating: " ", count: leadingSpaces) + marker + " "
      let updatedLine = prefix + body
      let bodyStart = prefix.utf16.count
      return (updatedLine, bodyStart..<(bodyStart + body.utf16.count))
    }

    let prefix = marker + " "
    let updatedLine = prefix + line
    let bodyStart = prefix.utf16.count
    return (updatedLine, bodyStart..<updatedLine.utf16.count)
  }

  static func atxMarkerRange(
    in line: String,
    afterLeadingSpaces leadingSpaces: Int
  ) -> Range<String.Index>? {
    let markerStart = line.index(line.startIndex, offsetBy: leadingSpaces)
    var markerEnd = markerStart
    var markerLength = 0

    while markerEnd < line.endIndex, line[markerEnd] == "#", markerLength < 6 {
      markerLength += 1
      markerEnd = line.index(after: markerEnd)
    }

    guard (1...6).contains(markerLength) else {
      return nil
    }

    if markerEnd < line.endIndex, !line[markerEnd].isWhitespace {
      return nil
    }

    return markerStart..<markerEnd
  }

  static func wrapInline(
    _ text: String,
    selection: Range<Int>,
    prefix: String,
    suffix: String,
    placeholder: String
  ) -> EditorCommandResult {
    let selectedText = string(in: selection, of: text)
    if !selectedText.isEmpty,
       let result = unwrapInline(
        text,
        selection: selection,
        selectedText: selectedText,
        prefix: prefix,
        suffix: suffix
       ) {
      return result
    }

    let content = selectedText.isEmpty ? placeholder : selectedText
    let replacement = prefix + content + suffix
    let updatedText = replacing(selection, in: text, with: replacement)
    let contentStart = selection.lowerBound + prefix.utf16.count
    let contentEnd = contentStart + content.utf16.count

    return EditorCommandResult(
      text: updatedText,
      replacementRange: selection,
      replacementText: replacement,
      selection: contentStart..<contentEnd
    )
  }

  static func unwrapInline(
    _ text: String,
    selection: Range<Int>,
    selectedText: String,
    prefix: String,
    suffix: String
  ) -> EditorCommandResult? {
    let prefixLength = prefix.utf16.count
    let suffixLength = suffix.utf16.count
    guard selection.lowerBound >= prefixLength,
          selection.upperBound + suffixLength <= text.utf16.count else {
      return nil
    }

    let markerRange = (selection.lowerBound - prefixLength)..<(selection.upperBound + suffixLength)
    let prefixRange = markerRange.lowerBound..<selection.lowerBound
    let suffixRange = selection.upperBound..<markerRange.upperBound
    guard string(in: prefixRange, of: text) == prefix,
          string(in: suffixRange, of: text) == suffix else {
      return nil
    }

    let updatedText = replacing(markerRange, in: text, with: selectedText)
    let selectionStart = markerRange.lowerBound
    return EditorCommandResult(
      text: updatedText,
      replacementRange: markerRange,
      replacementText: selectedText,
      selection: selectionStart..<(selectionStart + selectedText.utf16.count)
    )
  }

  static func applyTextColor(
    _ color: MarkdownTextColor,
    to text: String,
    selection: Range<Int>
  ) -> EditorCommandResult {
    let selectedText = string(in: selection, of: text)
    if !selectedText.isEmpty,
       let existingSpan = colorSpanAround(selection: selection, in: text) {
      let replacement = color.openingTag + selectedText + color.closingTag
      let updatedText = replacing(existingSpan, in: text, with: replacement)
      let selectionStart = existingSpan.lowerBound + color.openingTag.utf16.count

      return EditorCommandResult(
        text: updatedText,
        replacementRange: existingSpan,
        replacementText: replacement,
        selection: selectionStart..<(selectionStart + selectedText.utf16.count)
      )
    }

    return wrapInline(
      text,
      selection: selection,
      prefix: color.openingTag,
      suffix: color.closingTag,
      placeholder: "color"
    )
  }

  static func colorSpanAround(
    selection: Range<Int>,
    in text: String
  ) -> Range<Int>? {
    for color in MarkdownTextColor.allCases {
      let prefix = color.openingTag
      let suffix = color.closingTag
      let prefixLength = prefix.utf16.count
      let suffixLength = suffix.utf16.count

      guard selection.lowerBound >= prefixLength,
            selection.upperBound + suffixLength <= text.utf16.count else {
        continue
      }

      let markerRange = (selection.lowerBound - prefixLength)..<(selection.upperBound + suffixLength)
      let prefixRange = markerRange.lowerBound..<selection.lowerBound
      let suffixRange = selection.upperBound..<markerRange.upperBound

      guard string(in: prefixRange, of: text) == prefix,
            string(in: suffixRange, of: text) == suffix else {
        continue
      }

      return markerRange
    }

    return nil
  }

  static func applyLink(to text: String, selection: Range<Int>) -> EditorCommandResult {
    let selectedText = string(in: selection, of: text)
    let label = selectedText.isEmpty ? "text" : selectedText
    let url = "url"
    let replacement = "[\(label)](\(url))"
    let updatedText = replacing(selection, in: text, with: replacement)
    let urlStart = selection.lowerBound + label.utf16.count + 3

    return EditorCommandResult(
      text: updatedText,
      replacementRange: selection,
      replacementText: replacement,
      selection: urlStart..<(urlStart + url.utf16.count)
    )
  }

  static func applyQuote(to text: String, selection: Range<Int>) -> EditorCommandResult {
    let lineRange = selectedLineRange(in: text, selection: selection)
    let lineStartOffset = offset(of: lineRange.lowerBound, in: text)
    let selectedText = String(text[lineRange])
    let replacementRange = lineStartOffset..<(lineStartOffset + selectedText.utf16.count)
    let lines = selectedText.split(separator: "\n", omittingEmptySubsequences: false)
    let replacement: String

    if lines.allSatisfy(hasQuotePrefix) {
      replacement = lines.map(removingQuotePrefix).joined(separator: "\n")
    } else {
      replacement = lines.map { "> " + $0 }.joined(separator: "\n")
    }

    var updatedText = text
    updatedText.replaceSubrange(lineRange, with: replacement)

    if selection.isEmpty, selectedText.isEmpty {
      let cursor = lineStartOffset + 2
      return EditorCommandResult(
        text: updatedText,
        replacementRange: replacementRange,
        replacementText: replacement,
        selection: cursor..<cursor
      )
    }

    return EditorCommandResult(
      text: updatedText,
      replacementRange: replacementRange,
      replacementText: replacement,
      selection: lineStartOffset..<(lineStartOffset + replacement.utf16.count)
    )
  }

  static func hasQuotePrefix(_ line: Substring) -> Bool {
    line.hasPrefix(">")
  }

  static func removingQuotePrefix(_ line: Substring) -> String {
    if line.hasPrefix("> ") {
      return String(line.dropFirst(2))
    }

    return String(line.dropFirst())
  }

  static func prefixLines(
    in text: String,
    selection: Range<Int>,
    prefixForLine: (Int) -> String
  ) -> EditorCommandResult {
    let lineRange = selectedLineRange(in: text, selection: selection)
    let lineStartOffset = offset(of: lineRange.lowerBound, in: text)
    let selectedText = String(text[lineRange])
    let replacementRange = lineStartOffset..<(lineStartOffset + selectedText.utf16.count)
    let lines = selectedText.split(separator: "\n", omittingEmptySubsequences: false)
    let prefixedLines = lines.enumerated().map { index, line in
      prefixForLine(index) + line
    }
    let replacement = prefixedLines.joined(separator: "\n")
    var updatedText = text
    updatedText.replaceSubrange(lineRange, with: replacement)

    if selection.isEmpty, selectedText.isEmpty {
      let cursor = lineStartOffset + prefixForLine(0).utf16.count
      return EditorCommandResult(
        text: updatedText,
        replacementRange: replacementRange,
        replacementText: replacement,
        selection: cursor..<cursor
      )
    }

    return EditorCommandResult(
      text: updatedText,
      replacementRange: replacementRange,
      replacementText: replacement,
      selection: lineStartOffset..<(lineStartOffset + replacement.utf16.count)
    )
  }

  static func applyCodeBlock(to text: String, selection: Range<Int>) -> EditorCommandResult {
    let selectedText = string(in: selection, of: text)
    let replacement = "```\n\(selectedText)\n```"
    let updatedText = replacing(selection, in: text, with: replacement)
    let contentStart = selection.lowerBound + 4
    let contentEnd = contentStart + selectedText.utf16.count

    return EditorCommandResult(
      text: updatedText,
      replacementRange: selection,
      replacementText: replacement,
      selection: contentStart..<contentEnd
    )
  }

  static func selectedLineRange(in text: String, selection: Range<Int>) -> Range<String.Index> {
    if selection.isEmpty {
      return currentLineRange(in: text, containing: selection.lowerBound)
    }

    let endOffset = max(selection.lowerBound, selection.upperBound - 1)
    let start = currentLineRange(in: text, containing: selection.lowerBound).lowerBound
    let end = currentLineRange(in: text, containing: endOffset).upperBound
    return start..<end
  }

  static func currentLineRange(in text: String, containing offset: Int) -> Range<String.Index> {
    let index = index(at: offset, in: text)
    let lineStart = text[..<index].lastIndex(of: "\n").map { text.index(after: $0) } ?? text.startIndex
    let lineEnd = text[index...].firstIndex(of: "\n") ?? text.endIndex

    return lineStart..<lineEnd
  }

  static func replacing(_ range: Range<Int>, in text: String, with replacement: String) -> String {
    var updatedText = text
    updatedText.replaceSubrange(indexRange(for: range, in: text), with: replacement)
    return updatedText
  }

  static func string(in range: Range<Int>, of text: String) -> String {
    String(text[indexRange(for: range, in: text)])
  }

  static func indexRange(for range: Range<Int>, in text: String) -> Range<String.Index> {
    index(at: range.lowerBound, in: text)..<index(at: range.upperBound, in: text)
  }

  static func index(at offset: Int, in text: String) -> String.Index {
    String.Index(utf16Offset: offset, in: text)
  }

  static func offset(of index: String.Index, in text: String) -> Int {
    index.utf16Offset(in: text)
  }

  static func normalized(_ selection: Range<Int>, in text: String) -> Range<Int> {
    let textLength = text.utf16.count
    let clampedLowerBound = min(max(selection.lowerBound, 0), textLength)
    let clampedUpperBound = min(max(selection.upperBound, clampedLowerBound), textLength)
    let lowerBound = characterBoundary(atOrBefore: clampedLowerBound, in: text)
    let upperBound = characterBoundary(atOrAfter: clampedUpperBound, in: text)

    return lowerBound..<upperBound
  }

  static func characterBoundary(atOrBefore offset: Int, in text: String) -> Int {
    let endOffset = text.endIndex.utf16Offset(in: text)
    guard offset < endOffset else {
      return endOffset
    }

    var boundary = text.startIndex.utf16Offset(in: text)
    for index in text.indices {
      let indexOffset = index.utf16Offset(in: text)
      if indexOffset > offset {
        break
      }

      boundary = indexOffset
    }

    return boundary
  }

  static func characterBoundary(atOrAfter offset: Int, in text: String) -> Int {
    guard offset > 0 else {
      return text.startIndex.utf16Offset(in: text)
    }

    for index in text.indices {
      let indexOffset = index.utf16Offset(in: text)
      if indexOffset >= offset {
        return indexOffset
      }
    }

    return text.endIndex.utf16Offset(in: text)
  }
}
