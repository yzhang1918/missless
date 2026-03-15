import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, realpath } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const repoRoot = fileURLToPath(new URL("../../../", import.meta.url)).replace(/\/$/, "");
const wrapperPath = fileURLToPath(new URL("../../../scripts/bin/missless", import.meta.url));

function createShellEnv(extraEnv: Record<string, string> = {}): NodeJS.ProcessEnv {
  const env: NodeJS.ProcessEnv = {
    ...process.env,
    ...extraEnv,
    MISSLESS_REPO_ROOT: repoRoot
  };

  delete env.NODE_PATH;

  return env;
}

function runShell(
  shell: "bash" | "zsh",
  command: string,
  cwd = repoRoot,
  extraEnv: Record<string, string> = {}
) {
  return spawnSync(shell, ["-lc", command], {
    cwd,
    encoding: "utf8",
    env: createShellEnv(extraEnv)
  });
}

function runActivatedShell(
  shell: "bash" | "zsh",
  command: string,
  cwd = repoRoot,
  extraEnv: Record<string, string> = {}
) {
  return runShell(
    shell,
    `source "$MISSLESS_REPO_ROOT/scripts/dev-activate-missless.sh" >/dev/null && ${command}`,
    cwd,
    extraEnv
  );
}

for (const shell of ["bash", "zsh"] as const) {
  test(`sourced activation exposes the repo-local missless wrapper in ${shell} without changing caller cwd`, async () => {
    const workingDir = await mkdtemp(join(tmpdir(), `missless-activation-${shell}-cwd-`));
    const physicalWorkingDir = await realpath(workingDir);
    const command = runActivatedShell(
      shell,
      [
        "pwd -P",
        "command -v missless",
        "printf '%s\\n' \"$MISSLESS_ACTIVE_WORKTREE\""
      ].join("\n"),
      workingDir
    );

    assert.equal(command.status, 0, command.stderr);
    assert.equal(command.stderr, "");
    assert.deepEqual(command.stdout.trim().split("\n"), [
      physicalWorkingDir,
      wrapperPath,
      repoRoot
    ]);
  });
}

test("sourced activation fails closed when the current shell defines missless as an alias", () => {
  const command = runShell(
    "zsh",
    [
      "alias missless='echo nope'",
      "source \"$MISSLESS_REPO_ROOT/scripts/dev-activate-missless.sh\""
    ].join("\n")
  );

  assert.notEqual(command.status, 0);
  assert.match(command.stderr, /defines it as alias/i);
});

for (const shell of ["bash", "zsh"] as const) {
  test(`activated missless exposes the runtime help and contract from the repo-local wrapper in ${shell}`, () => {
    const command = runActivatedShell(
      shell,
      "missless --help >/dev/null && missless print-draft-contract"
    );

    assert.equal(command.status, 0, command.stderr);
    assert.equal(command.stderr, "");

    const payload = JSON.parse(command.stdout) as {
      schema_path: string;
      decision_labels: string[];
    };

    assert.equal(payload.schema_path, "extraction-draft.schema.json");
    assert.deepEqual(payload.decision_labels, ["deep_read", "skim", "skip"]);
  });
}

test("activated missless forwards fetch subcommands through the repo-local wrapper", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-activation-fetch-unsafe-"));
  const command = runActivatedShell(
    "zsh",
    `missless fetch "http://127.0.0.1/private" --runs-dir "${runsDir}"`
  );

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
  assert.match(payload.run_dir, new RegExp(`^${runsDir}/run-`));
});
