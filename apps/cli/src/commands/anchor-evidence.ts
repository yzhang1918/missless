import { getRunArtifactPaths } from "@missless/contracts";
import { anchorEvidenceInRunDir } from "@missless/core";

function readOptionValue(args: readonly string[], index: number, option: string): string {
  const value = args[index + 1];

  if (value === undefined || value.startsWith("--")) {
    throw new Error(`Missing value for ${option}`);
  }

  return value;
}

export async function runAnchorEvidenceCommand(
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

    if (arg === "--json") {
      continue;
    }

    throw new Error(`Unknown option for anchor: ${arg}`);
  }

  if (runDir === undefined) {
    throw new Error("anchor requires --run-dir <dir>");
  }

  const result = await anchorEvidenceInRunDir(runDir);
  const artifactPaths = getRunArtifactPaths(result.run_dir);
  console.log(
    JSON.stringify(
      {
        ok: result.ok,
        command: "anchor",
        summary: result.summary,
        run_dir: result.run_dir,
        artifacts: {
          run: artifactPaths.runManifest,
          source: artifactPaths.source,
          canonical_text: artifactPaths.canonicalText,
          extraction_draft: artifactPaths.extractionDraft,
          evidence_result: artifactPaths.evidenceResult
        },
        diagnostics: result.diagnostics,
        draft_sha256: result.draft_sha256,
        canonical_text_sha256: result.canonical_text_sha256,
        atom_count: result.atoms.length
      },
      null,
      2
    )
  );

  return result.ok ? 0 : 1;
}
