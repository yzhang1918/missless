import { rename, rm, writeFile } from "node:fs/promises";
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

    throw new Error(`Unknown option for review: ${arg}`);
  }

  if (runDir === undefined) {
    throw new Error("review requires --run-dir <dir>");
  }

  const resolvedRunDir = resolve(runDir);
  const artifactPaths = getRunArtifactPaths(resolvedRunDir);
  try {
    const reviewBundle = await buildReviewBundleInRunDir(resolvedRunDir);
    const html = renderReviewHtml(reviewBundle);
    const reviewHtmlTemp = `${artifactPaths.reviewHtml}.tmp`;

    await writeFile(reviewHtmlTemp, html, "utf8");
    await rename(reviewHtmlTemp, artifactPaths.reviewHtml);
    console.log(
      JSON.stringify(
        {
          ok: true,
          command: "review",
          summary: `Review package written to ${artifactPaths.reviewHtml}.`,
          run_dir: resolvedRunDir,
          artifacts: {
            run: artifactPaths.runManifest,
            source: artifactPaths.source,
            canonical_text: artifactPaths.canonicalText,
            extraction_draft: artifactPaths.extractionDraft,
            evidence_result: artifactPaths.evidenceResult,
            review_bundle: artifactPaths.reviewBundle,
            review_html: artifactPaths.reviewHtml
          },
          review_bundle: artifactPaths.reviewBundle,
          review_html: artifactPaths.reviewHtml,
          ready_for: ["inspect_review_html", "report_result"]
        },
        null,
        2
      )
    );
    return 0;
  } catch (error) {
    await rm(`${artifactPaths.reviewHtml}.tmp`, { force: true });
    console.log(
      JSON.stringify(
        {
          ok: false,
          command: "review",
          summary: error instanceof Error ? error.message : String(error),
          run_dir: resolvedRunDir,
          artifacts: {
            run: artifactPaths.runManifest,
            source: artifactPaths.source,
            canonical_text: artifactPaths.canonicalText,
            extraction_draft: artifactPaths.extractionDraft,
            evidence_result: artifactPaths.evidenceResult,
            review_bundle: artifactPaths.reviewBundle,
            review_html: artifactPaths.reviewHtml
          },
          ready_for: []
        },
        null,
        2
      )
    );
    return 1;
  }
}
