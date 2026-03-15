#!/usr/bin/env node

import { copyFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import { build } from "esbuild";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const cliDir = resolve(scriptDir, "..");
const repoRoot = resolve(cliDir, "../..");
const entryPoint = resolve(cliDir, "src/index.ts");
const outputFile = resolve(cliDir, "dist/index.js");
const schemaSource = resolve(
  repoRoot,
  "packages/contracts/extraction-draft.schema.json"
);
const schemaTarget = resolve(cliDir, "extraction-draft.schema.json");

await build({
  entryPoints: [entryPoint],
  outfile: outputFile,
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node22",
  sourcemap: true,
  external: [
    "@mozilla/readability",
    "jsdom",
    "node-html-markdown"
  ],
  // Bundle workspace packages while keeping third-party runtime resolution unchanged.
  alias: {
    "@missless/contracts": resolve(repoRoot, "packages/contracts/src/index.ts"),
    "@missless/core": resolve(repoRoot, "packages/core/src/index.ts"),
    "@missless/rendering": resolve(repoRoot, "packages/rendering/src/index.ts")
  }
});

await copyFile(schemaSource, schemaTarget);
