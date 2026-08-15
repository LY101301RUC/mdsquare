import Testing
@testable import MarkdownDev

@Suite("HeadingSlugger")
struct HeadingSluggerTests {
  @Test("normalizes and deduplicates slugs")
  func normalizesAndDeduplicatesSlugs() {
    var slugger = HeadingSlugger()

    #expect(slugger.slug(for: "Intro") == "intro")
    #expect(slugger.slug(for: "Intro") == "intro-1")
    #expect(slugger.slug(for: "Intro!") == "intro-2")
    #expect(slugger.slug(for: "Section 2.1") == "section-2-1")
  }

  @Test("uses section fallback for empty slugs")
  func usesSectionFallbackForEmptySlugs() {
    var slugger = HeadingSlugger()

    #expect(slugger.slug(for: "!!!") == "section")
    #expect(slugger.slug(for: "???") == "section-1")
  }

  @Test("keeps slugs unique when natural slugs collide with suffixes")
  func keepsSlugsUniqueWhenNaturalSlugsCollideWithSuffixes() {
    var slugger = HeadingSlugger()

    #expect(slugger.slug(for: "A") == "a")
    #expect(slugger.slug(for: "A 1") == "a-1")
    #expect(slugger.slug(for: "A") == "a-2")
  }

  @Test("keeps fallback slugs unique when titles normalize to section")
  func keepsFallbackSlugsUniqueWhenTitlesNormalizeToSection() {
    var slugger = HeadingSlugger()

    #expect(slugger.slug(for: "!!!") == "section")
    #expect(slugger.slug(for: "section") == "section-1")
    #expect(slugger.slug(for: "???") == "section-2")
  }
}
