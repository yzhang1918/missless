import { createHash, randomUUID } from "node:crypto";
import { mkdir, rm, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import { getRunArtifactPaths, type RunArtifactPaths } from "@missless/contracts";

import {
  createSourceProviderForMethod,
  type ConcreteFetchMethod,
  type FetchMethod
} from "../providers/default.js";
import type {
  FetchLike,
  SourceProvider
} from "../providers/provider.js";
import { writeCleanupToken } from "../runtime/cleanup-token.js";
import {
  registerRunDir,
  unregisterRunDir
} from "../runtime/run-registry.js";
import {
  assertSafeHttpUrl,
  defaultHostResolver,
  resolveSafeRedirectChain,
  type HostResolver
} from "./url-safety.js";

const SAFE_RUN_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]*$/u;

export interface RunManifest {
  readonly run_id: string;
  readonly created_at: string;
  readonly stage: "normalized";
  readonly source_kind: "url";
  readonly source_url: string;
}

export interface SourceArtifact {
  readonly requested: {
    readonly url: string;
    readonly fetch_method: FetchMethod;
  };
  readonly decision_basis: {
    readonly url: string;
    readonly fetch_method: ConcreteFetchMethod;
    readonly snapshot_sha256: string;
  };
  readonly fetched_at: string;
}

export interface FetchNormalizeInput {
  readonly sourceUrl: string;
  readonly runsDir?: string;
  readonly fetchMethod?: FetchMethod;
  readonly provider?: SourceProvider;
  readonly now?: Date;
  readonly runId?: string;
  readonly hostResolver?: HostResolver;
  readonly fetchImpl?: FetchLike;
  readonly cleanupTokenWriter?: (runDir: string) => Promise<void>;
}

export interface FetchNormalizeResult {
  readonly runId: string;
  readonly runDir: string;
  readonly artifactPaths: RunArtifactPaths;
  readonly canonicalText: string;
  readonly runManifest: RunManifest;
  readonly sourceArtifact: SourceArtifact;
  readonly provider: ConcreteFetchMethod;
}

function writeJsonFile(path: string, value: unknown): Promise<void> {
  return writeFile(path, JSON.stringify(value, null, 2) + "\n", "utf8");
}

function sha256(input: string): string {
  return createHash("sha256").update(input, "utf8").digest("hex");
}

function assertSafeRunId(runId: string): void {
  if (!SAFE_RUN_ID_PATTERN.test(runId)) {
    throw new Error("fetch rejects run IDs with path separators or unsafe segments");
  }
}

function assertChosenFetchMethod(providerName: string): ConcreteFetchMethod {
  if (providerName === "jina_reader" || providerName === "direct_origin") {
    return providerName;
  }

  throw new Error(
    `fetch received an unsupported provider result for durable provenance: ${providerName}`
  );
}

export function createRunId(now = new Date()): string {
  const timestamp = now
    .toISOString()
    .replace(/[-:]/gu, "")
    .replace(/\.\d{3}Z$/u, "Z");

  return `run-${timestamp}-${randomUUID().slice(0, 8)}`;
}

export async function fetchNormalizeSource(
  input: FetchNormalizeInput
): Promise<FetchNormalizeResult> {
  const now = input.now ?? new Date();
  const runId = input.runId ?? createRunId(now);
  const requestedFetchMethod = input.fetchMethod ?? "auto";
  assertSafeRunId(runId);
  const hostResolver = input.hostResolver ?? defaultHostResolver;
  const fetchImpl = input.fetchImpl ?? globalThis.fetch;
  await assertSafeHttpUrl(input.sourceUrl, hostResolver);
  const redirectResolution = await resolveSafeRedirectChain(input.sourceUrl, {
    fetchImpl,
    hostResolver
  });
  const provider =
    input.provider ?? createSourceProviderForMethod(requestedFetchMethod);
  const cleanupTokenWriter = input.cleanupTokenWriter ?? writeCleanupToken;
  const runsDir = resolve(input.runsDir ?? ".local/runs");
  const runDir = resolve(runsDir, runId);
  const artifactPaths = getRunArtifactPaths(runDir);

  await mkdir(runsDir, { recursive: true });

  const fetched = await provider.fetch(input.sourceUrl, {
    fetchImpl,
    assertSafeUrl: async (url) => assertSafeHttpUrl(url, hostResolver)
  });
  const resolvedSourceUrl =
    fetched.resolvedSourceUrl === input.sourceUrl
      ? redirectResolution.finalUrl
      : fetched.resolvedSourceUrl;
  const normalizedTextHash = sha256(fetched.canonicalText);
  const chosenFetchMethod = assertChosenFetchMethod(fetched.providerName);
  const runManifest: RunManifest = {
    run_id: runId,
    created_at: now.toISOString(),
    stage: "normalized",
    source_kind: "url",
    source_url: input.sourceUrl
  };
  const sourceArtifact: SourceArtifact = {
    requested: {
      url: input.sourceUrl,
      fetch_method: requestedFetchMethod
    },
    decision_basis: {
      url: resolvedSourceUrl,
      fetch_method: chosenFetchMethod,
      snapshot_sha256: normalizedTextHash
    },
    fetched_at: fetched.fetchedAt
  };

  await mkdir(runDir, { recursive: false });

  try {
    await Promise.all([
      writeJsonFile(artifactPaths.runManifest, runManifest),
      writeJsonFile(artifactPaths.source, sourceArtifact),
      writeFile(artifactPaths.canonicalText, fetched.canonicalText, "utf8")
    ]);
    await registerRunDir(runDir);
    await cleanupTokenWriter(runDir);
  } catch (error) {
    await Promise.allSettled([
      unregisterRunDir(runDir),
      rm(runDir, { recursive: true, force: true })
    ]);
    throw error;
  }

  return {
    runId,
    runDir,
    artifactPaths,
    canonicalText: fetched.canonicalText,
    runManifest,
    sourceArtifact,
    provider: chosenFetchMethod
  };
}
