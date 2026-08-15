import SwiftUI

struct DocumentNoticeBar: View {
  let state: DocumentFileState

  var body: some View {
    if let message = state.message {
      Text(message)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.black.opacity(0.78))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.18))
    }
  }
}
