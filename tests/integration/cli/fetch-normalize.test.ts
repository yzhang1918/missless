import assert from "node:assert/strict";
import { once } from "node:events";
import { readFile, readdir } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { mkdtemp } from "node:fs/promises";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";

const repoRoot = new URL("../../../", import.meta.url);
const cliEntrypoint = new URL("../../../apps/cli/dist/index.js", import.meta.url);
const fixturePath = new URL("../../fixtures/jina/harness-engineering.md", import.meta.url);
const fetchMockModulePath = fileURLToPath(
  new URL("../../helpers/fetch-mock.mjs", import.meta.url)
);
const happyPathSourceUrl = "https://example.com/agent-harness";
const fallbackSourceUrl = "https://example.com/fallback-article";

function createFetchMockEnv(sourceUrl: string, scenario: string): Record<string, string> {
  return {
    MISSLESS_TEST_SOURCE_URL: sourceUrl,
    MISSLESS_TEST_FETCH_SCENARIO: scenario,
    NODE_OPTIONS: [process.env.NODE_OPTIONS, `--import=${fetchMockModulePath}`]
      .filter(Boolean)
      .join(" ")
  };
}

function runFetchCommand(
  args: readonly string[],
  env: Record<string, string> = {}
): Promise<{
  status: number | null;
  stdout: string;
  stderr: string;
}> {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [cliEntrypoint.pathname, "fetch", ...args], {
      cwd: repoRoot,
      env: {
        ...process.env,
        ...env
      },
      stdio: ["ignore", "pipe", "pipe"]
    });
    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });
    child.on("error", reject);
    child.on("close", (status) => {
      resolve({ status, stdout, stderr });
    });
  });
}

test("fetch returns a JSON result and creates a stable run directory from a URL", async () => {
  const fixtureBody = await readFile(fixturePath, "utf8");
  const server = createServer((request, response) => {
    if (request.url === "/https://example.com/agent-harness") {
      response.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
      response.end("\uFEFF" + fixtureBody.replace(/\n/g, "\r\n") + "   \r\n");
      return;
    }

    response.writeHead(404);
    response.end("missing fixture");
  });

  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  server.unref();

  try {
    const address = server.address();

    if (address === null || typeof address === "string") {
      throw new Error("mock server did not expose a TCP address");
    }

    const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-"));
    const command = await runFetchCommand(
      [happyPathSourceUrl, "--runs-dir", runsDir],
      {
        MISSLESS_JINA_BASE_URL: `http://127.0.0.1:${address.port}/`,
        ...createFetchMockEnv(happyPathSourceUrl, "happy-path")
      }
    );

    assert.equal(command.status, 0, command.stderr);
    const payload = JSON.parse(command.stdout) as {
      ok: boolean;
      command: string;
      run_dir: string;
      artifacts: {
        source: string;
        canonical_text: string;
      };
      source: {
        requested: {
          url: string;
          fetch_method: string;
        };
        decision_basis: {
          url: string;
          fetch_method: string;
        };
      };
      ready_for: string[];
    };

    const entries = (await readdir(runsDir, { withFileTypes: true })).filter((entry) =>
      entry.isDirectory()
    );

    assert.equal(entries.length, 1, "expected one run directory");

    const runDir = join(runsDir, entries[0]!.name);
    const source = JSON.parse(
      await readFile(join(runDir, "source.json"), "utf8")
    ) as {
      requested: {
        url: string;
        fetch_method: string;
      };
      decision_basis: {
        url: string;
        fetch_method: string;
      };
    };
    const canonicalText = await readFile(join(runDir, "canonical_text.md"), "utf8");

    assert.equal(payload.ok, true);
    assert.equal(payload.command, "fetch");
    assert.equal(payload.run_dir, runDir);
    assert.equal(payload.artifacts.source, join(runDir, "source.json"));
    assert.equal(payload.artifacts.canonical_text, join(runDir, "canonical_text.md"));
    assert.equal(payload.source.requested.url, happyPathSourceUrl);
    assert.equal(payload.source.requested.fetch_method, "auto");
    assert.equal(payload.source.decision_basis.url, happyPathSourceUrl);
    assert.equal(payload.source.decision_basis.fetch_method, "jina_reader");
    assert.deepEqual(payload.ready_for, [
      "read_canonical_text",
      "write_extraction_draft",
      "validate"
    ]);
    assert.equal(source.requested.url, happyPathSourceUrl);
    assert.equal(source.decision_basis.fetch_method, "jina_reader");
    assert.equal(
      canonicalText,
      fixtureBody.trimEnd() + "\n"
    );
  } finally {
    server.closeAllConnections();
    server.close();
  }
});

test("fetch returns a JSON failure when it rejects an unsafe source URL before provider access", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-unsafe-"));
  const command = await runFetchCommand([
    "http://127.0.0.1/private",
    "--runs-dir",
    runsDir
  ]);

  assert.notEqual(command.status, 0);
  assert.equal(command.stderr, "");

  const payload = JSON.parse(command.stdout) as {
    ok: boolean;
    command: string;
    summary: string;
    run_dir: string;
  };

  assert.equal(payload.ok, false);
  assert.equal(payload.command, "fetch");
  assert.match(payload.summary, /localhost, private, link-local, and single-label hosts/);
  assert.match(payload.run_dir, /missless-fetch-unsafe-/);
});

test("fetch honors --fetch-method direct and persists direct-origin provenance", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-direct-cli-"));
  const command = await runFetchCommand(
    [
      fallbackSourceUrl,
      "--runs-dir",
      runsDir,
      "--fetch-method",
      "direct"
    ],
    createFetchMockEnv(fallbackSourceUrl, "fallback-direct-origin")
  );

  assert.equal(command.status, 0, command.stderr);
  assert.equal(command.stderr, "");

  const payload = JSON.parse(command.stdout) as {
    ok: boolean;
    command: string;
    source: {
      requested: {
        fetch_method: string;
      };
      decision_basis: {
        url: string;
        fetch_method: string;
      };
    };
  };

  assert.equal(payload.ok, true);
  assert.equal(payload.command, "fetch");
  assert.equal(payload.source.requested.fetch_method, "direct_origin");
  assert.equal(payload.source.decision_basis.fetch_method, "direct_origin");
  assert.equal(payload.source.decision_basis.url, fallbackSourceUrl);
});

test("fetch does not fall back when --fetch-method jina is explicitly requested", async () => {
  const fixtureBody = await readFile(fixturePath, "utf8");
  const server = createServer((request, response) => {
    if (request.url === `/${happyPathSourceUrl}`) {
      response.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
      response.end(fixtureBody);
      return;
    }

    if (request.url === `/${fallbackSourceUrl}`) {
      response.writeHead(502, { "content-type": "text/plain; charset=utf-8" });
      response.end("upstream unavailable");
      return;
    }

    response.writeHead(404);
    response.end("missing fixture");
  });

  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  server.unref();

  try {
    const address = server.address();

    if (address === null || typeof address === "string") {
      throw new Error("mock server did not expose a TCP address");
    }

    const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-jina-cli-"));
    const command = await runFetchCommand(
      [
        fallbackSourceUrl,
        "--runs-dir",
        runsDir,
        "--fetch-method",
        "jina"
      ],
      {
        MISSLESS_JINA_BASE_URL: `http://127.0.0.1:${address.port}/`,
        ...createFetchMockEnv(fallbackSourceUrl, "fallback-direct-origin")
      }
    );

    assert.equal(command.status, 1);
    assert.equal(command.stderr, "");

    const payload = JSON.parse(command.stdout) as {
      ok: boolean;
      command: string;
      summary: string;
      source: {
        requested: {
          fetch_method?: string;
        };
      };
    };

    assert.equal(payload.ok, false);
    assert.equal(payload.command, "fetch");
    assert.match(payload.summary, /Jina Reader request failed with status 502/);
    assert.equal(payload.source.requested.fetch_method, "jina_reader");
  } finally {
    server.closeAllConnections();
    server.close();
  }
});

test("fetch rejects unknown --fetch-method values before running the workflow", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-invalid-method-"));
  const command = await runFetchCommand([
    happyPathSourceUrl,
    "--runs-dir",
    runsDir,
    "--fetch-method",
    "toString"
  ]);

  assert.equal(command.status, 1);
  assert.equal(command.stdout, "");
  assert.match(
    command.stderr,
    /Unknown value for --fetch-method: toString. Expected one of auto, jina, direct./
  );
});
