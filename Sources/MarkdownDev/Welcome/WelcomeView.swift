import AppKit
import SwiftUI

struct WelcomeView: View {
  @Environment(\.dismissWindow) private var dismissWindow
  @Environment(\.openDocument) private var openDocument

  let recentStore: RecentDocumentStore
  let draftRecoveryStore: DraftRecoveryStore
  let recoveredDraftWriter: RecoveredDraftFileWriter

  @State private var recentDocuments: [RecentDocument] = []
  @State private var recoverableDrafts: [DraftRecoveryRecord] = []
  @State private var errorMessage: String?

  private let contentWidth: CGFloat = 596
  private let primaryCardHeight: CGFloat = 214
  private let openCardWidth: CGFloat = 240
  private let recentCardWidth: CGFloat = 340

  init(
    recentStore: RecentDocumentStore,
    draftRecoveryStore: DraftRecoveryStore = .shared,
    recoveredDraftWriter: RecoveredDraftFileWriter = RecoveredDraftFileWriter()
  ) {
    self.recentStore = recentStore
    self.draftRecoveryStore = draftRecoveryStore
    self.recoveredDraftWriter = recoveredDraftWriter
  }

  var body: some View {
    ZStack {
      welcomeBackground

      VStack(spacing: 0) {
        Spacer(minLength: 0)

        VStack(spacing: 28) {
          header

          if !recoverableDrafts.isEmpty {
            recoverableDraftsCard
          }

          HStack(alignment: .top, spacing: 16) {
            openFileCard
            recentFilesCard
          }
          .frame(width: contentWidth, height: primaryCardHeight)
        }
        .frame(width: contentWidth)

        Spacer(minLength: 0)
      }
      .padding(.horizontal, 64)
    }
    .frame(width: WelcomeWindow.width, height: WelcomeWindow.height)
    .onAppear {
      reloadWelcomeData()
    }
  }

  private var welcomeBackground: some View {
    ZStack {
      Color(red: 0.95, green: 0.91, blue: 0.81)
        .ignoresSafeArea()

      if let image = WelcomeAssets.inkLandscapeImage {
        Image(nsImage: image)
          .resizable()
          .scaledToFill()
          .frame(
            width: WelcomeWindow.width,
            height: WelcomeWindow.height + WelcomeWindow.backgroundBleed,
            alignment: .top
          )
          .clipped()
          .offset(y: WelcomeWindow.backgroundBleed / 2)
          .ignoresSafeArea()
      }

      LinearGradient(
        colors: [
          Color(red: 0.95, green: 0.91, blue: 0.81).opacity(0.04),
          Color(red: 0.95, green: 0.91, blue: 0.81).opacity(0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    }
  }

  private var header: some View {
    HStack(spacing: 18) {
      appIcon

      VStack(alignment: .leading, spacing: 7) {
        Text("欢迎使用 MdSquare")
          .font(.system(size: 27, weight: .semibold, design: .serif))
          .foregroundStyle(.black.opacity(0.88))

        Text("更清晰地打开、编辑与预览 Markdown。")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(.black.opacity(0.56))
      }

      Spacer(minLength: 0)
    }
    .frame(width: contentWidth)
  }

  @ViewBuilder
  private var appIcon: some View {
    if let image = WelcomeAssets.appIconImage {
      Image(nsImage: image)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 58, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    } else {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Color(red: 0.95, green: 0.91, blue: 0.81))
        .frame(width: 58, height: 58)
        .overlay {
          Text("md²")
            .font(.system(size: 22, weight: .bold, design: .serif))
            .foregroundStyle(.black)
        }
    }
  }

  private var openFileCard: some View {
    Button {
      chooseAndOpenFile()
    } label: {
      VStack(alignment: .leading, spacing: 0) {
        Image(systemName: "folder")
          .font(.system(size: 25, weight: .medium))
          .foregroundStyle(.black.opacity(0.78))
          .frame(width: 50, height: 50)
          .background(.black.opacity(0.055), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        Spacer()

        VStack(alignment: .leading, spacing: 4) {
          Text("打开文件")
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(.black.opacity(0.88))

          Text("选择一个 .md 或 .markdown 文件")
            .font(.system(size: 12))
            .foregroundStyle(.black.opacity(0.52))
        }

        Spacer().frame(height: 24)

        HStack {
          Text("选择文件")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.black.opacity(0.54))

          Spacer()

          Image(systemName: "arrow.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.black.opacity(0.4))
        }
      }
      .padding(18)
      .frame(width: openCardWidth, height: primaryCardHeight)
      .welcomeCardChrome()
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Open File")
  }

  private var recentFilesCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("过往文件")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.black.opacity(0.78))

        Spacer()
      }

      if recentDocuments.isEmpty {
        Text("打开 Markdown 文件后会显示在这里。")
          .font(.system(size: 12))
          .foregroundStyle(.black.opacity(0.46))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 8)
      } else {
        VStack(spacing: 2) {
          ForEach(recentDocuments.prefix(3)) { document in
            Button {
              openRecentDocument(document)
            } label: {
              RecentDocumentRow(document: document)
            }
            .buttonStyle(.plain)
          }
        }

        if recentDocuments.count > 3 {
          Text("还有 \(recentDocuments.count - 3) 个最近打开的文件")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.black.opacity(0.42))
            .padding(.top, 2)
        }
      }

      if let errorMessage {
        Text(errorMessage)
          .font(.system(size: 12))
          .foregroundStyle(.red.opacity(0.78))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .frame(width: recentCardWidth, height: primaryCardHeight, alignment: .top)
    .welcomeCardChrome()
  }

  @ViewBuilder
  private var recoverableDraftsCard: some View {
    if !recoverableDrafts.isEmpty {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("可恢复草稿")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.black.opacity(0.78))

          Spacer()
        }

        VStack(spacing: 2) {
          ForEach(recoverableDrafts.prefix(3)) { draft in
            Button {
              openRecoveredDraft(draft)
            } label: {
              RecoveredDraftRow(record: draft)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .welcomeCardChrome()
    }
  }

  private func chooseAndOpenFile() {
    guard let url = WelcomeOpenPanel.chooseMarkdownFile() else {
      return
    }

    open(url)
  }

  private func openRecentDocument(_ document: RecentDocument) {
    open(document.url)
  }

  private func openRecoveredDraft(_ record: DraftRecoveryRecord) {
    errorMessage = nil
    Task { @MainActor in
      do {
        let fileURL = try recoveredDraftWriter.write(record)
        try await openDocument(at: fileURL)
        try? draftRecoveryStore.delete(id: record.id)
        reloadWelcomeData()
        dismissWindow(id: WelcomeWindow.id)
      } catch {
        errorMessage = "无法恢复这个草稿，请重新打开原文件检查。"
      }
    }
  }

  private func open(_ url: URL) {
    errorMessage = nil
    Task { @MainActor in
      do {
        try await openDocument(at: url)
        recentStore.record(url)
        reloadWelcomeData()
        dismissWindow(id: WelcomeWindow.id)
      } catch {
        errorMessage = "无法打开这个文件，请确认它仍然存在并且是 UTF-8 Markdown。"
      }
    }
  }

  private func reloadRecentDocuments() {
    recentStore.pruneMissingFiles()
    recentDocuments = recentStore.recentDocuments
  }

  private func reloadRecoverableDrafts() {
    recoverableDrafts = (try? draftRecoveryStore.recoverableDrafts()) ?? []
  }

  private func reloadWelcomeData() {
    reloadRecentDocuments()
    reloadRecoverableDrafts()
  }
}

private extension View {
  func welcomeCardChrome() -> some View {
    background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(.black.opacity(0.08), lineWidth: 1)
      }
      .shadow(color: .black.opacity(0.04), radius: 16, y: 6)
  }
}

private struct RecoveredDraftRow: View {
  let record: DraftRecoveryRecord

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "clock.arrow.circlepath")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.black.opacity(0.48))
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(record.displayName)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.black.opacity(0.8))
          .lineLimit(1)

        Text(recoverySubtitle)
          .font(.system(size: 11))
          .foregroundStyle(.black.opacity(0.42))
          .lineLimit(1)
      }

      Spacer()

      Text("打开副本")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.black.opacity(0.5))
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .contentShape(Rectangle())
  }

  private var recoverySubtitle: String {
    if let filePath = record.filePath {
      return URL(fileURLWithPath: filePath).deletingLastPathComponent().path
    }

    return "未命名文档"
  }
}

private struct RecentDocumentRow: View {
  let document: RecentDocument

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "doc.text")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.black.opacity(0.48))
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 2) {
        Text(document.displayName)
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.black.opacity(0.8))
          .lineLimit(1)

        Text(document.displayPath)
          .font(.system(size: 11))
          .foregroundStyle(.black.opacity(0.42))
          .lineLimit(1)
      }

      Spacer()
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .contentShape(Rectangle())
  }
}
