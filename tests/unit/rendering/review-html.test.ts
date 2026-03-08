import assert from "node:assert/strict";
import test from "node:test";

import {
  renderReviewHtml,
  type ReviewBundle
} from "../../../packages/rendering/src/index.ts";

test("renderReviewHtml includes key review content and highlighted evidence", () => {
  const bundle: ReviewBundle = {
    generated_at: "2026-03-08T12:00:00.000Z",
    run_dir: "/tmp/missless/run-review",
    tldr:
      "Harness engineering argues that agent systems work best when repository structure and runtime legibility are deliberately designed.",
    decision: "deep_read",
    decision_reasons: [
      "It contains portable operating patterns rather than only opinion."
    ],
    canonical_text:
      "Repository-local artifacts should act as the system of record for agent work.\n",
    atoms: [
      {
        claim:
          "Repository-local artifacts should act as the system of record for agent work.",
        significance: "This captures the repository-legibility requirement.",
        evidence: [
          {
            selector_index: 0,
            exact: "system of record",
            prefix: "should act as the",
            suffix: "for agent work",
            char_range: {
              start: 46,
              end: 62
            },
            context_excerpt:
              "Repository-local artifacts should act as the system of record for agent work."
          }
        ]
      }
    ]
  };

  const html = renderReviewHtml(bundle);

  assert.match(html, /Harness engineering argues/);
  assert.match(html, /deep_read/);
  assert.match(html, /Repository-local artifacts should act as the system of record/);
  assert.match(html, /<mark/);
});
