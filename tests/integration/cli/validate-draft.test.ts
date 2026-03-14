import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

const repoRoot = new URL("../../../", import.meta.url);
const cliEntrypoint = new URL("../../../apps/cli/dist/index.js", import.meta.url);
const fixtureDraftPath = new URL("../../fixtures/drafts/valid-extraction-draft.json", import.meta.url);
const fixtureCanonicalPath = new URL("../../fixtures/jina/harness-engineering.md", import.meta.url);

test("validate emits a JSON result by default for both success and failure", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-cli-validate-"));
  const runDir = join(runsRoot, "run-validate");
  const validDraft = JSON.parse(
    await readFile(fixtureDraftPath, "utf8")
  ) as Record<string, unknown>;

  await mkdir(runDir, { recursive: true });
  await writeFile(
    join(runDir, "run.json"),
    "{\n  \"run_id\": \"run-validate\",\n  \"stage\": \"normalized\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "canonical_text.md"),
    await readFile(fixtureCanonicalPath, "utf8"),
    "utf8"
  );
  await writeFile(
    join(runDir, "source.json"),
    [
      "{",
      '  "requested": {',
      '    "url": "https://example.com/agent-harness",',
      '    "fetch_method": "auto"',
      "  },",
      '  "decision_basis": {',
      '    "url": "https://example.com/agent-harness",',
      '    "fetch_method": "jina_reader",',
      '    "snapshot_sha256": "fixture-sha"',
      "  },",
      '  "fetched_at": "2026-03-09T00:00:00.000Z"',
      "}"
    ].join("\n") + "\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "extraction_draft.json"),
    JSON.stringify(validDraft, null, 2) + "\n",
    "utf8"
  );

  const success = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "validate", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(success.status, 0, success.stderr);
  const successPayload = JSON.parse(success.stdout) as {
    ok: boolean;
    command: string;
    summary: string;
    run_dir: string;
    decision?: string;
    atom_count?: number;
  };
  assert.equal(successPayload.ok, true);
  assert.equal(successPayload.command, "validate");
  assert.match(successPayload.summary, /Draft is valid/);
  assert.equal(successPayload.run_dir, runDir);
  assert.equal(successPayload.decision, "deep_read");
  assert.equal(
    successPayload.atom_count,
    (validDraft.atom_candidates as unknown[]).length
  );

  const duplicateDraft = structuredClone(validDraft);
  const atomCandidates = duplicateDraft.atom_candidates as Array<Record<string, unknown>>;
  atomCandidates[1] = {
    ...atomCandidates[1],
    claim: atomCandidates[0]?.claim
  };

  await writeFile(
    join(runDir, "extraction_draft.json"),
    JSON.stringify(duplicateDraft, null, 2) + "\n",
    "utf8"
  );

  const failure = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "validate", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(failure.status, 1);

  const diagnostics = JSON.parse(failure.stdout) as {
    ok: boolean;
    command: string;
    summary: string;
    diagnostics: Array<{ code: string }>;
  };

  assert.equal(diagnostics.ok, false);
  assert.equal(diagnostics.command, "validate");
  assert.match(diagnostics.summary, /Draft validation failed/);
  assert.equal(diagnostics.diagnostics[0]?.code, "duplicate_atom_claim");
});
