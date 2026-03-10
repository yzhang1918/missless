import assert from "node:assert/strict";
import { mkdtemp, readFile, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { fetchNormalizeSource } from "../../../packages/core/src/index.ts";

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

test("fetchNormalizeSource creates missing parent directories for runsDir", async () => {
  const tempRoot = await mkdtemp(join(tmpdir(), "missless-fetch-runs-"));
  const runsDir = join(tempRoot, "nested", "runs");
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/article",
    runsDir,
    runId: "run-test",
    now: new Date("2026-03-09T00:00:00.000Z"),
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
});

test("fetchNormalizeSource rejects unsafe run IDs that escape runsDir", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-runid-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId: "../../outside"
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
});
