import { createHash } from "node:crypto";
import { readFile, stat, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

import {
  getRunArtifactPaths
} from "@missless/contracts";
import type {
  EvidenceSelector,
  ExtractionDraft
} from "@missless/contracts";

import { validateDraftInRunDir } from "../diagnostics/validate-draft.js";

const CONTEXT_WINDOW = 48;

export interface EvidenceDiagnostic {
  readonly code: string;
  readonly message: string;
  readonly path?: string;
  readonly details?: Readonly<Record<string, unknown>>;
}

export interface AnchoredEvidence {
  readonly selector_index: number;
  readonly exact: string;
  readonly prefix?: string;
  readonly suffix?: string;
  readonly char_range: {
    readonly start: number;
    readonly end: number;
  };
  readonly context_excerpt: string;
}

export interface AnchoredAtom {
  readonly claim: string;
  readonly significance: string;
  readonly evidence: readonly AnchoredEvidence[];
}

export interface EvidenceAnchoringResult {
  readonly ok: boolean;
  readonly summary: string;
  readonly run_dir: string;
  readonly draft_sha256?: string;
  readonly canonical_text_sha256?: string;
  readonly atoms: readonly AnchoredAtom[];
  readonly diagnostics: readonly EvidenceDiagnostic[];
}

interface TextMatch {
  readonly start: number;
  readonly end: number;
}

function writeJsonFile(path: string, value: unknown): Promise<void> {
  return writeFile(path, JSON.stringify(value, null, 2) + "\n", "utf8");
}

function sha256(input: string): string {
  return createHash("sha256").update(input, "utf8").digest("hex");
}

async function canPersistRunArtifact(runDir: string): Promise<boolean> {
  try {
    const result = await stat(runDir);
    return result.isDirectory();
  } catch (error) {
    if (
      error instanceof Error &&
      "code" in error &&
      (error.code === "ENOENT" || error.code === "ENOTDIR")
    ) {
      return false;
    }

    throw error;
  }
}

function findExactMatches(text: string, exact: string): TextMatch[] {
  const matches: TextMatch[] = [];
  let fromIndex = 0;

  while (fromIndex < text.length) {
    const start = text.indexOf(exact, fromIndex);

    if (start === -1) {
      break;
    }

    matches.push({
      start,
      end: start + exact.length
    });
    fromIndex = start + 1;
  }

  return matches;
}

function matchesContext(
  text: string,
  match: TextMatch,
  selector: EvidenceSelector
): boolean {
  const normalizeWhitespace = (value: string): string =>
    value.replace(/\s+/gu, " ").trim();
  const before = text.slice(
    Math.max(0, match.start - (selector.prefix?.length ?? 0) - CONTEXT_WINDOW),
    match.start
  );
  const after = text.slice(
    match.end,
    Math.min(
      text.length,
      match.end + (selector.suffix?.length ?? 0) + CONTEXT_WINDOW
    )
  );

  return (
    (selector.prefix === undefined ||
      normalizeWhitespace(before).includes(
        normalizeWhitespace(selector.prefix)
      )) &&
    (selector.suffix === undefined ||
      normalizeWhitespace(after).includes(normalizeWhitespace(selector.suffix)))
  );
}

function getContextExcerpt(text: string, match: TextMatch): string {
  const lineStart = text.lastIndexOf("\n", match.start - 1);
  const excerptStart = lineStart === -1 ? 0 : lineStart + 1;
  const lineEnd = text.indexOf("\n", match.end);
  const excerptEnd = lineEnd === -1 ? text.length : lineEnd;

  return text.slice(excerptStart, excerptEnd);
}

function anchorSelector(
  canonicalText: string,
  selector: EvidenceSelector,
  atomIndex: number,
  selectorIndex: number
):
  | { readonly ok: true; readonly evidence: AnchoredEvidence }
  | { readonly ok: false; readonly diagnostics: readonly EvidenceDiagnostic[] } {
  const matches = findExactMatches(canonicalText, selector.exact);

  if (matches.length === 0) {
    return {
      ok: false,
      diagnostics: [
        {
          code: "selector_exact_not_found",
          message: `Could not find exact quote for atom ${atomIndex}, selector ${selectorIndex}.`,
          path: `/atom_candidates/${atomIndex}/evidence_selectors/${selectorIndex}`,
          details: {
            exact: selector.exact
          }
        }
      ]
    };
  }

  const contextualMatches = matches.filter((match) =>
    matchesContext(canonicalText, match, selector)
  );

  if (contextualMatches.length === 0) {
    return {
      ok: false,
      diagnostics: [
        {
          code: "selector_context_mismatch",
          message: `Context did not narrow the exact quote for atom ${atomIndex}, selector ${selectorIndex}.`,
          path: `/atom_candidates/${atomIndex}/evidence_selectors/${selectorIndex}`,
          details: {
            exact: selector.exact,
            prefix: selector.prefix,
            suffix: selector.suffix,
            exact_match_count: matches.length
          }
        }
      ]
    };
  }

  if (contextualMatches.length > 1) {
    return {
      ok: false,
      diagnostics: [
        {
          code: "selector_ambiguous",
          message: `Selector for atom ${atomIndex}, selector ${selectorIndex} matched multiple evidence ranges.`,
          path: `/atom_candidates/${atomIndex}/evidence_selectors/${selectorIndex}`,
          details: {
            exact: selector.exact,
            match_count: contextualMatches.length
          }
        }
      ]
    };
  }

  const match = contextualMatches[0]!;

  return {
    ok: true,
    evidence: {
      selector_index: selectorIndex,
      exact: selector.exact,
      prefix: selector.prefix,
      suffix: selector.suffix,
      char_range: {
        start: match.start,
        end: match.end
      },
      context_excerpt: getContextExcerpt(canonicalText, match)
    }
  };
}

export async function anchorEvidenceInRunDir(
  runDir: string
): Promise<EvidenceAnchoringResult> {
  const resolvedRunDir = resolve(runDir);
  const artifactPaths = getRunArtifactPaths(resolvedRunDir);
  const draftValidation = await validateDraftInRunDir(resolvedRunDir);

  if (!draftValidation.ok) {
    const failedResult: EvidenceAnchoringResult = {
      ok: false,
      summary:
        "Cannot anchor evidence because validate-draft did not pass. Re-run with --json for details.",
      run_dir: resolvedRunDir,
      atoms: [],
      diagnostics: draftValidation.diagnostics
    };

    if (await canPersistRunArtifact(resolvedRunDir)) {
      await writeJsonFile(artifactPaths.evidenceResult, failedResult);
    }

    return failedResult;
  }

  const [canonicalText, draftText] = await Promise.all([
    readFile(artifactPaths.canonicalText, "utf8"),
    readFile(artifactPaths.extractionDraft, "utf8")
  ]);
  const draft = JSON.parse(draftText) as ExtractionDraft;
  const draftSha256 = sha256(draftText);
  const canonicalTextSha256 = sha256(canonicalText);
  const atoms: AnchoredAtom[] = [];
  const diagnostics: EvidenceDiagnostic[] = [];

  draft.atom_candidates.forEach((candidate, atomIndex) => {
    const evidence: AnchoredEvidence[] = [];

    candidate.evidence_selectors.forEach((selector, selectorIndex) => {
      const anchored = anchorSelector(
        canonicalText,
        selector,
        atomIndex,
        selectorIndex
      );

      if (anchored.ok) {
        evidence.push(anchored.evidence);
        return;
      }

      diagnostics.push(...anchored.diagnostics);
    });

    atoms.push({
      claim: candidate.claim,
      significance: candidate.significance,
      evidence
    });
  });

  const result: EvidenceAnchoringResult = {
    ok: diagnostics.length === 0,
    summary:
      diagnostics.length === 0
        ? `Evidence anchored for ${atoms.length} atom candidate(s).`
        : `Evidence anchoring failed with ${diagnostics.length} issue(s).`,
    run_dir: resolvedRunDir,
    draft_sha256: draftSha256,
    canonical_text_sha256: canonicalTextSha256,
    atoms,
    diagnostics
  };

  await writeJsonFile(artifactPaths.evidenceResult, result);

  return result;
}
