import {
  createHmac,
  randomBytes,
  timingSafeEqual
} from "node:crypto";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, resolve } from "node:path";

export const CLEANUP_TOKEN_FILE = ".missless-cleanup-token.json";

const RUNTIME_STATE_ROOT = resolve(homedir(), ".missless", "runtime");
const CLEANUP_SECRET_PATH = resolve(RUNTIME_STATE_ROOT, "cleanup-secret.txt");

interface CleanupToken {
  readonly version: 1;
  readonly run_dir: string;
  readonly signature: string;
}

function isCleanupToken(value: unknown): value is CleanupToken {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const record = value as Record<string, unknown>;

  return (
    record.version === 1 &&
    typeof record.run_dir === "string" &&
    typeof record.signature === "string"
  );
}

function signRunDir(runDir: string, secret: string): string {
  return createHmac("sha256", secret).update(resolve(runDir), "utf8").digest("hex");
}

async function readCleanupSecret(): Promise<string | null> {
  try {
    const secret = (await readFile(CLEANUP_SECRET_PATH, "utf8")).trim();
    return secret === "" ? null : secret;
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
    ) {
      return null;
    }

    throw error;
  }
}

async function readOrCreateCleanupSecret(): Promise<string> {
  const existing = await readCleanupSecret();

  if (existing !== null) {
    return existing;
  }

  await mkdir(dirname(CLEANUP_SECRET_PATH), {
    recursive: true,
    mode: 0o700
  });
  const generated = randomBytes(32).toString("hex");

  try {
    await writeFile(CLEANUP_SECRET_PATH, `${generated}\n`, {
      encoding: "utf8",
      flag: "wx",
      mode: 0o600
    });
    return generated;
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      error.code === "EEXIST"
    ) {
      const created = await readCleanupSecret();

      if (created !== null) {
        return created;
      }
    }

    throw error;
  }
}

export function getCleanupTokenPath(runDir: string): string {
  return resolve(runDir, CLEANUP_TOKEN_FILE);
}

export async function writeCleanupToken(runDir: string): Promise<void> {
  const resolvedRunDir = resolve(runDir);
  const secret = await readOrCreateCleanupSecret();
  const payload: CleanupToken = {
    version: 1,
    run_dir: resolvedRunDir,
    signature: signRunDir(resolvedRunDir, secret)
  };

  await writeFile(
    getCleanupTokenPath(resolvedRunDir),
    JSON.stringify(payload, null, 2) + "\n",
    "utf8"
  );
}

export async function hasValidCleanupToken(runDir: string): Promise<boolean> {
  try {
    const [tokenText, secret] = await Promise.all([
      readFile(getCleanupTokenPath(runDir), "utf8"),
      readCleanupSecret()
    ]);

    if (secret === null) {
      return false;
    }

    const parsed = JSON.parse(tokenText) as unknown;

    if (!isCleanupToken(parsed)) {
      return false;
    }

    const resolvedRunDir = resolve(runDir);

    if (parsed.run_dir !== resolvedRunDir) {
      return false;
    }

    const actual = Buffer.from(parsed.signature, "utf8");
    const expected = Buffer.from(signRunDir(resolvedRunDir, secret), "utf8");

    if (actual.length !== expected.length) {
      return false;
    }

    return timingSafeEqual(actual, expected);
  } catch (error) {
    if (
      error instanceof SyntaxError ||
      (error instanceof Error &&
        "code" in error &&
        error.code === "ENOENT")
    ) {
      return false;
    }

    throw error;
  }
}
