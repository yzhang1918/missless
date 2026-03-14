import { resolve } from "node:path";

import { getRunArtifactPaths } from "@missless/contracts";
import { createRunId, fetchNormalizeSource } from "@missless/core";

const CLI_FETCH_METHODS = {
  auto: "auto",
  direct: "direct_origin",
  jina: "jina_reader"
} as const;

type CliFetchMethod = keyof typeof CLI_FETCH_METHODS;

function readOptionValue(args: readonly string[], index: number, option: string): string {
  const value = args[index + 1];

  if (value === undefined || value.startsWith("--")) {
    throw new Error(`Missing value for ${option}`);
  }

  return value;
}

function parseFetchMethod(value: string): (typeof CLI_FETCH_METHODS)[CliFetchMethod] {
  if (Object.prototype.hasOwnProperty.call(CLI_FETCH_METHODS, value)) {
    return CLI_FETCH_METHODS[value as CliFetchMethod];
  }

  throw new Error(
    `Unknown value for --fetch-method: ${value}. Expected one of auto, jina, direct.`
  );
}

function buildArtifacts(runDir: string) {
  const artifactPaths = getRunArtifactPaths(runDir);

  return {
    canonical_text: artifactPaths.canonicalText,
    run: artifactPaths.runManifest,
    source: artifactPaths.source
  };
}

export async function runFetchNormalizeCommand(
  args: readonly string[]
): Promise<number> {
  let sourceUrl: string | undefined;
  let runsDir: string | undefined;
  let fetchMethod: ReturnType<typeof parseFetchMethod> = "auto";

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === "--runs-dir") {
      runsDir = readOptionValue(args, index, "--runs-dir");
      index += 1;
      continue;
    }

    if (arg === "--fetch-method") {
      fetchMethod = parseFetchMethod(readOptionValue(args, index, "--fetch-method"));
      index += 1;
      continue;
    }

    if (arg.startsWith("--")) {
      throw new Error(`Unknown option for fetch: ${arg}`);
    }

    if (sourceUrl !== undefined) {
      throw new Error(`Unexpected extra argument for fetch: ${arg}`);
    }

    sourceUrl = arg;
  }

  if (sourceUrl === undefined) {
    throw new Error("fetch requires a URL argument");
  }

  const now = new Date();
  const runId = createRunId(now);
  const plannedRunDir = resolve(runsDir ?? ".local/runs", runId);
  const plannedArtifacts = buildArtifacts(plannedRunDir);

  try {
    const result = await fetchNormalizeSource({
      sourceUrl,
      runsDir,
      fetchMethod,
      now,
      runId
    });

    console.log(
      JSON.stringify(
        {
          ok: true,
          command: "fetch",
          summary: `Fetched source into ${result.runDir} using ${result.sourceArtifact.decision_basis.fetch_method}.`,
          run_dir: result.runDir,
          artifacts: buildArtifacts(result.runDir),
          source: result.sourceArtifact,
          ready_for: [
            "read_canonical_text",
            "write_extraction_draft",
            "validate"
          ]
        },
        null,
        2
      )
    );

    return 0;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);

    console.log(
      JSON.stringify(
        {
          ok: false,
          command: "fetch",
          summary: message,
          run_dir: plannedRunDir,
          artifacts: plannedArtifacts,
          source: {
            requested: {
              url: sourceUrl,
              fetch_method: fetchMethod
            }
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
