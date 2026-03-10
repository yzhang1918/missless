import assert from "node:assert/strict";
import { once } from "node:events";
import { readFile, readdir } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { mkdtemp } from "node:fs/promises";
import { spawn } from "node:child_process";
import test from "node:test";

const repoRoot = new URL("../../../", import.meta.url);
const cliEntrypoint = new URL("../../../apps/cli/dist/index.js", import.meta.url);
const fixturePath = new URL("../../fixtures/jina/harness-engineering.md", import.meta.url);

test("fetch-normalize creates a stable run directory from a URL", async () => {
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
    const command = await new Promise<{
      status: number | null;
      stdout: string;
      stderr: string;
    }>((resolve, reject) => {
      const child = spawn(
        process.execPath,
        [
          cliEntrypoint.pathname,
          "fetch-normalize",
          "https://example.com/agent-harness",
          "--runs-dir",
          runsDir
        ],
        {
          cwd: repoRoot,
          env: {
            ...process.env,
            MISSLESS_JINA_BASE_URL: `http://127.0.0.1:${address.port}/`
          },
          stdio: ["ignore", "pipe", "pipe"]
        }
      );
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

    assert.equal(command.status, 0, command.stderr);

    const entries = (await readdir(runsDir, { withFileTypes: true })).filter((entry) =>
      entry.isDirectory()
    );

    assert.equal(entries.length, 1, "expected one run directory");

    const runDir = join(runsDir, entries[0]!.name);
    const source = JSON.parse(
      await readFile(join(runDir, "source.json"), "utf8")
    ) as Record<string, string>;
    const canonicalText = await readFile(join(runDir, "canonical_text.md"), "utf8");

    assert.equal(source.source_url, "https://example.com/agent-harness");
    assert.equal(source.provider, "jina_reader");
    assert.equal(
      canonicalText,
      fixtureBody.trimEnd() + "\n"
    );
  } finally {
    server.closeAllConnections();
    server.close();
  }
});

test("fetch-normalize rejects unsafe source URLs before provider access", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-unsafe-"));
  const command = await new Promise<{
    status: number | null;
    stdout: string;
    stderr: string;
  }>((resolve, reject) => {
    const child = spawn(
      process.execPath,
      [
        cliEntrypoint.pathname,
        "fetch-normalize",
        "http://127.0.0.1/private",
        "--runs-dir",
        runsDir
      ],
      {
        cwd: repoRoot,
        env: process.env,
        stdio: ["ignore", "pipe", "pipe"]
      }
    );
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

  assert.notEqual(command.status, 0);
  assert.match(
    command.stderr,
    /localhost, private, link-local, and single-label hosts/
  );
});
