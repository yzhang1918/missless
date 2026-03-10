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

test("validate-draft emits summary output by default and JSON diagnostics on failure", async () => {
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
    "{\n  \"source_url\": \"https://example.com/agent-harness\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "extraction_draft.json"),
    JSON.stringify(validDraft, null, 2) + "\n",
    "utf8"
  );

  const success = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "validate-draft", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(success.status, 0, success.stderr);
  assert.match(success.stdout, /Draft is valid/);

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
    [cliEntrypoint.pathname, "validate-draft", "--run-dir", runDir, "--json"],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(failure.status, 1);

  const diagnostics = JSON.parse(failure.stdout) as {
    ok: boolean;
    diagnostics: Array<{ code: string }>;
  };

  assert.equal(diagnostics.ok, false);
  assert.equal(diagnostics.diagnostics[0]?.code, "duplicate_atom_claim");
});
