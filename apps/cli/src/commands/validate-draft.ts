import { validateDraftInRunDir } from "@missless/core";

function readOptionValue(args: readonly string[], index: number, option: string): string {
  const value = args[index + 1];

  if (value === undefined || value.startsWith("--")) {
    throw new Error(`Missing value for ${option}`);
  }

  return value;
}

export async function runValidateDraftCommand(
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

    throw new Error(`Unknown option for validate: ${arg}`);
  }

  if (runDir === undefined) {
    throw new Error("validate requires --run-dir <dir>");
  }

  const result = await validateDraftInRunDir(runDir);
  console.log(
    JSON.stringify(
      {
        ok: result.ok,
        command: "validate",
        summary: result.summary,
        run_dir: result.runDir,
        artifacts: {
          run: result.artifacts.runManifest,
          source: result.artifacts.source,
          canonical_text: result.artifacts.canonicalText,
          extraction_draft: result.artifacts.extractionDraft
        },
        diagnostics: result.diagnostics,
        decision: result.decision,
        atom_count: result.atomCount
      },
      null,
      2
    )
  );

  return result.ok ? 0 : 1;
}
