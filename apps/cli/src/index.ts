#!/usr/bin/env node

import { RUN_ARTIFACT_FILES } from "@missless/contracts";
import { FIRST_SLICE_RUNTIME_BOUNDARY } from "@missless/core";
import { REVIEW_RENDERING_MODE } from "@missless/rendering";

import { runFetchNormalizeCommand } from "./commands/fetch-normalize.js";
import { runValidateDraftCommand } from "./commands/validate-draft.js";

const COMMANDS = [
  "fetch-normalize",
  "validate-draft",
  "anchor-evidence",
  "render-review"
] as const;

const COMMAND_HANDLERS = {
  "fetch-normalize": runFetchNormalizeCommand,
  "validate-draft": runValidateDraftCommand
} as const;

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

function isImplementedCommand(
  command: string
): command is keyof typeof COMMAND_HANDLERS {
  return command in COMMAND_HANDLERS;
}

async function main(): Promise<number> {
  const command = process.argv[2];

  if (command === undefined || process.argv.includes("--help")) {
    console.log(renderHelp());
    return 0;
  }

  if (!COMMANDS.includes(command as (typeof COMMANDS)[number])) {
    console.error(`Unknown command: ${command}`);
    console.error("");
    console.error(renderHelp());
    return 1;
  }

  if (!isImplementedCommand(command)) {
    console.error(`Command not implemented yet: ${command}`);
    return 1;
  }

  try {
    return await COMMAND_HANDLERS[command](process.argv.slice(3));
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    return 1;
  }
}

process.exit(await main());
