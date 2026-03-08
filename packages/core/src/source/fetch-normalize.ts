import { createHash, randomUUID } from "node:crypto";
import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import { getRunArtifactPaths, type RunArtifactPaths } from "@missless/contracts";

import { createJinaReaderProvider } from "../providers/jina.js";
import type { SourceProvider } from "../providers/provider.js";

export interface RunManifest {
  readonly run_id: string;
  readonly created_at: string;
  readonly stage: "normalized";
  readonly source_kind: "url";
  readonly source_url: string;
}

export interface SourceArtifact {
  readonly source_url: string;
  readonly provider: string;
  readonly provider_url: string;
  readonly fetched_at: string;
  readonly provider_response_status: number;
  readonly response_headers: Readonly<Record<string, string>>;
  readonly content_type: "text/markdown";
  readonly normalized_text_sha256: string;
}

export interface FetchNormalizeInput {
  readonly sourceUrl: string;
  readonly runsDir?: string;
  readonly provider?: SourceProvider;
  readonly now?: Date;
  readonly runId?: string;
}

export interface FetchNormalizeResult {
  readonly runId: string;
  readonly runDir: string;
  readonly artifactPaths: RunArtifactPaths;
  readonly canonicalText: string;
  readonly runManifest: RunManifest;
  readonly sourceArtifact: SourceArtifact;
  readonly provider: string;
}

function writeJsonFile(path: string, value: unknown): Promise<void> {
  return writeFile(path, JSON.stringify(value, null, 2) + "\n", "utf8");
}

function sha256(input: string): string {
  return createHash("sha256").update(input, "utf8").digest("hex");
}

function assertHttpUrl(sourceUrl: string): void {
  const parsed = new URL(sourceUrl);

  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new Error("fetch-normalize only supports http and https URLs");
  }
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
  assertHttpUrl(input.sourceUrl);

  const provider = input.provider ?? createJinaReaderProvider();
  const runsDir = resolve(input.runsDir ?? ".local/runs");
  const now = input.now ?? new Date();
  const runId = input.runId ?? createRunId(now);
  const runDir = resolve(runsDir, runId);
  const artifactPaths = getRunArtifactPaths(runDir);

  await mkdir(runDir, { recursive: false });

  const fetched = await provider.fetch(input.sourceUrl);
  const normalizedTextHash = sha256(fetched.canonicalText);
  const runManifest: RunManifest = {
    run_id: runId,
    created_at: now.toISOString(),
    stage: "normalized",
    source_kind: "url",
    source_url: input.sourceUrl
  };
  const sourceArtifact: SourceArtifact = {
    source_url: input.sourceUrl,
    provider: provider.name,
    provider_url: fetched.providerUrl,
    fetched_at: fetched.fetchedAt,
    provider_response_status: fetched.responseStatus,
    response_headers: fetched.responseHeaders,
    content_type: "text/markdown",
    normalized_text_sha256: normalizedTextHash
  };

  await Promise.all([
    writeJsonFile(artifactPaths.runManifest, runManifest),
    writeJsonFile(artifactPaths.source, sourceArtifact),
    writeFile(artifactPaths.canonicalText, fetched.canonicalText, "utf8")
  ]);

  return {
    runId,
    runDir,
    artifactPaths,
    canonicalText: fetched.canonicalText,
    runManifest,
    sourceArtifact,
    provider: provider.name
  };
}
