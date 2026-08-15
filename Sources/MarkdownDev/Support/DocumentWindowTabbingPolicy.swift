import AppKit

enum DocumentWindowTabbingPolicy {
  static let documentTabbingIdentifier = "com.mdsquare.editor.document-window"
  static let documentWindowFrameAutosaveName = "MdSquareDocumentWindow"

  @MainActor
  static func enableAppWideAutomaticTabbing() {
    NSWindow.allowsAutomaticWindowTabbing = true
  }

  @MainActor
  static func configure(_ window: NSWindow) {
    window.tabbingIdentifier = documentTabbingIdentifier
    window.tabbingMode = .preferred
    window.styleMask.remove(.fullSizeContentView)
    window.titlebarAppearsTransparent = false
    window.titlebarSeparatorStyle = .line
    window.setFrameAutosaveName(documentWindowFrameAutosaveName)
  }

  @MainActor
  static func configureIfAttached(_ window: NSWindow?) {
    guard let window else {
      return
    }

    configure(window)
  }
}
