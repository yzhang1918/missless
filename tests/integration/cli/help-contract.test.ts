import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import test from "node:test";

const repoRoot = new URL("../../../", import.meta.url);
const cliEntrypoint = new URL("../../../apps/cli/dist/index.js", import.meta.url);

test("global help describes the runtime contract without backend-specific wording", () => {
  const result = spawnSync(process.execPath, [cliEntrypoint.pathname, "--help"], {
    cwd: repoRoot,
    encoding: "utf8",
    env: process.env
  });

  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /- fetch:/);
  assert.match(result.stdout, /- validate:/);
  assert.match(result.stdout, /- anchor:/);
  assert.match(result.stdout, /- review:/);
  assert.match(result.stdout, /print-draft-contract/);
  assert.match(result.stdout, /run handle: run_dir/);
  assert.doesNotMatch(result.stdout, /fetch-normalize/);
  assert.doesNotMatch(result.stdout, /validate-draft/);
  assert.doesNotMatch(result.stdout, /anchor-evidence/);
  assert.doesNotMatch(result.stdout, /render-review/);
  assert.doesNotMatch(result.stdout, /Extractor boundary: codex/);
});

test("print-draft-contract returns machine-readable contract data", () => {
  const result = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "print-draft-contract"],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(result.status, 0, result.stderr);

  const contract = JSON.parse(result.stdout) as {
    slice: string;
    draft_file: string;
    decision_labels: string[];
    workflow_commands: string[];
    repair_loop: string[];
  };

  assert.equal(contract.slice, "single-run URL -> review package");
  assert.equal(contract.draft_file, "extraction_draft.json");
  assert.deepEqual(contract.decision_labels, ["deep_read", "skim", "skip"]);
  assert.deepEqual(contract.workflow_commands, [
    "fetch",
    "validate",
    "anchor",
    "review"
  ]);
  assert.match(contract.repair_loop[0] ?? "", /Write extraction_draft\.json/);
  assert.match(contract.repair_loop[1] ?? "", /Run validate --run-dir <dir>/);
  assert.match(contract.repair_loop[3] ?? "", /Run anchor --run-dir <dir>/);
  assert.match(contract.repair_loop[4] ?? "", /Run review --run-dir <dir>/);
});
