import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { getRunArtifactPaths } from "../../../packages/contracts/src/index.ts";
import { validateDraftInRunDir } from "../../../packages/core/src/index.ts";

const fixtureDraftPath = new URL(
  "../../fixtures/drafts/valid-extraction-draft.json",
  import.meta.url
);
const fixtureCanonicalPath = new URL(
  "../../fixtures/jina/harness-engineering.md",
  import.meta.url
);

test("validateDraftInRunDir rejects duplicate atom claims", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-validate-"));
  const runDir = join(runsRoot, "run-duplicate");
  const paths = getRunArtifactPaths(runDir);
  const validDraft = JSON.parse(
    await readFile(fixtureDraftPath, "utf8")
  ) as Record<string, unknown>;
  const canonicalText = await readFile(fixtureCanonicalPath, "utf8");
  const atomCandidates = validDraft.atom_candidates as Array<Record<string, unknown>>;

  atomCandidates[1] = {
    ...atomCandidates[1],
    claim: atomCandidates[0]?.claim
  };

  await mkdir(runDir, { recursive: true });
  await writeFile(paths.runManifest, "{\n  \"run_id\": \"run-duplicate\"\n}\n", "utf8");
  await writeFile(
    paths.source,
    "{\n  \"source_url\": \"https://example.com/agent-harness\"\n}\n",
    "utf8"
  );
  await writeFile(paths.canonicalText, canonicalText, "utf8");
  await writeFile(paths.extractionDraft, JSON.stringify(validDraft, null, 2) + "\n", "utf8");

  const result = await validateDraftInRunDir(runDir);

  assert.equal(result.ok, false);
  assert.equal(result.diagnostics[0]?.code, "duplicate_atom_claim");
});
