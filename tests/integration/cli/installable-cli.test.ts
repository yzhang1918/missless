import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { once } from "node:events";
import { mkdir, mkdtemp, readFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

const repoRoot = new URL("../../../", import.meta.url);
const fixturePath = new URL("../../fixtures/jina/harness-engineering.md", import.meta.url);

function runCommand(
  command: string,
  args: readonly string[],
  cwd = repoRoot,
  extraEnv: Record<string, string> = {}
) {
  return spawnSync(command, args, {
    cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      ...extraEnv
    }
  });
}

function assertMisslessHelp(binPath: string): void {
  const help = runCommand(binPath, ["--help"]);
  assert.equal(help.status, 0, help.stderr);
  assert.match(help.stdout, /stable entrypoint: missless/i);
}

function assertMisslessContract(binPath: string): void {
  const contract = runCommand(binPath, ["print-draft-contract"]);
  assert.equal(contract.status, 0, contract.stderr);

  const payload = JSON.parse(contract.stdout) as {
    schema_path: string;
    decision_labels: string[];
  };

  assert.equal(payload.schema_path, "extraction-draft.schema.json");
  assert.deepEqual(payload.decision_labels, ["deep_read", "skim", "skip"]);
}

function assertMisslessFetchNormalize(
  binPath: string,
  runsDir: string,
  extraEnv: Record<string, string>
): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(
      binPath,
      [
        "fetch-normalize",
        "https://example.com/agent-harness",
        "--runs-dir",
        runsDir
      ],
      {
        cwd: repoRoot,
        env: {
          ...process.env,
          ...extraEnv
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
      try {
        assert.equal(status, 0, stderr);
        assert.match(stdout, /Created run directory:/);
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  });
}

test("packed apps/cli tarball installs a runnable missless bin for local and prefix-global flows", async () => {
  const fixtureBody = await readFile(fixturePath, "utf8");
  const server = createServer((request, response) => {
    if (request.url === "/https://example.com/agent-harness") {
      response.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
      response.end(fixtureBody);
      return;
    }

    response.writeHead(404);
    response.end("missing fixture");
  });

  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  server.unref();

  const tempRoot = await mkdtemp(join(tmpdir(), "missless-installable-cli-"));
  const tarballDir = join(tempRoot, "tarballs");
  const localPrefix = join(tempRoot, "local-prefix");
  const globalPrefix = join(tempRoot, "global-prefix");
  const localRunsDir = join(tempRoot, "local-runs");
  const globalRunsDir = join(tempRoot, "global-runs");
  const address = server.address();

  if (address === null || typeof address === "string") {
    throw new Error("mock server did not expose a TCP address");
  }

  const fetchEnv = {
    MISSLESS_JINA_BASE_URL: `http://127.0.0.1:${address.port}/`
  };

  await mkdir(tarballDir, { recursive: true });
  await mkdir(localRunsDir, { recursive: true });
  await mkdir(globalRunsDir, { recursive: true });

  try {
    const packed = runCommand("npm", [
      "pack",
      "./apps/cli",
      "--pack-destination",
      tarballDir
    ]);
    assert.equal(packed.status, 0, packed.stderr);
    const tarballPath = join(tarballDir, "missless-cli-0.0.0.tgz");

    const localInstall = runCommand("npm", [
      "install",
      "--prefix",
      localPrefix,
      tarballPath
    ]);
    assert.equal(localInstall.status, 0, localInstall.stderr);
    const localBin = join(localPrefix, "node_modules/.bin/missless");
    assertMisslessHelp(localBin);
    assertMisslessContract(localBin);
    await assertMisslessFetchNormalize(localBin, localRunsDir, fetchEnv);

    const globalInstall = runCommand("npm", [
      "install",
      "--prefix",
      globalPrefix,
      "-g",
      tarballPath
    ]);
    assert.equal(globalInstall.status, 0, globalInstall.stderr);
    const globalBin = join(globalPrefix, "bin/missless");
    assertMisslessHelp(globalBin);
    assertMisslessContract(globalBin);
    await assertMisslessFetchNormalize(globalBin, globalRunsDir, fetchEnv);
  } finally {
    server.closeAllConnections();
    server.close();
  }
});
