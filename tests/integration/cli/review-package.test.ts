import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import test from "node:test";

import {
  getCleanupTokenPath,
  writeCleanupToken
} from "../../../packages/core/src/runtime/cleanup-token.ts";
import {
  getRunAttestationPath,
  getRunRegistryPath
} from "../../../packages/core/src/runtime/run-registry.ts";

const repoRoot = new URL("../../../", import.meta.url);
const cliEntrypoint = new URL("../../../apps/cli/dist/index.js", import.meta.url);
const fixtureDraftPath = new URL("../../fixtures/drafts/valid-extraction-draft.json", import.meta.url);
const fixtureCanonicalPath = new URL("../../fixtures/jina/harness-engineering.md", import.meta.url);

async function seedReviewRun(runDir: string): Promise<void> {
  await mkdir(runDir, { recursive: true });
  await writeFile(
    join(runDir, "run.json"),
    [
      "{",
      '  "run_id": "' + runDir.split("/").at(-1) + '",',
      '  "created_at": "2026-03-09T00:00:00.000Z",',
      '  "stage": "normalized",',
      '  "source_kind": "url",',
      '  "source_url": "https://example.com/agent-harness"',
      "}"
    ].join("\n") + "\n",
    "utf8"
  );
  await writeFile(
    join(runDir, "source.json"),
    "{\n  \"source_url\": \"https://example.com/agent-harness\"\n}\n",
    "utf8"
  );
  await mkdir(dirname(getRunRegistryPath(runDir)), { recursive: true });
  await writeFile(
    getRunRegistryPath(runDir),
    JSON.stringify(
      {
        version: 1,
        run_dirs: [runDir]
      },
      null,
      2
    ) + "\n",
    "utf8"
  );
  await mkdir(dirname(getRunAttestationPath(runDir)), { recursive: true });
  await writeFile(
    getRunAttestationPath(runDir),
    JSON.stringify(
      {
        version: 1,
        run_dir: runDir
      },
      null,
      2
    ) + "\n",
    "utf8"
  );
  await writeCleanupToken(runDir);
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
}

function runCli(command: string, runDir: string) {
  return spawnSync(
    process.execPath,
    [cliEntrypoint.pathname, command, "--run-dir", runDir],
    {
      cwd: repoRoot,
      encoding: "utf8",
      env: process.env
    }
  );
}

test("anchor-evidence and render-review produce the first review package artifacts", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-review");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);

  assert.equal(anchored.status, 0, anchored.stderr);

  const rendered = runCli("render-review", runDir);

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

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);

  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

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

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /anchor-evidence is rerun for the current extraction draft and canonical text/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review rejects stale evidence generated from an older canonical snapshot", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-stale-canonical");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);

  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await writeFile(
    join(runDir, "canonical_text.md"),
    `${await readFile(fixtureCanonicalPath, "utf8")}\nChanged after anchoring.\n`,
    "utf8"
  );

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /anchor-evidence is rerun for the current extraction draft and canonical text/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review translates missing evidence artifacts into a stable runtime error and removes stale review outputs", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-missing-evidence");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(join(runDir, "evidence_result.json"));

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /Cannot render review until anchor-evidence succeeds for the run/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review removes stale review outputs even when source.json is missing", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-missing-source");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(join(runDir, "source.json"));
  const staleDraft = JSON.parse(
    await readFile(join(runDir, "extraction_draft.json"), "utf8")
  ) as {
    tldr: string;
  };
  staleDraft.tldr = `${staleDraft.tldr} Changed after rendering.`;
  await writeFile(
    join(runDir, "extraction_draft.json"),
    JSON.stringify(staleDraft, null, 2) + "\n",
    "utf8"
  );

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /anchor-evidence is rerun for the current extraction draft and canonical text/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review removes stale review outputs when run.json is missing after a successful render", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-missing-manifest");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(join(runDir, "run.json"));

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review removes stale review outputs when run.json has an untrusted stage", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-untrusted-manifest");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await writeFile(
    join(runDir, "run.json"),
    [
      "{",
      '  "run_id": "run-untrusted-manifest",',
      '  "created_at": "2026-03-09T00:00:00.000Z",',
      '  "stage": "draft",',
      '  "source_kind": "url",',
      '  "source_url": "https://example.com/agent-harness"',
      "}"
    ].join("\n") + "\n",
    "utf8"
  );

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review removes stale review outputs when run.json is malformed after a successful render", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-malformed-manifest");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await writeFile(join(runDir, "run.json"), "{not-json\n", "utf8");

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review removes stale review outputs when only review.html remains and run.json becomes invalid", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-html-only");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(join(runDir, "review_bundle.json"));
  await writeFile(join(runDir, "run.json"), "{not-json\n", "utf8");

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review refuses cleanup when stale outputs are no longer trusted by the runtime registry", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-untrusted-cleanup");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(join(runDir, "review_bundle.json"));
  await rm(getRunRegistryPath(runDir), { force: true });
  await rm(getRunAttestationPath(runDir), { force: true });
  await rm(getCleanupTokenPath(runDir), { force: true });
  await writeFile(join(runDir, "run.json"), "{not-json\n", "utf8");

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await stat(join(runDir, "review.html"));
});

test("render-review still cleans stale outputs when the cleanup registry is corrupt but the per-run attestation is intact", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-corrupt-registry");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await writeFile(getRunRegistryPath(runDir), "{not-json\n", "utf8");
  await writeFile(join(runDir, "run.json"), "{not-json\n", "utf8");

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review still cleans stale outputs when only the runs-root registry remains trusted", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-registry-only");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(getRunAttestationPath(runDir), { force: true });
  await rm(getCleanupTokenPath(runDir), { force: true });
  await writeFile(join(runDir, "run.json"), "{not-json\n", "utf8");

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review still cleans stale outputs when only the signed run-local token remains trusted", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-token-only");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(getRunRegistryPath(runDir), { force: true });
  await rm(getRunAttestationPath(runDir), { force: true });
  await writeFile(join(runDir, "run.json"), "{not-json\n", "utf8");

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /render-review requires a valid missless run\.json before it can rebuild review artifacts/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review removes stale review outputs when canonical_text.md is missing", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-missing-canonical");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(join(runDir, "canonical_text.md"));

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /Cannot render review until canonical_text\.md exists for the run/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});

test("render-review removes stale review outputs when extraction_draft.json is missing", async () => {
  const runsRoot = await mkdtemp(join(tmpdir(), "missless-run-"));
  const runDir = join(runsRoot, "run-missing-draft");

  await seedReviewRun(runDir);

  const anchored = runCli("anchor-evidence", runDir);
  assert.equal(anchored.status, 0, anchored.stderr);

  const firstRender = runCli("render-review", runDir);
  assert.equal(firstRender.status, 0, firstRender.stderr);

  await rm(join(runDir, "extraction_draft.json"));

  const rendered = runCli("render-review", runDir);

  assert.equal(rendered.status, 1);
  assert.match(
    rendered.stderr,
    /Cannot render review until extraction_draft\.json exists for the run/
  );
  await assert.rejects(
    () => stat(join(runDir, "review_bundle.json")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
  await assert.rejects(
    () => stat(join(runDir, "review.html")),
    (error: unknown) =>
      error instanceof Error &&
      "code" in error &&
      error.code === "ENOENT"
  );
});
