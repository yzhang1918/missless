import assert from "node:assert/strict";
import { mkdtemp, readFile, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { fetchNormalizeSource } from "../../../packages/core/src/index.ts";
import { getCleanupTokenPath } from "../../../packages/core/src/runtime/cleanup-token.ts";
import {
  getRunAttestationPath,
  getRunRegistryPath
} from "../../../packages/core/src/runtime/run-registry.ts";

const publicHostResolver = async () =>
  [
    {
      address: "93.184.216.34",
      family: 4 as const
    }
  ] satisfies readonly { address: string; family: 4 | 6 }[];

async function readRegistryRunDirs(runDir: string): Promise<readonly string[]> {
  try {
    const text = await readFile(getRunRegistryPath(runDir), "utf8");
    const parsed = JSON.parse(text) as { run_dirs?: unknown };

    return Array.isArray(parsed.run_dirs)
      ? parsed.run_dirs.filter((value): value is string => typeof value === "string")
      : [];
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
    ) {
      return [];
    }

    throw error;
  }
}

test("fetchNormalizeSource rejects source URLs with embedded credentials", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://user:pass@example.com/private",
        runsDir
      }),
    /embedded credentials/
  );
});

test("fetchNormalizeSource rejects localhost and private IPv4 hosts", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://127.0.0.1/private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://localhost/private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://localhost./private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://foo.localhost./private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );
});

test("fetchNormalizeSource rejects loopback IPv6 hosts", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://[::1]/private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );
});

test("fetchNormalizeSource rejects IPv4-mapped IPv6 loopback hosts", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://[::ffff:127.0.0.1]/private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );
});

test("fetchNormalizeSource rejects hostnames that resolve to loopback or private addresses", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://localtest.me/article",
        runsDir,
        hostResolver: async () => [
          {
            address: "127.0.0.1",
            family: 4
          }
        ]
      }),
    /resolve to localhost, private, or link-local addresses/
  );
});

test("fetchNormalizeSource creates missing parent directories for runsDir", async () => {
  const tempRoot = await mkdtemp(join(tmpdir(), "missless-fetch-runs-"));
  const runsDir = join(tempRoot, "nested", "runs");
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/article",
    runsDir,
    runId: "run-test",
    now: new Date("2026-03-09T00:00:00.000Z"),
    hostResolver: publicHostResolver,
    provider: {
      name: "fixture",
      async fetch() {
        return {
          canonicalText: "Canonical text\n",
          fetchedAt: "2026-03-09T00:00:00.000Z",
          providerUrl: "https://reader.example/article",
          responseStatus: 200,
          responseHeaders: {
            "content-type": "text/markdown"
          }
        };
      }
    }
  });

  assert.equal(result.runDir, join(runsDir, "run-test"));
  assert.match(
    await readFile(join(result.runDir, "canonical_text.md"), "utf8"),
    /Canonical text/
  );
  assert.deepEqual(await readRegistryRunDirs(result.runDir), [result.runDir]);
  await stat(getCleanupTokenPath(result.runDir));
});

test("fetchNormalizeSource rejects unsafe run IDs that escape runsDir", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-runid-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId: "../../outside",
        hostResolver: publicHostResolver
      }),
    /run IDs with path separators or unsafe segments/
  );
});

test("fetchNormalizeSource does not leave a run directory behind when provider fetch fails", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-fail-"));
  const runId = "run-provider-fail";

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId,
        hostResolver: publicHostResolver,
        provider: {
          name: "fixture",
          async fetch() {
            throw new Error("fixture provider failed");
          }
        }
      }),
    /fixture provider failed/
  );

  await assert.rejects(
    () => stat(join(runsDir, runId)),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  assert.deepEqual(await readRegistryRunDirs(join(runsDir, runId)), []);
  await assert.rejects(
    () => stat(getRunAttestationPath(join(runsDir, runId))),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(getCleanupTokenPath(join(runsDir, runId))),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("fetchNormalizeSource removes the run directory when artifact writes fail after creation", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-write-fail-"));
  const runId = "run-write-fail";

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId,
        hostResolver: publicHostResolver,
        provider: {
          name: "fixture",
          async fetch() {
            return {
              canonicalText: "Canonical text\n",
              fetchedAt: "2026-03-09T00:00:00.000Z",
              providerUrl: "https://reader.example/article",
              responseStatus: 200,
              responseHeaders: {
                "x-bad-header": 1n as unknown as string
              }
            };
          }
        }
      }),
    /Do not know how to serialize a BigInt/
  );

  await assert.rejects(
    () => stat(join(runsDir, runId)),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  assert.deepEqual(await readRegistryRunDirs(join(runsDir, runId)), []);
  await assert.rejects(
    () => stat(getRunAttestationPath(join(runsDir, runId))),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(getCleanupTokenPath(join(runsDir, runId))),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("fetchNormalizeSource removes runtime cleanup state when cleanup-token creation fails after registration", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-token-fail-"));
  const runId = "run-token-fail";
  const runDir = join(runsDir, runId);

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId,
        hostResolver: publicHostResolver,
        provider: {
          name: "fixture",
          async fetch() {
            return {
              canonicalText: "Canonical text\n",
              fetchedAt: "2026-03-09T00:00:00.000Z",
              providerUrl: "https://reader.example/article",
              responseStatus: 200,
              responseHeaders: {
                "content-type": "text/markdown"
              }
            };
          }
        },
        async cleanupTokenWriter() {
          throw new Error("cleanup token write failed");
        }
      }),
    /cleanup token write failed/
  );

  await assert.rejects(
    () => stat(runDir),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  assert.deepEqual(await readRegistryRunDirs(runDir), []);
  await assert.rejects(
    () => stat(getRunAttestationPath(runDir)),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(getCleanupTokenPath(runDir)),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});
