/** Checks every AI summary must pass before it can publish without an editor. */

const NUMBER = /\d+(?:[.,]\d+)*/g;
const DEVANAGARI = /[ऀ-ॿ]/;

export interface ValidationResult {
  ok: boolean;
  reasons: string[];
}

export const numbersIn = (text: string) => new Set((text.match(NUMBER) ?? []).map((n) => n.replaceAll(",", "")));

export function validateSummary(args: {
  summary: string;
  headline: string;
  sourceText: string;
  minWords?: number;
  maxWords?: number;
}): ValidationResult {
  const { minWords = 45, maxWords = 75 } = args;
  const reasons: string[] = [];
  const words = args.summary.trim().split(/\s+/).filter(Boolean).length;
  if (words < minWords || words > maxWords) reasons.push(`summary has ${words} words (want ${minWords}-${maxWords})`);
  if (args.headline.length > 80) reasons.push("headline over 80 characters");
  const source = numbersIn(args.sourceText);
  const invented = [...new Set([...numbersIn(args.summary), ...numbersIn(args.headline)])].filter(
    (n) => !source.has(n),
  );
  if (invented.length) reasons.push(`numbers not in source: ${invented.sort().join(", ")}`);
  return { ok: reasons.length === 0, reasons };
}

export function looksHindi(text: string, minRatio = 0.5): boolean {
  const letters = [...text].filter((ch) => /\p{L}/u.test(ch));
  if (!letters.length) return false;
  return letters.filter((ch) => DEVANAGARI.test(ch)).length / letters.length >= minRatio;
}
