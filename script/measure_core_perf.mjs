import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { performance } from "node:perf_hooks";
import { fileURLToPath } from "node:url";
import vm from "node:vm";
import MarkdownIt from "markdown-it";
import { parseHTML } from "linkedom";

const root = path.resolve(fileURLToPath(new URL("..", import.meta.url)));
const fixtureDir = path.join(root, "tmp/perf-fixtures");
const rendererPath = path.join(root, "Sources/MarkdownDev/Resources/Preview/preview-renderer.js");
const rendererSource = fs.readFileSync(rendererPath, "utf8");
const enforceBudget = process.argv.includes("--budget");
const budgets = {
  "100kb.md": 250,
  "1mb.md": 1500
};

function ensureFixtures() {
  const result = spawnSync(process.execPath, [path.join(root, "script/create_perf_fixtures.mjs")], {
    cwd: root,
    encoding: "utf8"
  });

  if (result.status !== 0) {
    process.stderr.write(result.stderr || result.stdout);
    throw new Error("failed to create performance fixtures");
  }
}

function createPreviewWindow() {
  const { window } = parseHTML("<!doctype html><html><body></body></html>");
  window.markdownit = MarkdownIt;
  window.console = console;

  const context = vm.createContext(window);
  vm.runInContext(rendererSource, context, { filename: rendererPath });

  return window;
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function measureFixture(name) {
  const markdown = fs.readFileSync(path.join(fixtureDir, name), "utf8");
  const previewWindow = createPreviewWindow();
  const start = performance.now();
  const html = previewWindow.MarkdownDevPreview.render(markdown, []);
  const elapsed = performance.now() - start;
  const document = previewWindow.document;

  assert(html.length > 0, `${name} should render non-empty preview HTML`);
  assert(document.querySelectorAll("h1, h2, h3, h4, h5, h6").length > 0, `${name} should render headings`);
  assert(document.querySelectorAll("table").length > 0, `${name} should render tables`);
  assert(document.querySelectorAll("input[type='checkbox'][disabled]").length > 0, `${name} should render disabled task checkboxes`);

  return {
    bytes: Buffer.byteLength(markdown, "utf8"),
    elapsed,
    headings: document.querySelectorAll("h1, h2, h3, h4, h5, h6").length
  };
}

ensureFixtures();

for (const name of ["100kb.md", "1mb.md"]) {
  const result = measureFixture(name);
  if (enforceBudget && result.elapsed > budgets[name]) {
    throw new Error(`Preview render ${name} exceeded budget: ${result.elapsed.toFixed(2)}ms > ${budgets[name]}ms`);
  }

  console.log(
    `Preview render ${name}: ${result.elapsed.toFixed(2)}ms, bytes=${result.bytes}, headings=${result.headings}`
  );
}
