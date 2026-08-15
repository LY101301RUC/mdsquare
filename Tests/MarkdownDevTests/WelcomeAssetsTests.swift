import Testing
@testable import MarkdownDev

@Suite("WelcomeAssets")
struct WelcomeAssetsTests {
  @Test("loads bundled app icon")
  func loadsBundledAppIcon() {
    #expect(WelcomeAssets.appIconImage != nil)
  }

  @Test("loads bundled ink landscape")
  func loadsBundledInkLandscape() {
    #expect(WelcomeAssets.inkLandscapeImage != nil)
  }
}
