struct DocumentStats: Equatable {
  let lineCount: Int
  let wordCount: Int
  let characterCount: Int
  let headingCount: Int

  init(text: String, headings: [Heading]) {
    lineCount = text.isEmpty ? 0 : text.split(separator: "\n", omittingEmptySubsequences: false).count
    wordCount = text.split { !$0.isLetter && !$0.isNumber }.count
    characterCount = text.count
    headingCount = headings.count
  }
}
