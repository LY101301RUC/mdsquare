import fs from "node:fs/promises";
import path from "node:path";

const root = process.cwd();
const source = path.join(root, "node_modules/markdown-it/dist/markdown-it.min.js");
const destination = path.join(
  root,
  "Sources/MarkdownDev/Resources/Preview/vendor/markdown-it.min.js"
);

await fs.mkdir(path.dirname(destination), { recursive: true });
await fs.copyFile(source, destination);

console.log(`vendored ${path.relative(root, destination)}`);
