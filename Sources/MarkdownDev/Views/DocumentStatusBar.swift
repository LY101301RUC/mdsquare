import SwiftUI

struct DocumentStatusBar: View {
  let stats: DocumentStats
  let selection: NSRange

  var body: some View {
    HStack(spacing: 12) {
      Text("行 \(stats.lineCount)")
      Text("词 \(stats.wordCount)")
      Text("字符 \(stats.characterCount)")
      Text("标题 \(stats.headingCount)")
      Spacer()
      Text("位置 \(selection.location)")
    }
    .font(.system(size: 11, weight: .medium))
    .foregroundStyle(.secondary)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(.bar)
  }
}
