import AppKit
import SwiftUI

struct HeadingColorPalette: Equatable {
  static let `default` = HeadingColorPalette()

  func color(for level: HeadingLevel) -> Color {
    Color(nsColor: nsColor(for: level))
  }

  func nsColor(for level: HeadingLevel) -> NSColor {
    switch level {
    case .h1:
      return .systemTeal
    case .h2:
      return .systemBrown
    case .h3:
      return .systemPurple
    case .h4:
      return .systemGreen
    case .h5:
      return .systemIndigo
    case .h6:
      return .secondaryLabelColor
    }
  }
}
