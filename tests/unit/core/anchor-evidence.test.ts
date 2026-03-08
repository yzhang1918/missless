import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { getRunArtifactPaths } from "../../../packages/contracts/src/index.ts";
import { anchorEvidenceInRunDir } from "../../../packages/core/src/index.ts";

const fixtureDraftPath = new URL(
  "../../fixtures/drafts/valid-extraction-draft.json",
  import.meta.url
);
const fixtureCanonicalPath = new URL(
  "../../fixtures/jina/harness-engineering.md",
  import.meta.url
);

test("anchorEvidenceInRunDir materializes selector matches into char ranges", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-anchor-"));
  const runDir = join(runsRoot, "run-anchor");
  const paths = getRunArtifactPaths(runDir);

  await mkdir(runDir, { recursive: true });
  await writeFile(paths.runManifest, "{\n  \"run_id\": \"run-anchor\"\n}\n", "utf8");
  await writeFile(
    paths.source,
    "{\n  \"source_url\": \"https://example.com/agent-harness\"\n}\n",
    "utf8"
  );
  await writeFile(paths.canonicalText, await readFile(fixtureCanonicalPath, "utf8"), "utf8");
  await writeFile(paths.extractionDraft, await readFile(fixtureDraftPath, "utf8"), "utf8");

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
