import AppKit
import Foundation

enum WelcomeAssets {
  static var appIconImage: NSImage? {
    image(named: "AppIconSource")
  }

  static var inkLandscapeImage: NSImage? {
    image(named: "WelcomeInkLandscape")
  }

  private static func image(named name: String) -> NSImage? {
    guard let url = Bundle.module.url(forResource: name, withExtension: "png") else {
      return nil
    }

    return NSImage(contentsOf: url)
  }
}
