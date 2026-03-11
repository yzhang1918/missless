import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

const repoRoot = new URL("../../../", import.meta.url);

function runCommand(command: string, args: readonly string[], cwd = repoRoot) {
  return spawnSync(command, args, {
    cwd,
    encoding: "utf8",
    env: process.env
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

test("packed apps/cli tarball installs a runnable missless bin for local and prefix-global flows", async () => {
  const tempRoot = await mkdtemp(join(tmpdir(), "missless-installable-cli-"));
  const tarballDir = join(tempRoot, "tarballs");
  const localPrefix = join(tempRoot, "local-prefix");
  const globalPrefix = join(tempRoot, "global-prefix");

  await mkdir(tarballDir, { recursive: true });

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
  assertMisslessHelp(join(localPrefix, "node_modules/.bin/missless"));
  assertMisslessContract(join(localPrefix, "node_modules/.bin/missless"));

  const globalInstall = runCommand("npm", [
    "install",
    "--prefix",
    globalPrefix,
    "-g",
    tarballPath
  ]);
  assert.equal(globalInstall.status, 0, globalInstall.stderr);
  assertMisslessHelp(join(globalPrefix, "bin/missless"));
  assertMisslessContract(join(globalPrefix, "bin/missless"));
});
