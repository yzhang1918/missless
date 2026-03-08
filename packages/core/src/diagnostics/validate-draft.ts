import { readFile } from "node:fs/promises";
import { resolve } from "node:path";

import {
  createExtractionDraftValidator,
  getRunArtifactPaths,
  type ExtractionDraft
} from "@missless/contracts";

export interface ValidationDiagnostic {
  readonly code: string;
  readonly message: string;
  readonly path?: string;
  readonly details?: Readonly<Record<string, unknown>>;
}

export interface DraftValidationResult {
  readonly ok: boolean;
  readonly summary: string;
  readonly diagnostics: readonly ValidationDiagnostic[];
  readonly runDir: string;
  readonly artifacts: {
    readonly runManifest: string;
    readonly source: string;
    readonly canonicalText: string;
    readonly extractionDraft: string;
  };
  readonly decision?: ExtractionDraft["decision"];
  readonly atomCount?: number;
}

async function readUtf8(
  path: string,
  missingCode: string
): Promise<
  | { readonly ok: true; readonly value: string }
  | { readonly ok: false; readonly diagnostic: ValidationDiagnostic }
> {
  try {
    return {
      ok: true,
      value: await readFile(path, "utf8")
    };
  } catch (error) {
    if (error instanceof Error && "code" in error && error.code === "ENOENT") {
      return {
        ok: false,
        diagnostic: {
          code: missingCode,
          message: `Required artifact is missing: ${path}`,
          path
        }
      };
    }

    throw error;
  }
}

function normalizeClaim(claim: string): string {
  return claim.trim().replace(/\s+/gu, " ").toLowerCase();
}

function findDuplicateClaimDiagnostics(
  draft: ExtractionDraft
): ValidationDiagnostic[] {
  const firstClaimIndex = new Map<string, number>();
  const diagnostics: ValidationDiagnostic[] = [];

  draft.atom_candidates.forEach((candidate, index) => {
    const key = normalizeClaim(candidate.claim);
    const seenIndex = firstClaimIndex.get(key);

    if (seenIndex === undefined) {
      firstClaimIndex.set(key, index);
      return;
    }

    diagnostics.push({
      code: "duplicate_atom_claim",
      message: `Atom candidate ${index} duplicates atom candidate ${seenIndex}.`,
      path: `/atom_candidates/${index}/claim`,
      details: {
        first_index: seenIndex,
        duplicate_index: index,
        normalized_claim: key
      }
    });
  });

  return diagnostics;
}

function findSelectorContextDiagnostics(
  draft: ExtractionDraft
): ValidationDiagnostic[] {
  const diagnostics: ValidationDiagnostic[] = [];

  draft.atom_candidates.forEach((candidate, atomIndex) => {
    candidate.evidence_selectors.forEach((selector, selectorIndex) => {
      if (selector.prefix !== undefined || selector.suffix !== undefined) {
        return;
      }

      diagnostics.push({
        code: "selector_missing_context",
        message: `Evidence selector ${selectorIndex} for atom ${atomIndex} must include prefix or suffix context.`,
        path: `/atom_candidates/${atomIndex}/evidence_selectors/${selectorIndex}`,
        details: {
          exact: selector.exact
        }
      });
    });
  });

  return diagnostics;
}

function findSelfCheckDiagnostics(
  draft: ExtractionDraft
): ValidationDiagnostic[] {
  if (draft.self_check === undefined) {
    return [];
  }

  if (
    draft.self_check.corrected !== undefined ||
    draft.self_check.uncertain !== undefined
  ) {
    return [];
  }

  return [
    {
      code: "self_check_empty",
      message: "self_check must contain corrected or uncertain when present.",
      path: "/self_check"
    }
  ];
}

function summarizeFailure(diagnostics: readonly ValidationDiagnostic[]): string {
  return `Draft validation failed with ${diagnostics.length} issue(s). Re-run with --json for details.`;
}

export async function validateDraftInRunDir(
  runDir: string
): Promise<DraftValidationResult> {
  const resolvedRunDir = resolve(runDir);
  const artifactPaths = getRunArtifactPaths(resolvedRunDir);
  const diagnostics: ValidationDiagnostic[] = [];

  const canonicalText = await readUtf8(
    artifactPaths.canonicalText,
    "canonical_text_missing"
  );
  const draftText = await readUtf8(
    artifactPaths.extractionDraft,
    "extraction_draft_missing"
  );

  if (!canonicalText.ok) {
    diagnostics.push(canonicalText.diagnostic);
  }

  if (!draftText.ok) {
    diagnostics.push(draftText.diagnostic);
  }

  const canonicalTextValue = canonicalText.ok ? canonicalText.value : undefined;
  const draftTextValue = draftText.ok ? draftText.value : undefined;

  if (
    diagnostics.length > 0 ||
    canonicalTextValue === undefined ||
    draftTextValue === undefined
  ) {
    return {
      ok: false,
      summary: summarizeFailure(diagnostics),
      diagnostics,
      runDir: resolvedRunDir,
      artifacts: {
        runManifest: artifactPaths.runManifest,
        source: artifactPaths.source,
        canonicalText: artifactPaths.canonicalText,
        extractionDraft: artifactPaths.extractionDraft
      }
    };
  }

  let parsedDraft: unknown;

  try {
    parsedDraft = JSON.parse(draftTextValue);
  } catch (error) {
    const diagnostic: ValidationDiagnostic = {
      code: "extraction_draft_invalid_json",
      message:
        error instanceof Error
          ? error.message
          : "Extraction draft could not be parsed as JSON.",
      path: artifactPaths.extractionDraft
    };

    return {
      ok: false,
      summary: summarizeFailure([diagnostic]),
      diagnostics: [diagnostic],
      runDir: resolvedRunDir,
      artifacts: {
        runManifest: artifactPaths.runManifest,
        source: artifactPaths.source,
        canonicalText: artifactPaths.canonicalText,
        extractionDraft: artifactPaths.extractionDraft
      }
    };
  }

  const validator = createExtractionDraftValidator();

  if (!validator.validate(parsedDraft)) {
    const schemaDiagnostics =
      validator.errors()?.map((error) => ({
        code: "schema_violation",
        message: error.message ?? "Schema validation failed.",
        path: error.instancePath === "" ? "/" : error.instancePath,
        details: {
          keyword: error.keyword,
          schema_path: error.schemaPath,
          params: error.params
        }
      })) ?? [];

    return {
      ok: false,
      summary: summarizeFailure(schemaDiagnostics),
      diagnostics: schemaDiagnostics,
      runDir: resolvedRunDir,
      artifacts: {
        runManifest: artifactPaths.runManifest,
        source: artifactPaths.source,
        canonicalText: artifactPaths.canonicalText,
        extractionDraft: artifactPaths.extractionDraft
      }
    };
  }

  const draft = parsedDraft as ExtractionDraft;
  const contractDiagnostics = [
    ...findDuplicateClaimDiagnostics(draft),
    ...findSelectorContextDiagnostics(draft),
    ...findSelfCheckDiagnostics(draft)
  ];

  if (contractDiagnostics.length > 0) {
    return {
      ok: false,
      summary: summarizeFailure(contractDiagnostics),
      diagnostics: contractDiagnostics,
      runDir: resolvedRunDir,
      artifacts: {
        runManifest: artifactPaths.runManifest,
        source: artifactPaths.source,
        canonicalText: artifactPaths.canonicalText,
        extractionDraft: artifactPaths.extractionDraft
      },
      decision: draft.decision,
      atomCount: draft.atom_candidates.length
    };
  }

  return {
    ok: true,
    summary: `Draft is valid: ${draft.decision} with ${draft.atom_candidates.length} atom candidate(s).`,
    diagnostics: [],
    runDir: resolvedRunDir,
    artifacts: {
      runManifest: artifactPaths.runManifest,
      source: artifactPaths.source,
      canonicalText: artifactPaths.canonicalText,
      extractionDraft: artifactPaths.extractionDraft
    },
    decision: draft.decision,
    atomCount: draft.atom_candidates.length
  };
}
