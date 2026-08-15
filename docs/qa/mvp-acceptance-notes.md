# MdSquare MVP Acceptance Notes

Date: 2026-05-09

## Automated Verification

- `./script/test.sh`: pass
- `./script/build_and_run.sh --verify`: pass
- Info.plist document type check: pass

## Manual Verification

- Document I/O: pass
- Three-pane layout: pass
- Markdown preview: pass
- Outline navigation: pass
- Editing commands: pass
- Light/Dark appearance: pass
- Appearance note: Light Mode was visually checked in the app. Dark Mode was verified through dynamic AppKit colors and preview `color-scheme` support; the available per-app override did not visually toggle the running UI during this pass.

## Known Non-MVP Gaps

- No folder workspace.
- No settings window.
- No raw HTML rendering.
- No Mermaid or math rendering.
- No precise bidirectional scroll synchronization.

## Local Product Maturity Baseline

Date: 2026-05-11

- `./script/test.sh`: pass before maturity work.
- `node script/measure_core_perf.mjs`: pass before maturity work.
- `git diff --check`: pass before maturity work.
- Known local untracked files: `MarkdownDev_MVP_Test.md`, `MdSquare.app`.

## Local Product Maturity Acceptance

Date: 2026-05-11

### Automated Verification

- `./script/test.sh`: pass, 105 tests in 23 suites; preview fixtures verified.
- `node script/measure_core_perf.mjs`: pass; 100KB preview 75.22ms, 1MB preview 545.05ms in this run.
- `node script/measure_core_perf.mjs --budget`: pass; 100KB preview 74.11ms, 1MB preview 569.99ms in this run.
- `git diff --check`: pass.
- `./script/build_and_run.sh --verify`: pass; `dist/MdSquare.app` rebuilt and `MdSquare` launched.

### Manual Verification Pending

- Draft recovery after unsaved edit and forced quit.
- Missing file warning after backing `.md` file is moved away.
- External modification warning after another editor changes the same file.
- `Cmd+F`, `Cmd+G`, and `Shift+Cmd+G` behavior inside the editor.
- Outline highlight following editor cursor without forcing editor scroll.
- Status bar count updates while typing.
- Same-folder local image rendering in preview.
- Remote images remaining blocked.
- Paused editor selection syncing preview to active heading.
- 1MB fixture usability while typing.

## GitHub Publication Baseline

Date: 2026-08-15

### Automated Verification

- `npm audit --package-lock-only --audit-level=moderate`: pass; 0 known vulnerabilities after updating `markdown-it` to 14.3.0 and `linkify-it` to 5.0.2.
- `npm run verify:preview`: pass.
- `./script/test.sh`: pass; 121 tests in 27 suites, with preview fixtures verified.
- `node script/measure_core_perf.mjs --budget`: pass; 100KB preview 62.68ms and 1MB preview 506.93ms in the recorded dependency-verification run.
- `git diff --check`: pass.

### Publication Limits

- Latest pane interaction changes still require real-app manual verification.
- The existing local app bundle is ad-hoc signed and is not approved for a GitHub Release.
- Project license and bundled-image redistribution rights must be confirmed before changing the GitHub repository from private to public.
