import AppKit
import Testing
@testable import MarkdownDev

@MainActor
@Suite("DocumentWindowTabbingPolicy")
struct DocumentWindowTabbingPolicyTests {
  @Test("configures document windows to prefer a shared tab group")
  func configuresDocumentWindowsToPreferSharedTabGroup() {
    let window = NSWindow()

    DocumentWindowTabbingPolicy.configure(window)

    #expect(window.tabbingMode == .preferred)
    #expect(window.tabbingIdentifier == DocumentWindowTabbingPolicy.documentTabbingIdentifier)
  }

  @Test("keeps document titlebar visually separated from content")
  @MainActor
  func keepsDocumentTitlebarVisuallySeparatedFromContent() {
    let window = NSWindow()

    DocumentWindowTabbingPolicy.configure(window)

    #expect(window.titlebarAppearsTransparent == false)
    #expect(window.titlebarSeparatorStyle == .line)
    #expect(!window.styleMask.contains(.fullSizeContentView))
  }

  @Test("configures a stable frame autosave name")
  func configuresStableFrameAutosaveName() {
    let window = NSWindow()

    DocumentWindowTabbingPolicy.configure(window)

    #expect(window.frameAutosaveName == "MdSquareDocumentWindow")
  }
}
