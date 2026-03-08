export const REVIEW_RENDERING_MODE = "read_only" as const;

export interface ReviewEvidence {
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

export interface ReviewAtom {
  readonly claim: string;
  readonly significance: string;
  readonly evidence: readonly ReviewEvidence[];
}

export interface ReviewBundle {
  readonly generated_at: string;
  readonly run_dir: string;
  readonly tldr: string;
  readonly decision: "deep_read" | "skim" | "skip";
  readonly decision_reasons: readonly string[];
  readonly atoms: readonly ReviewAtom[];
  readonly canonical_text: string;
}

interface RenderedHighlight {
  readonly id: string;
  readonly start: number;
  readonly end: number;
  readonly keys: readonly string[];
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&#39;");
}

function collectHighlights(bundle: ReviewBundle): {
  readonly highlights: readonly RenderedHighlight[];
  readonly highlightIdByRange: ReadonlyMap<string, string>;
} {
  const rawHighlights = bundle.atoms.flatMap((atom) =>
    atom.evidence.map((evidence: ReviewEvidence) => ({
      start: evidence.char_range.start,
      end: evidence.char_range.end,
      key: `${evidence.char_range.start}:${evidence.char_range.end}`
    }))
  );
  rawHighlights.sort(
    (left, right) => left.start - right.start || left.end - right.end
  );

  const merged: Array<{ start: number; end: number; keys: string[] }> = [];

  for (const highlight of rawHighlights) {
    const last = merged.at(-1);

    if (last !== undefined && highlight.start <= last.end) {
      last.end = Math.max(last.end, highlight.end);
      last.keys.push(highlight.key);
      continue;
    }

    merged.push({
      start: highlight.start,
      end: highlight.end,
      keys: [highlight.key]
    });
  }

  const highlightIdByRange = new Map<string, string>();
  const highlights = merged.map((highlight, index) => {
    const id = `highlight-${index}`;

    highlight.keys.forEach((key) => {
      highlightIdByRange.set(key, id);
    });

    return {
      id,
      start: highlight.start,
      end: highlight.end,
      keys: [...highlight.keys]
    };
  });

  return {
    highlights,
    highlightIdByRange
  };
}

function renderCanonicalText(
  canonicalText: string,
  highlights: readonly RenderedHighlight[]
): string {
  let cursor = 0;
  let html = "";

  for (const highlight of highlights) {
    html += escapeHtml(canonicalText.slice(cursor, highlight.start));
    html += `<mark id="${highlight.id}" class="evidence-highlight">${escapeHtml(
      canonicalText.slice(highlight.start, highlight.end)
    )}</mark>`;
    cursor = highlight.end;
  }

  html += escapeHtml(canonicalText.slice(cursor));

  return html.replaceAll("\n", "<br />\n");
}

export function renderReviewHtml(bundle: ReviewBundle): string {
  const { highlights, highlightIdByRange } = collectHighlights(bundle);
  const atomsHtml = bundle.atoms
    .map((atom: ReviewAtom, atomIndex: number) => {
      const evidenceHtml = atom.evidence
        .map((evidence: ReviewEvidence) => {
          const highlightId =
            highlightIdByRange.get(
              `${evidence.char_range.start}:${evidence.char_range.end}`
            ) ?? "";

          return [
            "<li>",
            `<a href="#${highlightId}">${escapeHtml(evidence.exact)}</a>`,
            `<div class="evidence-excerpt">${escapeHtml(
              evidence.context_excerpt
            )}</div>`,
            "</li>"
          ].join("");
        })
        .join("");

      return [
        `<article class="atom-card" id="atom-${atomIndex}">`,
        `<h3>${escapeHtml(atom.claim)}</h3>`,
        `<p class="atom-significance">${escapeHtml(atom.significance)}</p>`,
        evidenceHtml === ""
          ? "<p class=\"atom-empty\">No evidence anchored.</p>"
          : `<ol class="atom-evidence">${evidenceHtml}</ol>`,
        "</article>"
      ].join("");
    })
    .join("");

  const reasonsHtml = bundle.decision_reasons
    .map((reason: string) => `<li>${escapeHtml(reason)}</li>`)
    .join("");

  return [
    "<!doctype html>",
    "<html lang=\"en\">",
    "<head>",
    "  <meta charset=\"utf-8\" />",
    "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />",
    "  <title>missless review package</title>",
    "  <style>",
    "    :root {",
    "      color-scheme: light;",
    "      --bg: #f6f2ea;",
    "      --panel: #fffdf8;",
    "      --ink: #1c1b18;",
    "      --muted: #635d52;",
    "      --line: #d7cfbf;",
    "      --accent: #c95b2b;",
    "      --highlight: #ffe29a;",
    "      --shadow: 0 18px 40px rgba(30, 24, 15, 0.08);",
    "    }",
    "    body {",
    "      margin: 0;",
    "      font-family: Georgia, 'Times New Roman', serif;",
    "      color: var(--ink);",
    "      background: radial-gradient(circle at top, #fff6dd, var(--bg) 45%);",
    "    }",
    "    main {",
    "      max-width: 1200px;",
    "      margin: 0 auto;",
    "      padding: 32px 20px 48px;",
    "    }",
    "    .summary {",
    "      background: var(--panel);",
    "      border: 1px solid var(--line);",
    "      border-radius: 20px;",
    "      padding: 24px;",
    "      box-shadow: var(--shadow);",
    "      margin-bottom: 24px;",
    "    }",
    "    .decision {",
    "      display: inline-block;",
    "      padding: 6px 12px;",
    "      border-radius: 999px;",
    "      background: var(--accent);",
    "      color: white;",
    "      font-weight: 700;",
    "      letter-spacing: 0.04em;",
    "      text-transform: lowercase;",
    "    }",
    "    .layout {",
    "      display: grid;",
    "      grid-template-columns: minmax(0, 1.1fr) minmax(320px, 0.9fr);",
    "      gap: 20px;",
    "    }",
    "    .panel {",
    "      background: var(--panel);",
    "      border: 1px solid var(--line);",
    "      border-radius: 20px;",
    "      padding: 24px;",
    "      box-shadow: var(--shadow);",
    "    }",
    "    .atom-card + .atom-card {",
    "      margin-top: 18px;",
    "      padding-top: 18px;",
    "      border-top: 1px solid var(--line);",
    "    }",
    "    .atom-significance, .evidence-excerpt, .meta {",
    "      color: var(--muted);",
    "    }",
    "    .canonical-text {",
    "      line-height: 1.65;",
    "      white-space: normal;",
    "      word-break: break-word;",
    "    }",
    "    .evidence-highlight {",
    "      background: var(--highlight);",
    "      padding: 0.08em 0.12em;",
    "      border-radius: 0.2em;",
    "    }",
    "    ol, ul {",
    "      padding-left: 20px;",
    "    }",
    "    a {",
    "      color: var(--accent);",
    "    }",
    "    @media (max-width: 900px) {",
    "      .layout {",
    "        grid-template-columns: 1fr;",
    "      }",
    "    }",
    "  </style>",
    "</head>",
    "<body>",
    "  <main>",
    "    <section class=\"summary\">",
    "      <p class=\"meta\">missless review package</p>",
    `      <span class="decision">${escapeHtml(bundle.decision)}</span>`,
    `      <h1>${escapeHtml(bundle.tldr)}</h1>`,
    `      <ul>${reasonsHtml}</ul>`,
    `      <p class="meta">Run directory: ${escapeHtml(bundle.run_dir)}</p>`,
    "    </section>",
    "    <section class=\"layout\">",
    "      <div class=\"panel\">",
    "        <h2>Claim candidates</h2>",
    atomsHtml,
    "      </div>",
    "      <div class=\"panel\">",
    "        <h2>Canonical text</h2>",
    `        <div class="canonical-text">${renderCanonicalText(
      bundle.canonical_text,
      highlights
    )}</div>`,
    "      </div>",
    "    </section>",
    "  </main>",
    "</body>",
    "</html>"
  ].join("\n");
}
