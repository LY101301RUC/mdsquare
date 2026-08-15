import AppKit
import Testing
@testable import MarkdownDev

@MainActor
@Suite("MdSquareAppDelegate")
struct MdSquareAppDelegateTests {
  @Test("direct launch does not ask AppKit to open an untitled document")
  func directLaunchDoesNotAskAppKitToOpenUntitledDocument() {
    let delegate = MdSquareAppDelegate()

    #expect(delegate.applicationShouldOpenUntitledFile(NSApplication.shared) == false)
  }
}
