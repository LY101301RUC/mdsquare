import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(fileURLToPath(new URL("..", import.meta.url)));
const outDir = resolve(root, "tmp/perf-fixtures");
await mkdir(outDir, { recursive: true });

function makeMarkdown(targetBytes) {
  let text = "# Performance Fixture\n\n";
  let section = 1;
  while (Buffer.byteLength(text, "utf8") < targetBytes) {
    text += `## Section ${section}\n\n`;
    text += "- [ ] Task\n- [x] Done\n\n";
    text += "| A | B |\n| - | - |\n| 1 | 2 |\n\n";
    text += "Paragraph text for measuring load and outline extraction.\n\n";
    section += 1;
  }
  return text;
}

await writeFile(resolve(outDir, "100kb.md"), makeMarkdown(100 * 1024));
await writeFile(resolve(outDir, "1mb.md"), makeMarkdown(1024 * 1024));
console.log(outDir);
