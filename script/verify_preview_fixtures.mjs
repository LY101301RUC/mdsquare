import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import MarkdownIt from "markdown-it";
import { parseHTML } from "linkedom";

const root = process.cwd();
const rendererPath = path.join(root, "Sources/MarkdownDev/Resources/Preview/preview-renderer.js");
const rendererSource = fs.readFileSync(rendererPath, "utf8");

function fixture(name) {
  return fs.readFileSync(path.join(root, "Tests/MarkdownDevTests/Fixtures", `${name}.md`), "utf8");
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

const taskWindow = createPreviewWindow();
taskWindow.MarkdownDevPreview.render(fixture("task-list"), [
  { slug: "tasks", level: 1 }
]);
const taskHTML = taskWindow.document.body.innerHTML;
assert(taskHTML.includes("type=\"checkbox\""), "task list should render checkbox markup");
assert(taskHTML.includes("disabled"), "task checkboxes should be disabled");
assert(taskHTML.includes("checked"), "checked task should keep checked state");

const tableWindow = createPreviewWindow();
tableWindow.MarkdownDevPreview.render(fixture("table"), [
  { slug: "table", level: 1 }
]);
const tableHTML = tableWindow.document.body.innerHTML;
assert(tableHTML.includes("<table>"), "table fixture should render a table");

const setextWindow = createPreviewWindow();
setextWindow.MarkdownDevPreview.render(fixture("setext-headings"), [
  { slug: "title-one", level: 1 },
  { slug: "title-two", level: 2 }
]);
const setextHTML = setextWindow.document.body.innerHTML;
assert(setextHTML.includes("<h1"), "setext fixture should render h1");
assert(setextHTML.includes("<h2"), "setext fixture should render h2");

const unsafeWindow = createPreviewWindow();
unsafeWindow.MarkdownDevPreview.render(fixture("unsafe-html"), [
  { slug: "unsafe", level: 1 }
]);
const unsafeHTML = unsafeWindow.document.body.innerHTML;
assert(!unsafeHTML.includes("<script"), "raw script HTML should not enter the DOM");
assert(!unsafeHTML.includes("<img"), "markdown images should not render img elements");
assert(unsafeHTML.includes("data-blocked-image"), "blocked images should be marked");
assert(
  (unsafeHTML.match(/data-blocked-image/g) || []).length === 2,
  "each markdown image should be marked as blocked"
);
const unsafeAnchors = [...unsafeWindow.document.querySelectorAll("a")];
assert(
  unsafeAnchors.some((anchor) => anchor.hasAttribute("data-blocked-link")),
  "blocked links should be marked"
);
for (const anchor of unsafeAnchors) {
  const href = anchor.getAttribute("href");
  assert(!href || /^(https?|mailto):/i.test(href), "anchors should not keep unsafe href attributes");
}
assert(!unsafeHTML.includes("src="), "blocked image URLs should not appear as src attributes");
assert(
  unsafeWindow.document.querySelectorAll("[src]").length === 0,
  "rendered unsafe fixture should not contain src attributes"
);

const imageWindow = createPreviewWindow();
imageWindow.MarkdownDevPreview.render("![Local](local.png)\n\n![Remote](https://example.com/x.png)", [], {
  "local.png": "data:image/png;base64,iVBORw0KGgo="
});
assert(imageWindow.document.querySelectorAll("img").length === 1, "allowed local image should render one img");
assert(
  imageWindow.document.querySelectorAll("[data-blocked-image]").length === 1,
  "remote image should remain blocked"
);
assert(
  !imageWindow.document.body.innerHTML.includes("https://example.com/x.png"),
  "blocked remote image URL should not be retained in rendered HTML"
);

const colorWindow = createPreviewWindow();
colorWindow.MarkdownDevPreview.render(
  '<span style="color: red">Red text</span>\n\n<span style="color: green">Green text</span>',
  [],
  {}
);
const redSpan = colorWindow.document.querySelector('[data-mdsquare-color="red"]');
assert(redSpan, "safe red color span should render");
assert(redSpan.textContent === "Red text", "safe red color span should keep text content");
assert(
  colorWindow.document.querySelector('[data-mdsquare-color="green"]') === null,
  "unsupported color span should remain inert"
);
assert(
  colorWindow.document.body.textContent.includes('<span style="color: green">Green text</span>'),
  "unsupported color markup should remain visible as text"
);

const codeWindow = createPreviewWindow();
codeWindow.MarkdownDevPreview.render(
  [
    "# Code",
    "",
    "`href=\"javascript:alert(1)\"`",
    "",
    "```html",
    "<a href=\"javascript:alert(1)\">bad link</a>",
    "```"
  ].join("\n"),
  [{ slug: "code", level: 1 }]
);
const codeText = codeWindow.document.body.textContent;
assert(
  codeText.includes("href=\"javascript:alert(1)\""),
  "inline code and code blocks should preserve inert javascript href text"
);

console.log("preview fixtures verified");
