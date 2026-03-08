#!/usr/bin/env node

import { RUN_ARTIFACT_FILES } from "@missless/contracts";
import { FIRST_SLICE_RUNTIME_BOUNDARY } from "@missless/core";
import { REVIEW_RENDERING_MODE } from "@missless/rendering";

const COMMANDS = [
  "fetch-normalize",
  "validate-draft",
  "anchor-evidence",
  "render-review"
] as const;

function renderHelp(): string {
  return [
    "missless CLI (bootstrap)",
    "",
    "Planned commands:",
    ...COMMANDS.map((command) => `- ${command}`),
    "",
    `Run directory artifacts start with: ${RUN_ARTIFACT_FILES.runManifest}, ${RUN_ARTIFACT_FILES.source}, ${RUN_ARTIFACT_FILES.canonicalText}`,
    `Extractor boundary: ${FIRST_SLICE_RUNTIME_BOUNDARY.extractor}`,
    `Review rendering mode: ${REVIEW_RENDERING_MODE}`
  ].join("\n");
}

const command = process.argv[2];

if (command === undefined || process.argv.includes("--help")) {
  console.log(renderHelp());
  process.exit(0);
}

if (!COMMANDS.includes(command as (typeof COMMANDS)[number])) {
  console.error(`Unknown command: ${command}`);
  console.error("");
  console.error(renderHelp());
  process.exit(1);
}

console.error(`Command not implemented yet: ${command}`);
process.exit(1);
