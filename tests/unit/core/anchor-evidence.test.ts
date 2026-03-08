import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  getRunArtifactPaths,
  type ExtractionDraft
} from "../../../packages/contracts/src/index.ts";
import { anchorEvidenceInRunDir } from "../../../packages/core/src/index.ts";

const fixtureDraftPath = new URL(
  "../../fixtures/drafts/valid-extraction-draft.json",
  import.meta.url
);
const fixtureCanonicalPath = new URL(
  "../../fixtures/jina/harness-engineering.md",
  import.meta.url
);

async function loadFixtureDraft(): Promise<ExtractionDraft> {
  return JSON.parse(
    await readFile(fixtureDraftPath, "utf8")
  ) as ExtractionDraft;
}

async function createFixtureRun(
  runName: string,
  draft: ExtractionDraft | Record<string, unknown>
): Promise<{ runDir: string; paths: ReturnType<typeof getRunArtifactPaths> }> {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-anchor-"));
  const runDir = join(runsRoot, runName);
  const paths = getRunArtifactPaths(runDir);

  await mkdir(runDir, { recursive: true });
  await writeFile(paths.runManifest, `{\n  "run_id": "${runName}"\n}\n`, "utf8");
  await writeFile(
    paths.source,
    '{\n  "source_url": "https://example.com/agent-harness"\n}\n',
    "utf8"
  );
  await writeFile(paths.canonicalText, await readFile(fixtureCanonicalPath, "utf8"), "utf8");
  await writeFile(paths.extractionDraft, JSON.stringify(draft, null, 2) + "\n", "utf8");

  return { runDir, paths };
}

test("anchorEvidenceInRunDir materializes selector matches into char ranges", async () => {
  const draft = await loadFixtureDraft();
  const { runDir } = await createFixtureRun("run-anchor", draft);

  const result = await anchorEvidenceInRunDir(runDir);

  assert.equal(result.ok, true, result.summary);
  assert.equal(result.atoms.length, 2);
  assert.equal(result.atoms[0]?.evidence.length, 1);
  assert.ok((result.atoms[0]?.evidence[0]?.char_range.start ?? -1) >= 0);
  assert.ok(
    (result.atoms[0]?.evidence[0]?.char_range.end ?? 0) >
      (result.atoms[0]?.evidence[0]?.char_range.start ?? 0)
  );
});

test("anchorEvidenceInRunDir reports missing exact quotes", async () => {
  const draft = await loadFixtureDraft();
  draft.atom_candidates[0] = {
    ...draft.atom_candidates[0],
    evidence_selectors: [
      {
        exact: "missing exact quote",
        prefix: "should act as the",
        suffix: "for agent work"
      }
    ]
  };
  const { runDir, paths } = await createFixtureRun("run-missing-exact", draft);

  const result = await anchorEvidenceInRunDir(runDir);
  const persisted = JSON.parse(
    await readFile(paths.evidenceResult, "utf8")
  ) as { ok: boolean; diagnostics: Array<{ code: string }> };

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "selector_exact_not_found");
  assert.equal(persisted.ok, false);
});

test("anchorEvidenceInRunDir reports selector context mismatches", async () => {
  const draft = await loadFixtureDraft();
  draft.atom_candidates[0] = {
    ...draft.atom_candidates[0],
    evidence_selectors: [
      {
        exact: "system of record",
        prefix: "wrong prefix",
        suffix: "for agent work"
      }
    ]
  };
  const { runDir } = await createFixtureRun("run-context-mismatch", draft);

  const result = await anchorEvidenceInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "selector_context_mismatch");
});

test("anchorEvidenceInRunDir reports ambiguous selectors", async () => {
  const draft = await loadFixtureDraft();
  draft.atom_candidates[0] = {
    ...draft.atom_candidates[0],
    evidence_selectors: [
      {
        exact: "the",
        prefix: " ",
        suffix: " "
      }
    ]
  };
  const { runDir } = await createFixtureRun("run-ambiguous", draft);

  const result = await anchorEvidenceInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "selector_ambiguous");
});

test("anchorEvidenceInRunDir writes failed evidence results when validate-draft fails", async () => {
  const draft = await loadFixtureDraft();
  draft.atom_candidates[1] = {
    ...draft.atom_candidates[1],
    claim: draft.atom_candidates[0]?.claim ?? draft.atom_candidates[1].claim
  };
  const { runDir, paths } = await createFixtureRun("run-invalid-draft", draft);

  const result = await anchorEvidenceInRunDir(runDir);
  const persisted = JSON.parse(
    await readFile(paths.evidenceResult, "utf8")
  ) as { ok: boolean; diagnostics: Array<{ code: string }> };

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "duplicate_atom_claim");
  assert.equal(persisted.ok, false);
  assert.equal(persisted.diagnostics[0]?.code, "duplicate_atom_claim");
});
