import { fetchNormalizeSource } from "@missless/core";

function readOptionValue(args: readonly string[], index: number, option: string): string {
  const value = args[index + 1];

  if (value === undefined || value.startsWith("--")) {
    throw new Error(`Missing value for ${option}`);
  }

  return value;
}

export async function runFetchNormalizeCommand(
  args: readonly string[]
): Promise<number> {
  let sourceUrl: string | undefined;
  let runsDir: string | undefined;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === "--runs-dir") {
      runsDir = readOptionValue(args, index, "--runs-dir");
      index += 1;
      continue;
    }

    if (arg.startsWith("--")) {
      throw new Error(`Unknown option for fetch-normalize: ${arg}`);
    }

    if (sourceUrl !== undefined) {
      throw new Error(`Unexpected extra argument for fetch-normalize: ${arg}`);
    }

    sourceUrl = arg;
  }

  if (sourceUrl === undefined) {
    throw new Error("fetch-normalize requires a URL argument");
  }

  const result = await fetchNormalizeSource({
    sourceUrl,
    runsDir
  });

  console.log(`Created run directory: ${result.runDir}`);
  console.log(`Canonical text: ${result.artifactPaths.canonicalText}`);
  console.log(`Provider: ${result.provider}`);

  return 0;
}
