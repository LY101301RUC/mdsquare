import Foundation
import Observation

@Observable
final class DocumentSyncCoordinator {
  var snapshot: MarkdownSnapshot
  var selectedHeading: Heading?
  var selectedPreviewSlug: String?

  init(snapshot: MarkdownSnapshot) {
    self.snapshot = snapshot
  }

  func update(text: String, baseDirectory: URL? = nil) {
    snapshot = MarkdownSnapshot(text: text, baseDirectory: baseDirectory)

    guard let selectedHeading else {
      return
    }

    if let matchingHeading = snapshot.headings.first(where: { $0.id == selectedHeading.id }) {
      self.selectedHeading = matchingHeading
      selectedPreviewSlug = matchingHeading.slug
    } else if let selectedPreviewSlug,
              let matchingHeading = snapshot.headings.first(where: { $0.slug == selectedPreviewSlug }) {
      self.selectedHeading = matchingHeading
      self.selectedPreviewSlug = matchingHeading.slug
    } else {
      self.selectedHeading = nil
      self.selectedPreviewSlug = nil
    }
  }

  func selectHeading(id: String) {
    selectedHeading = snapshot.headings.first { $0.id == id }
    selectedPreviewSlug = selectedHeading?.slug
  }

  func selectHeading(containingUTF16Location location: Int) {
    guard !snapshot.headings.isEmpty else {
      selectedHeading = nil
      selectedPreviewSlug = nil
      return
    }

    let selected = snapshot.headings.last { heading in
      heading.sourceRange.lowerBound.utf16Offset(in: snapshot.text) <= location
    } ?? snapshot.headings.first

    selectedHeading = selected
    selectedPreviewSlug = selected?.slug
  }
}
