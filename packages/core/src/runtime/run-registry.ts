import { createHash } from "node:crypto";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, resolve } from "node:path";

export const RUN_REGISTRY_FILE = ".missless-run-registry.json";
const RUNTIME_STATE_ROOT = resolve(homedir(), ".missless", "runtime");

interface RunRegistry {
  readonly version: 1;
  readonly run_dirs: readonly string[];
}

interface RunAttestation {
  readonly version: 1;
  readonly run_dir: string;
}

function isRunRegistry(value: unknown): value is RunRegistry {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const record = value as Record<string, unknown>;

  return (
    record.version === 1 &&
    Array.isArray(record.run_dirs) &&
    record.run_dirs.every((entry: unknown) => typeof entry === "string")
  );
}

function isRunAttestation(value: unknown): value is RunAttestation {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const record = value as Record<string, unknown>;

  return record.version === 1 && typeof record.run_dir === "string";
}

function hashPath(path: string): string {
  return createHash("sha256").update(path, "utf8").digest("hex");
}

export function getRunRegistryPath(runDir: string): string {
  const resolvedRunsRoot = resolve(dirname(runDir));
  const runsRootHash = hashPath(resolvedRunsRoot);

  return resolve(RUNTIME_STATE_ROOT, "run-registries", runsRootHash, RUN_REGISTRY_FILE);
}

export function getRunAttestationPath(runDir: string): string {
  const resolvedRunDir = resolve(runDir);

  return resolve(
    RUNTIME_STATE_ROOT,
    "run-attestations",
    `${hashPath(resolvedRunDir)}.json`
  );
}

async function readRunRegistry(runDir: string): Promise<RunRegistry> {
  const registryPath = getRunRegistryPath(runDir);

  try {
    const text = await readFile(registryPath, "utf8");
    const parsed = JSON.parse(text) as unknown;

    if (isRunRegistry(parsed)) {
      return parsed;
    }
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
    ) {
      return {
        version: 1,
        run_dirs: []
      };
    }

    if (error instanceof SyntaxError) {
      return {
        version: 1,
        run_dirs: []
      };
    }

    throw error;
  }

  return {
    version: 1,
    run_dirs: []
  };
}

async function writeRunRegistry(
  runDir: string,
  registry: RunRegistry
): Promise<void> {
  await mkdir(dirname(getRunRegistryPath(runDir)), {
    recursive: true,
    mode: 0o700
  });
  await writeFile(
    getRunRegistryPath(runDir),
    JSON.stringify(registry, null, 2) + "\n",
    "utf8"
  );
}

async function readRunAttestation(
  runDir: string
): Promise<RunAttestation | null> {
  try {
    const text = await readFile(getRunAttestationPath(runDir), "utf8");
    const parsed = JSON.parse(text) as unknown;

    if (isRunAttestation(parsed)) {
      return parsed;
    }
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
    ) {
      return null;
    }

    if (error instanceof SyntaxError) {
      return null;
    }

    throw error;
  }

  return null;
}

async function writeRunAttestation(runDir: string): Promise<void> {
  await mkdir(dirname(getRunAttestationPath(runDir)), {
    recursive: true,
    mode: 0o700
  });
  await writeFile(
    getRunAttestationPath(runDir),
    JSON.stringify(
      {
        version: 1,
        run_dir: resolve(runDir)
      },
      null,
      2
    ) + "\n",
    "utf8"
  );
}

export async function registerRunDir(runDir: string): Promise<void> {
  const resolvedRunDir = resolve(runDir);
  const registry = await readRunRegistry(resolvedRunDir);
  const nextRunDirs = Array.from(
    new Set([...registry.run_dirs, resolvedRunDir])
  ).sort();

  await writeRunAttestation(resolvedRunDir);
  await writeRunRegistry(resolvedRunDir, {
    version: 1,
    run_dirs: nextRunDirs
  });
}

export async function unregisterRunDir(runDir: string): Promise<void> {
  const resolvedRunDir = resolve(runDir);
  const registry = await readRunRegistry(resolvedRunDir);
  const nextRunDirs = registry.run_dirs.filter(
    (value) => value !== resolvedRunDir
  );
  await rm(getRunAttestationPath(resolvedRunDir), { force: true });

  if (nextRunDirs.length === 0) {
    await rm(getRunRegistryPath(resolvedRunDir), { force: true });
    return;
  }

  await writeRunRegistry(resolvedRunDir, {
    version: 1,
    run_dirs: nextRunDirs
  });
}

export async function isRegisteredRunDir(runDir: string): Promise<boolean> {
  const resolvedRunDir = resolve(runDir);
  const attestation = await readRunAttestation(resolvedRunDir);

  if (attestation?.run_dir === resolvedRunDir) {
    return true;
  }

  const registry = await readRunRegistry(resolvedRunDir);

  return registry.run_dirs.includes(resolvedRunDir);
}
