import SwiftUI

enum DocumentPaneLayout {
  static let paneSpacing: CGFloat = 0
  static let splitterHitWidth: CGFloat = 14

  static let outlineMinWidth: CGFloat = 160
  static let outlineIdealWidth: CGFloat = 190
  static let outlineMaxWidth: CGFloat = 230

  static let contentPaneMinWidth: CGFloat = 320
  static let editorPreviewDefaultFraction: CGFloat = 0.5

  static let windowMinWidth: CGFloat = 980
  static let windowMinHeight: CGFloat = 620

  static let outlineRowSpacing: CGFloat = 8
  static let outlineMarkerSize: CGFloat = 6
  static let outlineLevelIndent: CGFloat = 12
  static let outlineRowVerticalPadding: CGFloat = 4
  static let outlineRowInsets = EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8)

  static let selectedOutlineCornerRadius: CGFloat = 6
  static let selectedOutlineHorizontalPadding: CGFloat = 4
  static let selectedOutlineVerticalPadding: CGFloat = 1
}
