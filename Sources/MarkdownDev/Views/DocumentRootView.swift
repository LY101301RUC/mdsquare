import SwiftUI

struct DocumentRootView: View {
  @Binding var document: MarkdownDocument
  let fileURL: URL?

  @Environment(\.dismissWindow) private var dismissWindow

  @State private var selection = NSRange(location: 0, length: 0)
  @State private var pendingCommand: PendingMarkdownCommand?
  @State private var pendingFindAction: PendingFindAction?
  @State private var commandTriggerID = 0
  @State private var findActionTriggerID = 0
  @State private var syncCoordinator: DocumentSyncCoordinator
  @State private var snapshotUpdateTask: Task<Void, Never>?
  @State private var previewSelectionSyncTask: Task<Void, Never>?
  @State private var editorScrollTarget: Heading?
  @State private var previewScrollTargetSlug: String?
  @State private var draftRecoveryController: DraftRecoveryController?
  @State private var fileState: DocumentFileState = .healthy
  @State private var knownFileModificationDate: Date?
  @State private var knownDiskText: String?
  @AppStorage(DocumentViewPreferences.viewModeKey) private var viewModeRawValue = DocumentViewMode.threeColumn.rawValue
  @AppStorage(DocumentViewPreferences.editorFractionKey) private var storedEditorFraction = Double(DocumentPaneLayout.editorPreviewDefaultFraction)

  private let fileStateMonitor = DocumentFileStateMonitor()

  init(document: Binding<MarkdownDocument>, fileURL: URL? = nil) {
    _document = document
    self.fileURL = fileURL
    _syncCoordinator = State(
      initialValue: DocumentSyncCoordinator(
        snapshot: MarkdownSnapshot(text: document.wrappedValue.text, baseDirectory: fileURL?.deletingLastPathComponent())
      )
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      DocumentNoticeBar(state: fileState)

      DocumentPaneSplitView(
        mode: viewMode,
        editorFraction: $storedEditorFraction
      ) {
        OutlineView(
          headings: syncCoordinator.snapshot.headings,
          selectedID: syncCoordinator.selectedHeading?.id,
          onSelect: { id in
            syncCoordinator.selectHeading(id: id)
            if viewMode.showsEditor {
              editorScrollTarget = syncCoordinator.selectedHeading
            }
            if viewMode.showsPreview {
              previewScrollTargetSlug = syncCoordinator.selectedPreviewSlug
            }
          }
        )
      } editor: {
        EditorPane(
          text: $document.text,
          selection: $selection,
          pendingCommand: pendingCommand,
          pendingFindAction: pendingFindAction,
          scrollTarget: editorScrollTarget,
          onCommandApplied: {
            pendingCommand = nil
          },
          onFindActionApplied: {
            pendingFindAction = nil
          },
          onScrollTargetConsumed: {
            editorScrollTarget = nil
          }
        )
      } preview: {
        PreviewPane(snapshot: syncCoordinator.snapshot, scrollTargetSlug: previewScrollTargetSlug)
          .onChange(of: previewScrollTargetSlug) { _, slug in
            guard let slug else { return }
            Task { @MainActor in
              await Task.yield()
              if previewScrollTargetSlug == slug {
                previewScrollTargetSlug = nil
              }
            }
          }
      }

      DocumentStatusBar(
        stats: DocumentStats(text: document.text, headings: syncCoordinator.snapshot.headings),
        selection: selection
      )
    }
    .frame(minWidth: DocumentPaneLayout.windowMinWidth, minHeight: DocumentPaneLayout.windowMinHeight)
    .toolbar {
      MarkdownToolbar(
        send: sendMarkdownCommand,
        viewMode: viewMode,
        setViewMode: setViewMode,
        isEditorVisible: viewMode.showsEditor
      )
    }
    .focusedValue(\.markdownCommandAction) { command in
      sendMarkdownCommand(command)
    }
    .focusedValue(\.markdownFindAction) { action in
      sendFindAction(action)
    }
    .background(DocumentWindowTabbingConfigurator().frame(width: 0, height: 0))
    .onChange(of: viewModeRawValue) { _, rawValue in
      clearHiddenPaneTargets(for: DocumentViewMode.resolved(from: rawValue))
    }
    .onChange(of: document.text) { _, text in
      scheduleSnapshotUpdate(for: text)
      draftRecoveryController?.scheduleSave(text: text)
      refreshFileState()
    }
    .onChange(of: selection) { _, newSelection in
      syncCoordinator.selectHeading(containingUTF16Location: newSelection.location)
      previewSelectionSyncTask?.cancel()
      guard viewMode.showsPreview, let slug = syncCoordinator.selectedPreviewSlug else {
        return
      }

      previewSelectionSyncTask = Task { @MainActor in
        do {
          try await Task.sleep(for: .milliseconds(350))
        } catch {
          return
        }

        previewScrollTargetSlug = slug
      }
    }
    .onDisappear {
      snapshotUpdateTask?.cancel()
      snapshotUpdateTask = nil
      previewSelectionSyncTask?.cancel()
      previewSelectionSyncTask = nil
      draftRecoveryController?.cancel()
      draftRecoveryController = nil
    }
    .onAppear {
      recordOpenedFileIfNeeded()
      draftRecoveryController = DraftRecoveryController(fileURL: fileURL)
      knownFileModificationDate = fileStateMonitor.modificationDate(for: fileURL)
      knownDiskText = fileStateMonitor.text(for: fileURL)
      refreshFileState()
    }
    .task(id: fileURL) {
      guard fileURL != nil else {
        return
      }

      while !Task.isCancelled {
        refreshFileState()
        try? await Task.sleep(for: .seconds(5))
      }
    }
  }

  private var viewMode: DocumentViewMode {
    DocumentViewMode.resolved(from: viewModeRawValue)
  }

  private func scheduleSnapshotUpdate(for text: String) {
    snapshotUpdateTask?.cancel()
    snapshotUpdateTask = Task { @MainActor in
      do {
        try await Task.sleep(for: .milliseconds(200))
      } catch {
        return
      }

      guard !Task.isCancelled, document.text == text else {
        return
      }

      syncCoordinator.update(text: text, baseDirectory: fileURL?.deletingLastPathComponent())
    }
  }

  private func sendMarkdownCommand(_ command: MarkdownEditorCommand) {
    guard viewMode.showsEditor else {
      return
    }

    commandTriggerID += 1
    pendingCommand = PendingMarkdownCommand(command: command, id: commandTriggerID)
  }

  private func sendFindAction(_ action: MarkdownFindAction) {
    guard viewMode.showsEditor else {
      return
    }

    findActionTriggerID += 1
    pendingFindAction = PendingFindAction(action: action, id: findActionTriggerID)
  }

  private func setViewMode(_ mode: DocumentViewMode) {
    viewModeRawValue = mode.rawValue
    clearHiddenPaneTargets(for: mode)
  }

  private func clearHiddenPaneTargets(for mode: DocumentViewMode) {
    if !mode.showsEditor {
      editorScrollTarget = nil
      pendingCommand = nil
      pendingFindAction = nil
    }

    if !mode.showsPreview {
      previewScrollTargetSlug = nil
      previewSelectionSyncTask?.cancel()
      previewSelectionSyncTask = nil
    }
  }

  private func refreshFileState() {
    fileState = fileStateMonitor.state(
      for: fileURL,
      documentText: document.text,
      knownDiskText: knownDiskText,
      previousModificationDate: knownFileModificationDate
    )

    if fileState == .healthy {
      knownFileModificationDate = fileStateMonitor.modificationDate(for: fileURL)
      updateKnownDiskTextIfNeeded()
    }
  }

  private func updateKnownDiskTextIfNeeded() {
    guard let diskText = fileStateMonitor.text(for: fileURL),
          diskText == document.text || knownDiskText == nil else {
      return
    }

    knownDiskText = diskText
  }

  private func recordOpenedFileIfNeeded() {
    guard let fileURL else {
      return
    }

    Task { @MainActor in
      RecentDocumentStore.shared.record(fileURL)
      dismissWindow(id: WelcomeWindow.id)
    }
  }
}
