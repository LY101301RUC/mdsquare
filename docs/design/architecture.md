# MdSquare Architecture

## Overview

MdSquare is a local-first macOS document application built as a Swift Package executable. SwiftUI provides scene and view composition, AppKit provides the native text editor and window integration, and WebKit hosts a deliberately constrained Markdown preview.

The package exposes one executable product, `MdSquare`, from the historical source target `MarkdownDev`. The application supports macOS 14 and newer.

## Document Data Flow

1. `MarkdownDocument` reads and writes UTF-8 Markdown through SwiftUI's document APIs.
2. `DocumentRootView` owns document-window state and connects editing, outline, preview, file monitoring, and recovery services.
3. `MarkdownTextViewRepresentable` bridges SwiftUI state to the native `MarkdownTextView`.
4. `DocumentSyncCoordinator` derives a `MarkdownSnapshot` from the current text and editor selection.
5. `HeadingExtractor` and `HeadingSlugger` produce stable outline entries and preview anchors.
6. `PreviewPane` passes the snapshot to `WebPreviewRenderer`, which invokes the bundled preview JavaScript inside a WebKit view.

The outline and preview consume the same snapshot, so heading identity and navigation stay aligned.

## Main Components

- `App/`: application entry point, menus, commands, and AppKit delegate behavior.
- `Models/`: document, heading, and snapshot value types.
- `Editor/`: native text editing, formatting commands, find actions, keyboard shortcuts, and syntax highlighting.
- `Parsing/`: Markdown heading extraction and stable slug generation.
- `Preview/`: WebKit bridge, HTML builder, local image resolver, and link policy.
- `Recovery/`: periodic local draft records and recovered-file writing.
- `FileState/`: detection of missing or externally modified source files.
- `Sync/`: editor selection, outline selection, and preview scroll coordination.
- `Views/`: pane layout, view modes, toolbar, outline, editor, preview, notices, and status bar.
- `Welcome/`: welcome window, recent documents, open panel, and bundled artwork.

## Preview Security Boundary

Markdown text is rendered by the vendored `markdown-it` distribution with raw HTML disabled. The preview script constructs allowed output and leaves unsupported HTML inert.

External navigation is restricted to explicitly allowed web and mail schemes. Remote images are blocked. Same-directory local images are resolved in Swift, constrained by file location and size, and provided to the preview as data URLs. Unsupported color markup remains visible as text instead of becoming active HTML.

Tests cover script injection, unsafe links, remote-image blocking, local-path traversal, and supported color rendering.

## Persistence And Recovery

`RecentDocumentStore` records recently opened local files. `DraftRecoveryStore` persists unsaved text outside the document itself, and `RecoveredDraftFileWriter` creates a separate recovered Markdown file instead of overwriting the source. `DocumentFileStateMonitor` compares the current document with the known disk state and surfaces missing-file or external-change warnings.

## Layout And Preferences

`DocumentViewMode` defines four presentations: three-column, writing, reading, and focus. `DocumentPaneSplitView` calculates pane visibility and widths and persists the editor/preview ratio through `@AppStorage`. The outline uses a stable width; the editor/preview boundary exposes a native resize cursor and drag behavior.

## Build And Verification

- Swift Package Manager builds the application and test target.
- `script/build_and_run.sh` assembles the local `.app` bundle and its document-type metadata.
- `script/test.sh` runs Swift tests and JavaScript preview fixtures.
- `script/measure_core_perf.mjs --budget` enforces preview budgets for generated 100KB and 1MB Markdown fixtures.
- `script/vendor-preview-assets.mjs` copies the locked `markdown-it` distribution into application resources.

Generated products live under `.build/`, `dist/`, and `tmp/` and are not part of the source repository.
