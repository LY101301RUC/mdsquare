import AppKit

final class MdSquareAppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    ApplicationMenuLocalizer.install()
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    ApplicationMenuLocalizer.install()
  }

  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    false
  }
}
