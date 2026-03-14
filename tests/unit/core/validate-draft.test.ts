import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  getRunArtifactPaths,
  type ExtractionDraft
} from "../../../packages/contracts/src/index.ts";
import { validateDraftInRunDir } from "../../../packages/core/src/index.ts";

const fixtureDraftPath = new URL(
  "../../fixtures/drafts/valid-extraction-draft.json",
  import.meta.url
);
const fixtureCanonicalPath = new URL(
  "../../fixtures/jina/harness-engineering.md",
  import.meta.url
);
const fixtureSourceArtifact =
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
  ].join("\n") + "\n";

async function loadFixtureDraft(): Promise<ExtractionDraft> {
  return JSON.parse(
    await readFile(fixtureDraftPath, "utf8")
  ) as ExtractionDraft;
}

async function createFixtureRun(
  runName: string,
  options: {
    draft?: unknown;
    writeCanonicalText?: boolean;
    writeDraft?: boolean;
  } = {}
): Promise<{ runDir: string; paths: ReturnType<typeof getRunArtifactPaths> }> {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-validate-"));
  const runDir = join(runsRoot, runName);
  const paths = getRunArtifactPaths(runDir);
  const shouldWriteCanonicalText = options.writeCanonicalText ?? true;
  const shouldWriteDraft = options.writeDraft ?? true;
  const draft = options.draft ?? (await loadFixtureDraft());

  await mkdir(runDir, { recursive: true });
  await writeFile(
    paths.runManifest,
    `{\n  "run_id": "${runName}",\n  "stage": "normalized"\n}\n`,
    "utf8"
  );
  await writeFile(
    paths.source,
    fixtureSourceArtifact,
    "utf8"
  );

  if (shouldWriteCanonicalText) {
    await writeFile(paths.canonicalText, await readFile(fixtureCanonicalPath, "utf8"), "utf8");
  }

  if (shouldWriteDraft) {
    const draftText =
      typeof draft === "string" ? draft : JSON.stringify(draft, null, 2) + "\n";

    await writeFile(paths.extractionDraft, draftText, "utf8");
  }

  return { runDir, paths };
}

test("validateDraftInRunDir reports missing required artifacts", async () => {
  const { runDir } = await createFixtureRun("run-missing", {
    writeCanonicalText: false,
    writeDraft: false
  });

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.deepEqual(
    result.diagnostics.map((diagnostic) => diagnostic.code).sort(),
    ["canonical_text_missing", "extraction_draft_missing"]
  );
});

test("validateDraftInRunDir rejects malformed JSON drafts", async () => {
  const { runDir } = await createFixtureRun("run-invalid-json", {
    draft: "{ not valid json }\n"
  });

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "extraction_draft_invalid_json");
});

test("validateDraftInRunDir rejects invalid run manifests", async () => {
  const { runDir, paths } = await createFixtureRun("run-invalid-manifest");

  await writeFile(paths.runManifest, "{ not valid json }\n", "utf8");

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "run_manifest_invalid_json");
});

test("validateDraftInRunDir rejects schema violations", async () => {
  const draft = await loadFixtureDraft();
  const invalidDraft = {
    ...draft,
    atom_candidates: draft.atom_candidates.map((candidate, index) =>
      index === 0 ? { claim: candidate.claim } : candidate
    )
  };
  const { runDir } = await createFixtureRun("run-schema-violation", {
    draft: invalidDraft
  });

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "schema_violation");
});

test("validateDraftInRunDir rejects duplicate atom claims", async () => {
  const draft = await loadFixtureDraft();
  const duplicatedDraft = {
    ...draft,
    atom_candidates: draft.atom_candidates.map((candidate, index) =>
      index === 1
        ? {
            ...candidate,
            claim: draft.atom_candidates[0]?.claim ?? candidate.claim
          }
        : candidate
    )
  };
  const { runDir } = await createFixtureRun("run-duplicate", {
    draft: duplicatedDraft
  });

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "duplicate_atom_claim");
});

test("validateDraftInRunDir rejects selectors without prefix or suffix context", async () => {
  const draft = await loadFixtureDraft();
  const invalidDraft = {
    ...draft,
    atom_candidates: draft.atom_candidates.map((candidate, index) =>
      index === 1
        ? {
            ...candidate,
            evidence_selectors: candidate.evidence_selectors.map((selector) => ({
              exact: selector.exact
            }))
          }
        : candidate
    )
  };
  const { runDir } = await createFixtureRun("run-missing-selector-context", {
    draft: invalidDraft
  });

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "selector_missing_context");
});

test("validateDraftInRunDir rejects empty self_check objects", async () => {
  const draft = await loadFixtureDraft();
  const invalidDraft = {
    ...draft,
    self_check: {}
  };
  const { runDir } = await createFixtureRun("run-empty-self-check", {
    draft: invalidDraft
  });

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "self_check_empty");
});
