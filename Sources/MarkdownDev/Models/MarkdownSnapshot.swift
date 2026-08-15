import Foundation

struct MarkdownSnapshot: Equatable {
  let text: String
  let headings: [Heading]
  let localImages: [String: String]

  init(text: String, baseDirectory: URL? = nil) {
    self.text = text
    self.headings = HeadingExtractor.extract(from: text)
    self.localImages = PreviewImageResolver(baseDirectory: baseDirectory).resolve(in: text)
  }
}
