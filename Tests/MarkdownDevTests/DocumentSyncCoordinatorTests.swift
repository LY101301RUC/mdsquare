import Testing
@testable import MarkdownDev

@Suite("DocumentSyncCoordinator")
struct DocumentSyncCoordinatorTests {
  @Test("selects heading by real heading id")
  func selectsHeadingByRealHeadingID() throws {
    let snapshot = MarkdownSnapshot(text: "# One\n\n## Two")
    let coordinator = DocumentSyncCoordinator(snapshot: snapshot)
    let two = try #require(snapshot.headings.first { $0.title == "Two" })

    coordinator.selectHeading(id: two.id)

    #expect(coordinator.selectedHeading?.title == "Two")
    #expect(coordinator.selectedPreviewSlug == "two")
  }

  @Test("clears selected heading and slug when heading disappears")
  func clearsSelectionWhenHeadingDisappears() throws {
    let snapshot = MarkdownSnapshot(text: "# One\n\n## Two")
    let coordinator = DocumentSyncCoordinator(snapshot: snapshot)
    let two = try #require(snapshot.headings.first { $0.title == "Two" })
    coordinator.selectHeading(id: two.id)

    coordinator.update(text: "# One\n\nBody")

    #expect(coordinator.selectedHeading == nil)
    #expect(coordinator.selectedPreviewSlug == nil)
  }

  @Test("keeps selected heading when heading remains")
  func keepsSelectionWhenHeadingRemains() throws {
    let snapshot = MarkdownSnapshot(text: "# One\n\n## Two")
    let coordinator = DocumentSyncCoordinator(snapshot: snapshot)
    let two = try #require(snapshot.headings.first { $0.title == "Two" })
    coordinator.selectHeading(id: two.id)

    coordinator.update(text: "# One\n\n## Two\n\nBody")

    #expect(coordinator.selectedHeading?.id == two.id)
    #expect(coordinator.selectedHeading?.title == "Two")
    #expect(coordinator.selectedPreviewSlug == "two")
  }

  @Test("keeps selected heading by slug when heading line changes")
  func keepsSelectionBySlugWhenHeadingLineChanges() throws {
    let snapshot = MarkdownSnapshot(text: "# One\n\n## Two")
    let coordinator = DocumentSyncCoordinator(snapshot: snapshot)
    let two = try #require(snapshot.headings.first { $0.title == "Two" })
    coordinator.selectHeading(id: two.id)

    coordinator.update(text: "# Intro\n\n# One\n\n## Two")

    #expect(coordinator.selectedHeading?.title == "Two")
    #expect(coordinator.selectedHeading?.id != two.id)
    #expect(coordinator.selectedPreviewSlug == "two")
  }

  @Test("selects heading containing editor selection")
  func selectsHeadingContainingEditorSelection() {
    let coordinator = DocumentSyncCoordinator(snapshot: MarkdownSnapshot(text: "# One\nBody\n## Two\nMore"))

    coordinator.selectHeading(containingUTF16Location: 14)

    #expect(coordinator.selectedHeading?.title == "Two")
  }

  @Test("keeps previous heading when selection is in body below it")
  func keepsPreviousHeadingWhenSelectionIsInBodyBelowIt() {
    let coordinator = DocumentSyncCoordinator(snapshot: MarkdownSnapshot(text: "# One\nBody\n## Two\nMore"))

    coordinator.selectHeading(containingUTF16Location: 7)

    #expect(coordinator.selectedHeading?.title == "One")
  }

  @Test("exposes active preview slug for editor selection")
  func exposesActivePreviewSlugForEditorSelection() {
    let coordinator = DocumentSyncCoordinator(snapshot: MarkdownSnapshot(text: "# One\nBody\n## Two\nMore"))

    coordinator.selectHeading(containingUTF16Location: 14)

    #expect(coordinator.selectedPreviewSlug == "two")
  }
}
