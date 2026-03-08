import { Ajv2020, type ErrorObject, type ValidateFunction } from "ajv/dist/2020.js";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

import type { DecisionLabel } from "./decision.js";

export interface EvidenceSelector {
  readonly exact: string;
  readonly prefix?: string;
  readonly suffix?: string;
}

export interface AtomCandidate {
  readonly claim: string;
  readonly significance: string;
  readonly evidence_selectors: readonly EvidenceSelector[];
}

export interface ExtractionSelfCheck {
  readonly corrected?: readonly string[];
  readonly uncertain?: readonly string[];
}

export interface ExtractionDraft {
  readonly tldr: string;
  readonly decision: DecisionLabel;
  readonly decision_reasons: readonly string[];
  readonly atom_candidates: readonly AtomCandidate[];
  readonly self_check?: ExtractionSelfCheck;
}

const extractionDraftSchemaPath = fileURLToPath(
  new URL("../extraction-draft.schema.json", import.meta.url)
);

export interface ExtractionDraftValidator {
  readonly validate: ValidateFunction<ExtractionDraft>;
  readonly errors: () => ErrorObject[] | null | undefined;
}

export function getExtractionDraftSchemaPath(): string {
  return extractionDraftSchemaPath;
}

export function loadExtractionDraftSchema(): Record<string, unknown> {
  return JSON.parse(
    readFileSync(extractionDraftSchemaPath, "utf8")
  ) as Record<string, unknown>;
}

export function createExtractionDraftValidator(): ExtractionDraftValidator {
  const ajv = new Ajv2020({
    allErrors: true,
    strict: true
  });
  const validate = ajv.compile<ExtractionDraft>(loadExtractionDraftSchema());

  return {
    validate,
    errors: () => validate.errors
  };
}
