import AppKit
import SwiftUI

struct DocumentWindowTabbingConfigurator: NSViewRepresentable {
  func makeNSView(context: Context) -> NSView {
    DocumentWindowTabbingHostView(frame: .zero)
  }

  func updateNSView(_ view: NSView, context: Context) {
    (view as? DocumentWindowTabbingHostView)?.configureCurrentWindow()
  }
}

private final class DocumentWindowTabbingHostView: NSView {
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    configureCurrentWindow()
  }

  func configureCurrentWindow() {
    DocumentWindowTabbingPolicy.configureIfAttached(window)
  }
}
