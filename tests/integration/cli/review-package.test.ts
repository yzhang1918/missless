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

test("anchor-evidence and render-review produce the first review package artifacts", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-review");

  await mkdir(runDir, { recursive: true });
  await writeFile(
    join(runDir, "run.json"),
    "{\n  \"run_id\": \"run-review\",\n  \"stage\": \"normalized\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "source.json"),
    "{\n  \"source_url\": \"https://example.com/agent-harness\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "canonical_text.md"),
    await readFile(fixtureCanonicalPath, "utf8"),
    "utf8"
  );
  await writeFile(
    join(runDir, "extraction_draft.json"),
    await readFile(fixtureDraftPath, "utf8"),
    "utf8"
  );

  const anchored = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "anchor-evidence", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(anchored.status, 0, anchored.stderr);

  const rendered = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "render-review", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(rendered.status, 0, rendered.stderr);

  const evidenceResult = JSON.parse(
    await readFile(join(runDir, "evidence_result.json"), "utf8")
  ) as { ok: boolean };
  const reviewBundle = JSON.parse(
    await readFile(join(runDir, "review_bundle.json"), "utf8")
  ) as { decision: string };
  const reviewHtml = await readFile(join(runDir, "review.html"), "utf8");

  assert.equal(evidenceResult.ok, true);
  assert.equal(reviewBundle.decision, "deep_read");
  assert.match(reviewHtml, /<mark/);
  assert.match(reviewHtml, /Repository-local artifacts/);
});

test("render-review rejects stale evidence generated from an older draft", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-stale-review");

  await mkdir(runDir, { recursive: true });
  await writeFile(
    join(runDir, "run.json"),
    "{\n  \"run_id\": \"run-stale-review\",\n  \"stage\": \"normalized\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "source.json"),
    "{\n  \"source_url\": \"https://example.com/agent-harness\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "canonical_text.md"),
    await readFile(fixtureCanonicalPath, "utf8"),
    "utf8"
  );
  await writeFile(
    join(runDir, "extraction_draft.json"),
    await readFile(fixtureDraftPath, "utf8"),
    "utf8"
  );

  const anchored = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "anchor-evidence", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(anchored.status, 0, anchored.stderr);

  const staleDraft = JSON.parse(
    await readFile(join(runDir, "extraction_draft.json"), "utf8")
  ) as {
    tldr: string;
    decision_reasons: string[];
  };
  staleDraft.tldr = `${staleDraft.tldr} Updated after anchoring.`;
  staleDraft.decision_reasons = [...staleDraft.decision_reasons, "Late edit"];

  await writeFile(
    join(runDir, "extraction_draft.json"),
    JSON.stringify(staleDraft, null, 2) + "\n",
    "utf8"
  );

  const rendered = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "render-review", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /anchor-evidence is rerun for the current extraction draft and canonical text/
  );
});

test("render-review rejects stale evidence generated from an older canonical snapshot", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-stale-canonical");

  await mkdir(runDir, { recursive: true });
  await writeFile(
    join(runDir, "run.json"),
    "{\n  \"run_id\": \"run-stale-canonical\",\n  \"stage\": \"normalized\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "source.json"),
    "{\n  \"source_url\": \"https://example.com/agent-harness\"\n}\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "canonical_text.md"),
    await readFile(fixtureCanonicalPath, "utf8"),
    "utf8"
  );
  await writeFile(
    join(runDir, "extraction_draft.json"),
    await readFile(fixtureDraftPath, "utf8"),
    "utf8"
  );

  const anchored = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "anchor-evidence", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(anchored.status, 0, anchored.stderr);

  await writeFile(
    join(runDir, "canonical_text.md"),
    `${await readFile(fixtureCanonicalPath, "utf8")}\nChanged after anchoring.\n`,
    "utf8"
  );

  const rendered = spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, "render-review", "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /anchor-evidence is rerun for the current extraction draft and canonical text/
  );
});
