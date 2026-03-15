#!/usr/bin/env node

import { DECISION_LABELS, RUN_ARTIFACT_FILES } from "@missless/contracts";
import { REVIEW_RENDERING_MODE } from "@missless/rendering";

import { runAnchorEvidenceCommand } from "./commands/anchor-evidence.js";
import { runFetchNormalizeCommand } from "./commands/fetch-normalize.js";
import { runPrintDraftContractCommand } from "./commands/print-draft-contract.js";
import { runRenderReviewCommand } from "./commands/render-review.js";
import { runValidateDraftCommand } from "./commands/validate-draft.js";

const COMMANDS = [
  {
    name: "fetch",
    description: "Create a run directory and canonical text from one public URL."
  },
  {
    name: "print-draft-contract",
    description: "Print the runtime-owned extraction_draft.json contract."
  },
  {
    name: "validate",
    description: "Validate an agent-authored extraction draft in a run directory."
  },
  {
    name: "anchor",
    description: "Validate and materialize evidence from extraction selectors."
  },
  {
    name: "review",
    description: "Render a read-only HTML review package from run artifacts."
  }
] as const;

const COMMAND_HANDLERS = {
  anchor: runAnchorEvidenceCommand,
  fetch: runFetchNormalizeCommand,
  "print-draft-contract": runPrintDraftContractCommand,
  review: runRenderReviewCommand,
  validate: runValidateDraftCommand
} as const;

function renderHelp(): string {
  return [
    "missless",
    "",
    "Stable runtime command for the first review-package slice.",
    "",
    "Usage:",
    "- missless <command>",
    "",
    "Commands:",
    ...COMMANDS.map((command) => `- ${command.name}: ${command.description}`),
    "",
    "Runtime contract:",
    "- stable entrypoint: missless",
    "- run handle: run_dir",
    `- agent-authored draft: ${RUN_ARTIFACT_FILES.extractionDraft}`,
    `- derived artifacts: ${RUN_ARTIFACT_FILES.evidenceResult}, ${RUN_ARTIFACT_FILES.reviewBundle}, ${RUN_ARTIFACT_FILES.reviewHtml}`,
    `- decision labels: ${DECISION_LABELS.join(", ")}`,
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

  if (!COMMANDS.some((candidate) => candidate.name === command)) {
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
