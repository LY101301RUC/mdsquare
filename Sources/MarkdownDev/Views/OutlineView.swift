import SwiftUI

struct OutlineView: View {
  let headings: [Heading]
  let selectedID: Heading.ID?
  let onSelect: (Heading.ID) -> Void

  private let palette = HeadingColorPalette.default

  var body: some View {
    Group {
      if headings.isEmpty {
        ContentUnavailableView(
          "暂无大纲",
          systemImage: "list.bullet.rectangle",
          description: Text("添加 Markdown 标题后会在这里显示。")
        )
      } else {
        ScrollViewReader { proxy in
          List(headings) { heading in
            Button {
              onSelect(heading.id)
            } label: {
              HStack(spacing: DocumentPaneLayout.outlineRowSpacing) {
                Circle()
                  .fill(palette.color(for: heading.level))
                  .frame(
                    width: DocumentPaneLayout.outlineMarkerSize,
                    height: DocumentPaneLayout.outlineMarkerSize
                  )

                Text(heading.title)
                  .font(.system(size: 13, weight: selectedID == heading.id ? .semibold : .regular))
                  .foregroundStyle(.primary)
                  .lineLimit(1)
                  .truncationMode(.tail)
              }
              .padding(.vertical, DocumentPaneLayout.outlineRowVerticalPadding)
              .padding(.leading, indentation(for: heading))
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(Rectangle())
            }
            .id(heading.id)
            .buttonStyle(.plain)
            .listRowInsets(DocumentPaneLayout.outlineRowInsets)
            .listRowSeparator(.hidden)
            .listRowBackground(rowBackground(for: heading))
          }
          .listStyle(.sidebar)
          .onChange(of: selectedID) { _, id in
            guard let id else {
              return
            }

            withAnimation(.easeOut(duration: 0.16)) {
              proxy.scrollTo(id, anchor: .center)
            }
          }
        }
      }
    }
    .frame(
      minWidth: DocumentPaneLayout.outlineMinWidth,
      idealWidth: DocumentPaneLayout.outlineIdealWidth,
      maxWidth: DocumentPaneLayout.outlineMaxWidth
    )
  }

  private func indentation(for heading: Heading) -> CGFloat {
    CGFloat(max(heading.level.rawValue - 1, 0)) * DocumentPaneLayout.outlineLevelIndent
  }

  @ViewBuilder
  private func rowBackground(for heading: Heading) -> some View {
    if selectedID == heading.id {
      RoundedRectangle(cornerRadius: DocumentPaneLayout.selectedOutlineCornerRadius, style: .continuous)
        .fill(Color.accentColor.opacity(0.14))
        .padding(.horizontal, DocumentPaneLayout.selectedOutlineHorizontalPadding)
        .padding(.vertical, DocumentPaneLayout.selectedOutlineVerticalPadding)
    } else {
      Color.clear
    }
  }
}
