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
  let jsonMode = false;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];

    if (arg === "--run-dir") {
      runDir = readOptionValue(args, index, "--run-dir");
      index += 1;
      continue;
    }

    if (arg === "--json") {
      jsonMode = true;
      continue;
    }

    throw new Error(`Unknown option for validate-draft: ${arg}`);
  }

  if (runDir === undefined) {
    throw new Error("validate-draft requires --run-dir <dir>");
  }

  const result = await validateDraftInRunDir(runDir);

  if (jsonMode) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    console.log(result.summary);
  }

  return result.ok ? 0 : 1;
}
