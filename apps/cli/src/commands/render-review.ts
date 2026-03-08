import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import { getRunArtifactPaths } from "@missless/contracts";
import { buildReviewBundleInRunDir } from "@missless/core";
import { renderReviewHtml } from "@missless/rendering";

function readOptionValue(args: readonly string[], index: number, option: string): string {
  const value = args[index + 1];

  if (value === undefined || value.startsWith("--")) {
    throw new Error(`Missing value for ${option}`);
  }

  return value;
}

export async function runRenderReviewCommand(
  args: readonly string[]
): Promise<number> {
  let runDir: string | undefined;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === "--run-dir") {
      runDir = readOptionValue(args, index, "--run-dir");
      index += 1;
      continue;
    }

    throw new Error(`Unknown option for render-review: ${arg}`);
  }

  if (runDir === undefined) {
    throw new Error("render-review requires --run-dir <dir>");
  }

  const resolvedRunDir = resolve(runDir);
  const artifactPaths = getRunArtifactPaths(resolvedRunDir);
  const reviewBundle = await buildReviewBundleInRunDir(resolvedRunDir);
  const html = renderReviewHtml(reviewBundle);

  await writeFile(artifactPaths.reviewHtml, html, "utf8");

  console.log(`Review package written: ${artifactPaths.reviewHtml}`);

  return 0;
}
