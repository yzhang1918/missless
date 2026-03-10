export const DECISION_LABELS = ["deep_read", "skim", "skip"] as const;

export type DecisionLabel = (typeof DECISION_LABELS)[number];
