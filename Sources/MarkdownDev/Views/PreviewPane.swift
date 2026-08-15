import SwiftUI

struct PreviewPane: View {
  let snapshot: MarkdownSnapshot
  let scrollTargetSlug: String?

  var body: some View {
    WebPreviewRenderer(snapshot: snapshot, scrollTargetSlug: scrollTargetSlug)
  }
}
