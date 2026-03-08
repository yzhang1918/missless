import assert from "node:assert/strict";
import test from "node:test";

import {
  createExtractionDraftValidator,
  type ExtractionDraft
} from "../../../packages/contracts/src/index.ts";

test("valid extraction drafts satisfy the first-slice schema", () => {
  const validator = createExtractionDraftValidator();
  const draft: ExtractionDraft = {
    tldr:
      "The article argues that agent-first engineering shifts leverage toward repository design, runtime legibility, and strong feedback loops.",
    decision: "deep_read",
    decision_reasons: [
      "The piece contains reusable operating patterns rather than only opinion.",
      "Several operational details still matter beyond the TLDR."
    ],
    atom_candidates: [
      {
        claim:
          "Repository-local artifacts should act as the system of record for agent work.",
        significance:
          "This is the repository-legibility claim that most directly affects missless.",
        evidence_selectors: [
          {
            exact: "system of record",
            prefix: "repository become the",
            suffix: "for the system"
          }
        ]
      },
      {
        claim:
          "Runtime legibility is a prerequisite for agents to validate and debug their own work.",
        significance:
          "This turns observability into a product requirement rather than an afterthought.",
        evidence_selectors: [
          {
            exact: "legible",
            prefix: "application itself needs to be",
            suffix: "to the coding agent"
          }
        ]
      }
    ],
    self_check: {
      corrected: [
        "Separated repository legibility from runtime legibility to avoid duplicate atoms."
      ]
    }
  };

  assert.equal(
    validator.validate(draft),
    true,
    JSON.stringify(validator.errors(), null, 2)
  );
});

test("invalid drafts fail closed with useful diagnostics", () => {
  const validator = createExtractionDraftValidator();
  const invalidDraft = {
    tldr: "A short summary.",
    decision: "read",
    decision_reasons: ["Reasonable sounding but wrong decision label."],
    atom_candidates: [
      {
        claim: "A claim without selector support.",
        significance: "This should fail schema validation."
      }
    ]
  };

  assert.equal(validator.validate(invalidDraft), false);

  const errorSummary = (validator.errors() ?? [])
    .map((error) => `${error.instancePath} ${error.message}`)
    .join("\n");

  assert.match(errorSummary, /decision/);
  assert.match(errorSummary, /atom_candidates\/0/);
});
