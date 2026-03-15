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

const noRedirectFetch = async () => new Response(null, { status: 200 });

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

test("fetchNormalizeSource rejects redirect hops to blocked destinations before provider fetch", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        hostResolver: publicHostResolver,
        fetchImpl: async () =>
          new Response(null, {
            status: 302,
            headers: {
              location: "http://127.0.0.1/private"
            }
          }),
        provider: {
          name: "fixture",
          async fetch() {
            throw new Error("provider should not be called");
          }
        }
      }),
    /redirect hops and final destinations/
  );
});

test("fetchNormalizeSource preflights redirects but still passes the original URL into provider fetch", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));
  const providerCalls: string[] = [];
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/original",
    runsDir,
    runId: "run-redirect-preflight",
    now: new Date("2026-03-11T00:00:00.000Z"),
    hostResolver: publicHostResolver,
    fetchImpl: async (input) => {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;

      if (url === "https://example.com/original") {
        return new Response(null, {
          status: 302,
          headers: {
            location: "https://www.example.com/final"
          }
        });
      }

      if (url === "https://www.example.com/final") {
        return new Response(null, {
          status: 200
        });
      }

      throw new Error(`Unexpected URL during redirect preflight: ${url}`);
    },
    provider: {
      name: "jina_reader",
      async fetch(sourceUrl) {
        providerCalls.push(sourceUrl);

        return {
          providerName: "jina_reader",
          canonicalText: "Canonical text\n",
          fetchedAt: "2026-03-11T00:00:00.000Z",
          providerUrl: "https://reader.example/https://example.com/original",
          resolvedSourceUrl: sourceUrl,
          responseStatus: 200,
          responseHeaders: {
            "content-type": "text/markdown"
          }
        };
      }
    }
  });

  assert.deepEqual(providerCalls, ["https://example.com/original"]);
  assert.equal(result.sourceArtifact.requested.url, "https://example.com/original");
  assert.equal(result.sourceArtifact.requested.fetch_method, "auto");
  assert.equal(result.sourceArtifact.decision_basis.url, "https://www.example.com/final");
  assert.equal(result.sourceArtifact.decision_basis.fetch_method, "jina_reader");
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
    fetchImpl: noRedirectFetch,
    provider: {
      name: "jina_reader",
      async fetch() {
        return {
          providerName: "jina_reader",
          canonicalText: "Canonical text\n",
          fetchedAt: "2026-03-09T00:00:00.000Z",
          providerUrl: "https://reader.example/article",
          resolvedSourceUrl: "https://example.com/article",
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

test("fetchNormalizeSource falls back from Jina Reader to direct origin on recoverable failures", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-fallback-"));
  const requests: string[] = [];
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/article",
    runsDir,
    runId: "run-fallback",
    now: new Date("2026-03-11T00:00:00.000Z"),
    hostResolver: publicHostResolver,
    fetchImpl: async (input) => {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;

      requests.push(url);

      if (url === "https://example.com/article" && requests.length === 1) {
        return new Response(null, { status: 200 });
      }

      if (url === "https://r.jina.ai/https://example.com/article") {
        return new Response("upstream unavailable", { status: 502 });
      }

      if (url === "https://example.com/article") {
        return new Response(
          [
            "<!doctype html>",
            "<html>",
            "<head><title>Fallback Article</title></head>",
            "<body><article><h1>Fallback Article</h1><p>Recovered from origin.</p></article></body>",
            "</html>"
          ].join(""),
          {
            status: 200,
            headers: {
              "content-type": "text/html; charset=utf-8"
            }
          }
        );
      }

      throw new Error(`Unexpected URL: ${url}`);
    }
  });

  assert.deepEqual(requests, [
    "https://example.com/article",
    "https://r.jina.ai/https://example.com/article",
    "https://example.com/article"
  ]);
  assert.equal(result.provider, "direct_origin");
  assert.equal(result.sourceArtifact.requested.fetch_method, "auto");
  assert.equal(result.sourceArtifact.decision_basis.fetch_method, "direct_origin");
  assert.equal(result.sourceArtifact.decision_basis.url, "https://example.com/article");
  assert.match(result.canonicalText, /Fallback Article/);
  assert.match(result.canonicalText, /Recovered from origin/);
});

test("fetchNormalizeSource falls back when Jina Reader returns an interstitial warning page", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-fallback-"));
  const requests: string[] = [];
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/article",
    runsDir,
    runId: "run-fallback-warning",
    now: new Date("2026-03-11T00:00:00.000Z"),
    hostResolver: publicHostResolver,
    fetchImpl: async (input) => {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;

      requests.push(url);

      if (url === "https://example.com/article" && requests.length === 1) {
        return new Response(null, { status: 200 });
      }

      if (url === "https://r.jina.ai/https://example.com/article") {
        return new Response(
          [
            "Title: Just a moment...",
            "",
            "URL Source: https://example.com/article",
            "",
            "Markdown Content:",
            "Verification successful. Waiting for example.com to respond"
          ].join("\n"),
          {
            status: 200,
            headers: {
              "content-type": "text/plain; charset=utf-8"
            }
          }
        );
      }

      if (url === "https://example.com/article") {
        return new Response("Recovered canonical text\n", {
          status: 200,
          headers: {
            "content-type": "text/plain; charset=utf-8"
          }
        });
      }

      throw new Error(`Unexpected URL: ${url}`);
    }
  });

  assert.deepEqual(requests, [
    "https://example.com/article",
    "https://r.jina.ai/https://example.com/article",
    "https://example.com/article"
  ]);
  assert.equal(result.provider, "direct_origin");
  assert.equal(result.canonicalText, "Recovered canonical text\n");
});

test("fetchNormalizeSource falls back when Jina Reader returns empty canonical text", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-fallback-"));
  const requests: string[] = [];
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/article",
    runsDir,
    runId: "run-fallback-empty",
    now: new Date("2026-03-11T00:00:00.000Z"),
    hostResolver: publicHostResolver,
    fetchImpl: async (input) => {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;

      requests.push(url);

      if (url === "https://example.com/article" && requests.length === 1) {
        return new Response(null, { status: 200 });
      }

      if (url === "https://r.jina.ai/https://example.com/article") {
        return new Response("\n\n", {
          status: 200,
          headers: {
            "content-type": "text/plain; charset=utf-8"
          }
        });
      }

      if (url === "https://example.com/article") {
        return new Response("Recovered after empty reader response\n", {
          status: 200,
          headers: {
            "content-type": "text/plain; charset=utf-8"
          }
        });
      }

      throw new Error(`Unexpected URL: ${url}`);
    }
  });

  assert.deepEqual(requests, [
    "https://example.com/article",
    "https://r.jina.ai/https://example.com/article",
    "https://example.com/article"
  ]);
  assert.equal(result.provider, "direct_origin");
  assert.equal(result.canonicalText, "Recovered after empty reader response\n");
});

test("fetchNormalizeSource honors an explicit direct_origin fetch method", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-direct-"));
  const requests: string[] = [];
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/article",
    runsDir,
    runId: "run-direct-method",
    now: new Date("2026-03-14T00:00:00.000Z"),
    fetchMethod: "direct_origin",
    hostResolver: publicHostResolver,
    fetchImpl: async (input) => {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;

      requests.push(url);

      if (url === "https://example.com/article" && requests.length === 1) {
        return new Response(null, { status: 200 });
      }

      if (url === "https://example.com/article") {
        return new Response("Direct fetch only\n", {
          status: 200,
          headers: {
            "content-type": "text/plain; charset=utf-8"
          }
        });
      }

      throw new Error(`Unexpected URL: ${url}`);
    }
  });

  assert.deepEqual(requests, [
    "https://example.com/article",
    "https://example.com/article"
  ]);
  assert.equal(result.provider, "direct_origin");
  assert.equal(result.sourceArtifact.requested.fetch_method, "direct_origin");
  assert.equal(result.sourceArtifact.decision_basis.fetch_method, "direct_origin");
  assert.equal(result.canonicalText, "Direct fetch only\n");
});

test("fetchNormalizeSource does not fall back when an explicit jina_reader fetch method fails", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-jina-only-"));
  const requests: string[] = [];

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId: "run-jina-only",
        now: new Date("2026-03-14T00:00:00.000Z"),
        fetchMethod: "jina_reader",
        hostResolver: publicHostResolver,
        fetchImpl: async (input) => {
          const url =
            typeof input === "string"
              ? input
              : input instanceof URL
                ? input.toString()
                : input.url;

          requests.push(url);

          if (url === "https://example.com/article" && requests.length === 1) {
            return new Response(null, { status: 200 });
          }

          if (url === "https://r.jina.ai/https://example.com/article") {
            return new Response("upstream unavailable", { status: 502 });
          }

          throw new Error(`Unexpected URL: ${url}`);
        }
      }),
    /Jina Reader request failed with status 502/
  );

  assert.deepEqual(requests, [
    "https://example.com/article",
    "https://r.jina.ai/https://example.com/article"
  ]);
});

test("fetchNormalizeSource allows injected custom providers that declare a durable fetch method", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-custom-provider-"));
  const result = await fetchNormalizeSource({
    sourceUrl: "https://example.com/article",
    runsDir,
    runId: "run-custom-provider",
    now: new Date("2026-03-15T00:00:00.000Z"),
    hostResolver: publicHostResolver,
    fetchImpl: noRedirectFetch,
    provider: {
      name: "fixture_provider",
      async fetch() {
        return {
          providerName: "fixture_provider",
          durableFetchMethod: "direct_origin",
          canonicalText: "Custom provider text\n",
          fetchedAt: "2026-03-15T00:00:00.000Z",
          providerUrl: "https://provider.example/article",
          resolvedSourceUrl: "https://example.com/article",
          responseStatus: 200,
          responseHeaders: {
            "content-type": "text/plain; charset=utf-8"
          }
        };
      }
    }
  });

  assert.equal(result.provider, "direct_origin");
  assert.equal(result.sourceArtifact.requested.fetch_method, "auto");
  assert.equal(result.sourceArtifact.decision_basis.fetch_method, "direct_origin");
  assert.equal(result.canonicalText, "Custom provider text\n");
});

test("fetchNormalizeSource rejects injected custom providers that omit a durable fetch method", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-custom-provider-auto-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId: "run-custom-provider-auto",
        now: new Date("2026-03-15T00:00:00.000Z"),
        fetchMethod: "direct_origin",
        hostResolver: publicHostResolver,
        fetchImpl: noRedirectFetch,
        provider: {
          name: "fixture_provider",
          async fetch() {
            return {
              providerName: "fixture_provider",
              canonicalText: "Custom provider text\n",
              fetchedAt: "2026-03-15T00:00:00.000Z",
              providerUrl: "https://provider.example/article",
              resolvedSourceUrl: "https://example.com/article",
              responseStatus: 200,
              responseHeaders: {
                "content-type": "text/plain; charset=utf-8"
              }
            };
          }
        }
      }),
    /custom providers to return durableFetchMethod/
  );
});

test("fetchNormalizeSource rejects custom providers that contradict an explicit fetch method", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-custom-provider-mismatch-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId: "run-custom-provider-mismatch",
        now: new Date("2026-03-15T00:00:00.000Z"),
        fetchMethod: "direct_origin",
        hostResolver: publicHostResolver,
        fetchImpl: noRedirectFetch,
        provider: {
          name: "fixture_provider",
          async fetch() {
            return {
              providerName: "fixture_provider",
              durableFetchMethod: "jina_reader",
              canonicalText: "Custom provider text\n",
              fetchedAt: "2026-03-15T00:00:00.000Z",
              providerUrl: "https://provider.example/article",
              resolvedSourceUrl: "https://example.com/article",
              responseStatus: 200,
              responseHeaders: {
                "content-type": "text/plain; charset=utf-8"
              }
            };
          }
        }
      }),
    /conflicts with explicit requested fetch method direct_origin/
  );
});

test("fetchNormalizeSource rejects unsafe run IDs that escape runsDir", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-runid-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://example.com/article",
        runsDir,
        runId: "../../outside",
        hostResolver: publicHostResolver,
        fetchImpl: noRedirectFetch
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
        fetchImpl: noRedirectFetch,
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
        fetchImpl: noRedirectFetch,
        provider: {
          name: "jina_reader",
          async fetch() {
            return {
              providerName: "jina_reader",
              canonicalText: "Canonical text\n",
              fetchedAt: 1n as unknown as string,
              providerUrl: "https://reader.example/article",
              resolvedSourceUrl: "https://example.com/article",
              responseStatus: 200,
              responseHeaders: {
                "content-type": "text/markdown"
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
        fetchImpl: noRedirectFetch,
        provider: {
          name: "jina_reader",
          async fetch() {
            return {
              providerName: "jina_reader",
              canonicalText: "Canonical text\n",
              fetchedAt: "2026-03-09T00:00:00.000Z",
              providerUrl: "https://reader.example/article",
              resolvedSourceUrl: "https://example.com/article",
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
