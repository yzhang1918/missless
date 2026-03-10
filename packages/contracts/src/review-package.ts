import type { DecisionLabel } from "./decision.js";

export interface RunDiagnostic {
  readonly code: string;
  readonly message: string;
  readonly path?: string;
  readonly details?: Readonly<Record<string, unknown>>;
}

export interface CharRange {
  readonly start: number;
  readonly end: number;
}

export interface AnchoredEvidence {
  readonly selector_index: number;
  readonly exact: string;
  readonly prefix?: string;
  readonly suffix?: string;
  readonly char_range: CharRange;
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
  readonly diagnostics: readonly RunDiagnostic[];
}

export interface ReviewBundle {
  readonly generated_at: string;
  readonly run_dir: string;
  readonly tldr: string;
  readonly decision: DecisionLabel;
  readonly decision_reasons: readonly string[];
  readonly atoms: readonly AnchoredAtom[];
  readonly canonical_text: string;
}
