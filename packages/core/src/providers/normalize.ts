function trimBlankLines(lines: readonly string[]): readonly string[] {
  let start = 0;
  let end = lines.length;

  while (start < end && lines[start]?.trim() === "") {
    start += 1;
  }

  while (end > start && lines[end - 1]?.trim() === "") {
    end -= 1;
  }

  return lines.slice(start, end);
}

export function normalizeProviderText(rawText: string): string {
  const withoutBom = rawText.replace(/^\uFEFF/u, "");
  const normalizedNewlines = withoutBom.replace(/\r\n?/gu, "\n");
  const withoutTrailingSpaces = normalizedNewlines
    .split("\n")
    .map((line) => line.replace(/[ \t]+$/u, ""))
    .join("\n");
  const trimmed = trimBlankLines(withoutTrailingSpaces.split("\n")).join("\n");

  return trimmed === "" ? "" : `${trimmed}\n`;
}
