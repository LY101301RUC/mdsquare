import Testing
@testable import MarkdownDev

@Suite("WebPreviewRenderer")
struct WebPreviewRendererTests {
  @Test("builds render script with JSON encoded markdown and headings")
  func buildsRenderScriptWithJSONEncodedPayload() throws {
    let snapshot = MarkdownSnapshot(text: "# O'Reilly\n\n<script>alert('x')</script>\n\n## Two")

    let script = try WebPreviewRenderer.Coordinator.renderScript(for: snapshot)

    #expect(script.hasPrefix("window.MarkdownDevPreview.render("))
    #expect(script.hasSuffix(");"))
    #expect(script.contains(##""# O'Reilly\n\n<script>alert('x')<\/script>\n\n## Two""##))
    #expect(script.contains(#"[{"level":1,"slug":"o-reilly"},{"level":2,"slug":"two"}]"#))
  }

  @Test("builds scroll script with JSON encoded slug")
  func buildsScrollScriptWithJSONEncodedSlug() throws {
    let script = try WebPreviewRenderer.Coordinator.scrollScript(forSlug: #"quote'and"slash"#)

    #expect(script == #"window.MarkdownDevPreview.scrollToHeading("quote'and\"slash");"#)
  }

  @Test("render identity uses full snapshot equality")
  func renderIdentityUsesFullSnapshotEquality() {
    let first = MarkdownSnapshot(text: "# Title\n\nBody")
    let same = MarkdownSnapshot(text: "# Title\n\nBody")
    let differentBodySameHeadingCount = MarkdownSnapshot(text: "# Title\n\nChanged")

    #expect(WebPreviewRenderer.Coordinator.shouldRender(first, after: nil))
    #expect(!WebPreviewRenderer.Coordinator.shouldRender(same, after: first))
    #expect(WebPreviewRenderer.Coordinator.shouldRender(differentBodySameHeadingCount, after: first))
  }
}
