import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import { createSchemaValidator } from "../../../packages/contracts/src/index.ts";

test("codex output schema accepts a runtime-compatible extraction draft subset", () => {
  const schema = JSON.parse(
    readFileSync(
      new URL(
        "../../../packages/contracts/extraction-draft.codex-output-schema.json",
        import.meta.url
      ),
      "utf8"
    )
  ) as Record<string, unknown>;
  const draft = {
    tldr:
      "Harness engineering argues that agent systems work best when repository structure and runtime legibility are deliberately designed.",
    decision: "deep_read",
    decision_reasons: [
      "It contains portable operating patterns rather than only opinion.",
      "The summary does not replace the implementation details."
    ],
    atom_candidates: [
      {
        claim:
          "Repository-local artifacts should act as the system of record for agent work.",
        significance: "This captures the repository-legibility requirement.",
        evidence_selectors: [
          {
            exact: "system of record",
            prefix: "should act as the",
            suffix: "for agent work"
          }
        ]
      }
    ]
  };
  const validator = createSchemaValidator(schema);

  assert.equal(
    validator.validate(draft),
    true,
    JSON.stringify(validator.errors(), null, 2)
  );
});
