import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { once } from "node:events";
import { mkdir, mkdtemp, readFile, readdir } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const repoRoot = new URL("../../../", import.meta.url);
const fixturePath = new URL("../../fixtures/jina/harness-engineering.md", import.meta.url);
const fetchMockModulePath = fileURLToPath(
  new URL("../../helpers/fetch-mock.mjs", import.meta.url)
);
const happyPathSourceUrl = "https://example.com/agent-harness";
const fallbackSourceUrl = "https://example.com/fallback-article";
const blockedRedirectSourceUrl = "https://example.com/blocked-redirect";

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

function createFetchMockEnv(sourceUrl: string, scenario: string): Record<string, string> {
  return {
    MISSLESS_TEST_SOURCE_URL: sourceUrl,
    MISSLESS_TEST_FETCH_SCENARIO: scenario,
    NODE_OPTIONS: [process.env.NODE_OPTIONS, `--import=${fetchMockModulePath}`]
      .filter(Boolean)
      .join(" ")
  };
}

function createPackagedFetchEnv(
  sourceUrl: string,
  scenario: string,
  port: number
): Record<string, string> {
  return {
    MISSLESS_JINA_BASE_URL: `http://127.0.0.1:${port}/`,
    ...createFetchMockEnv(sourceUrl, scenario)
  };
}

function createJinaFixtureServer(fixtureBody: string) {
  return createServer((request, response) => {
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

    if (request.url === `/${blockedRedirectSourceUrl}`) {
      response.writeHead(500, { "content-type": "text/plain; charset=utf-8" });
      response.end("provider should not be called");
      return;
    }

    response.writeHead(404);
    response.end("missing fixture");
  });
}

function packCliTarball(tarballDir: string): string {
  const packed = runCommand("npm", [
    "pack",
    "./apps/cli",
    "--pack-destination",
    tarballDir
  ]);
  assert.equal(packed.status, 0, packed.stderr);

  return join(tarballDir, "missless-cli-0.0.0.tgz");
}

function installTarball(
  tarballPath: string,
  prefix: string,
  cacheDir: string,
  globalInstall = false
): void {
  const args = [
    "install",
    "--offline",
    "--cache",
    cacheDir,
    "--prefix",
    prefix
  ];

  if (globalInstall) {
    args.push("-g");
  }

  args.push(tarballPath);

  const install = runCommand("npm", args);
  assert.equal(install.status, 0, install.stderr);
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

function runMisslessFetchNormalize(
  binPath: string,
  sourceUrl: string,
  runsDir: string,
  extraEnv: Record<string, string>
): Promise<{
  status: number | null;
  stdout: string;
  stderr: string;
}> {
  return new Promise((resolve, reject) => {
    const child = spawn(
      binPath,
      [
        "fetch-normalize",
        sourceUrl,
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
      resolve({ status, stdout, stderr });
    });
  });
}

async function readSingleRunArtifacts(runsDir: string): Promise<{
  runDir: string;
  source: Record<string, string>;
  canonicalText: string;
}> {
  const entries = (await readdir(runsDir, { withFileTypes: true })).filter((entry) =>
    entry.isDirectory()
  );

  assert.equal(entries.length, 1, "expected one run directory");

  const runDir = join(runsDir, entries[0]!.name);
  const source = JSON.parse(
    await readFile(join(runDir, "source.json"), "utf8")
  ) as Record<string, string>;
  const canonicalText = await readFile(join(runDir, "canonical_text.md"), "utf8");

  return {
    runDir,
    source,
    canonicalText
  };
}

test("packed apps/cli tarball installs offline for local and prefix-global flows and preserves happy-path smoke", async () => {
  const fixtureBody = await readFile(fixturePath, "utf8");
  const server = createJinaFixtureServer(fixtureBody);

  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  server.unref();

  const tempRoot = await mkdtemp(join(tmpdir(), "missless-installable-cli-"));
  const tarballDir = join(tempRoot, "tarballs");
  const localPrefix = join(tempRoot, "local-prefix");
  const globalPrefix = join(tempRoot, "global-prefix");
  const localCacheDir = join(tempRoot, "local-cache");
  const globalCacheDir = join(tempRoot, "global-cache");
  const localRunsDir = join(tempRoot, "local-runs");
  const globalRunsDir = join(tempRoot, "global-runs");
  const address = server.address();

  if (address === null || typeof address === "string") {
    throw new Error("mock server did not expose a TCP address");
  }

  await mkdir(tarballDir, { recursive: true });
  await mkdir(localRunsDir, { recursive: true });
  await mkdir(globalRunsDir, { recursive: true });

  try {
    const tarballPath = packCliTarball(tarballDir);

    installTarball(tarballPath, localPrefix, localCacheDir);
    const localBin = join(localPrefix, "node_modules/.bin/missless");
    assertMisslessHelp(localBin);
    assertMisslessContract(localBin);

    const localCommand = await runMisslessFetchNormalize(
      localBin,
      happyPathSourceUrl,
      localRunsDir,
      createPackagedFetchEnv(happyPathSourceUrl, "happy-path", address.port)
    );
    assert.equal(localCommand.status, 0, localCommand.stderr);
    assert.match(localCommand.stdout, /Created run directory:/);

    const localArtifacts = await readSingleRunArtifacts(localRunsDir);
    assert.equal(localArtifacts.source.source_url, happyPathSourceUrl);
    assert.equal(localArtifacts.source.provider, "jina_reader");
    assert.equal(localArtifacts.canonicalText, fixtureBody.trimEnd() + "\n");

    installTarball(tarballPath, globalPrefix, globalCacheDir, true);
    const globalBin = join(globalPrefix, "bin/missless");
    assertMisslessHelp(globalBin);
    assertMisslessContract(globalBin);

    const globalCommand = await runMisslessFetchNormalize(
      globalBin,
      happyPathSourceUrl,
      globalRunsDir,
      createPackagedFetchEnv(happyPathSourceUrl, "happy-path", address.port)
    );
    assert.equal(globalCommand.status, 0, globalCommand.stderr);
    assert.match(globalCommand.stdout, /Created run directory:/);

    const globalArtifacts = await readSingleRunArtifacts(globalRunsDir);
    assert.equal(globalArtifacts.source.source_url, happyPathSourceUrl);
    assert.equal(globalArtifacts.source.provider, "jina_reader");
    assert.equal(globalArtifacts.canonicalText, fixtureBody.trimEnd() + "\n");
  } finally {
    server.closeAllConnections();
    server.close();
  }
});

test("installed missless bin covers fallback success and redirect-preflight failure without live network access", async () => {
  const fixtureBody = await readFile(fixturePath, "utf8");
  const server = createJinaFixtureServer(fixtureBody);

  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  server.unref();

  const tempRoot = await mkdtemp(join(tmpdir(), "missless-installable-cli-"));
  const tarballDir = join(tempRoot, "tarballs");
  const localPrefix = join(tempRoot, "local-prefix");
  const localCacheDir = join(tempRoot, "local-cache");
  const fallbackRunsDir = join(tempRoot, "fallback-runs");
  const blockedRunsDir = join(tempRoot, "blocked-runs");
  const address = server.address();

  if (address === null || typeof address === "string") {
    throw new Error("mock server did not expose a TCP address");
  }

  await mkdir(tarballDir, { recursive: true });
  await mkdir(fallbackRunsDir, { recursive: true });
  await mkdir(blockedRunsDir, { recursive: true });

  try {
    const tarballPath = packCliTarball(tarballDir);
    installTarball(tarballPath, localPrefix, localCacheDir);
    const localBin = join(localPrefix, "node_modules/.bin/missless");

    const fallbackCommand = await runMisslessFetchNormalize(
      localBin,
      fallbackSourceUrl,
      fallbackRunsDir,
      createPackagedFetchEnv(fallbackSourceUrl, "fallback-direct-origin", address.port)
    );
    assert.equal(fallbackCommand.status, 0, fallbackCommand.stderr);
    assert.match(fallbackCommand.stdout, /Created run directory:/);

    const fallbackArtifacts = await readSingleRunArtifacts(fallbackRunsDir);
    assert.equal(fallbackArtifacts.source.source_url, fallbackSourceUrl);
    assert.equal(fallbackArtifacts.source.provider, "direct_origin");
    assert.equal(fallbackArtifacts.source.resolved_source_url, fallbackSourceUrl);
    assert.equal(fallbackArtifacts.source.provider_url, fallbackSourceUrl);
    assert.match(fallbackArtifacts.canonicalText, /Fallback Article/);
    assert.match(fallbackArtifacts.canonicalText, /Recovered from origin/);

    const blockedCommand = await runMisslessFetchNormalize(
      localBin,
      blockedRedirectSourceUrl,
      blockedRunsDir,
      createPackagedFetchEnv(
        blockedRedirectSourceUrl,
        "redirect-preflight-blocked",
        address.port
      )
    );
    assert.notEqual(blockedCommand.status, 0);
    assert.match(
      blockedCommand.stderr,
      /redirect hops and final destinations/
    );

    const blockedEntries = (await readdir(blockedRunsDir, {
      withFileTypes: true
    })).filter((entry) => entry.isDirectory());
    assert.equal(blockedEntries.length, 0);
  } finally {
    server.closeAllConnections();
    server.close();
  }
});
