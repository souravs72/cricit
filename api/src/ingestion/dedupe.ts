/**
 * Two-pass duplicate detection with a three-way verdict.
 *
 * Measured during design: title similarity alone is unreliable for sports news.
 * "India beat Australia in Perth Test" vs "India lose to Australia in Perth Test" scores ~92,
 * while a genuine rewording of the same story can score ~57. So we auto-merge only when very sure,
 * send the uncertain middle band to the review queue, and treat the rest as distinct.
 * Titles whose numbers differ ("3rd ODI" vs "4th ODI") are never auto-merged.
 */

export const AUTO_MERGE_SIMILARITY = 95;
export const PASS1_REVIEW_SIMILARITY = 85;
export const PASS2_REVIEW_SIMILARITY = 55;

export type Verdict = "distinct" | "possible" | "duplicate";

const TRACKING = /^(utm_|fbclid$|gclid$|ref$|ref_src$|amp$)/i;

export function canonicalUrl(url: string): string {
  const u = new URL(url.trim());
  const params = [...u.searchParams.entries()].filter(([k]) => !TRACKING.test(k));
  const path = u.pathname.replace(/\/+$/, "").replace(/\/amp$/, "") || "/";
  const host = u.hostname.toLowerCase().replace(/^www\./, "");
  const query = params.length ? `?${new URLSearchParams(params).toString()}` : "";
  return `https://${host}${path}${query}`;
}

export function normaliseTitle(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** Indel similarity 0–100 (same definition as rapidfuzz `fuzz.ratio`). */
export function ratio(a: string, b: string): number {
  if (!a.length && !b.length) return 100;
  const m = a.length;
  const n = b.length;
  let prev = new Array<number>(n + 1).fill(0);
  for (let i = 1; i <= m; i++) {
    const cur = new Array<number>(n + 1).fill(0);
    for (let j = 1; j <= n; j++) {
      cur[j] = a[i - 1] === b[j - 1] ? prev[j - 1]! + 1 : Math.max(prev[j]!, cur[j - 1]!);
    }
    prev = cur;
  }
  const lcs = prev[n]!;
  return (200 * lcs) / (m + n);
}

/** Same algorithm as rapidfuzz `fuzz.token_set_ratio`. */
export function tokenSetRatio(a: string, b: string): number {
  const ta = new Set(a.split(" ").filter(Boolean));
  const tb = new Set(b.split(" ").filter(Boolean));
  const inter = [...ta].filter((t) => tb.has(t)).sort();
  const diffA = [...ta].filter((t) => !tb.has(t)).sort();
  const diffB = [...tb].filter((t) => !ta.has(t)).sort();
  if (!inter.length && (!diffA.length || !diffB.length)) return ratio(a, b);
  if (inter.length && (!diffA.length || !diffB.length)) return 100;
  const s = inter.join(" ");
  const sa = [s, ...diffA].filter(Boolean).join(" ");
  const sb = [s, ...diffB].filter(Boolean).join(" ");
  return Math.max(ratio(s, sa), ratio(s, sb), ratio(sa, sb));
}

const numbers = (t: string) => new Set(t.match(/\d+/g) ?? []);
const sameSet = (a: Set<string>, b: Set<string>) => a.size === b.size && [...a].every((x) => b.has(x));

export interface Candidate {
  title: string;
  publishedAt: number;
  tags?: ReadonlySet<string>;
}

function compare(next: Candidate, old: Candidate, reviewFloor: number): Verdict {
  const a = normaliseTitle(next.title);
  const b = normaliseTitle(old.title);
  const score = tokenSetRatio(a, b);
  if (score < reviewFloor) return "distinct";
  const na = numbers(a);
  const nb = numbers(b);
  const numbersConflict = na.size > 0 && nb.size > 0 && !sameSet(na, nb);
  return score >= AUTO_MERGE_SIMILARITY && !numbersConflict ? "duplicate" : "possible";
}

function strongest(verdicts: Verdict[]): Verdict {
  if (verdicts.includes("duplicate")) return "duplicate";
  if (verdicts.includes("possible")) return "possible";
  return "distinct";
}

const HOUR = 3600_000;

export function checkPass1(next: Candidate, recent: Candidate[]): Verdict {
  return strongest(
    recent
      .filter((old) => Math.abs(next.publishedAt - old.publishedAt) <= 48 * HOUR)
      .map((old) => compare(next, old, PASS1_REVIEW_SIMILARITY)),
  );
}

export function checkPass2(next: Candidate, recent: Candidate[]): Verdict {
  const tags = next.tags ?? new Set<string>();
  if (!tags.size) return "distinct";
  return strongest(
    recent
      .filter((old) => {
        if (Math.abs(next.publishedAt - old.publishedAt) > 6 * HOUR) return false;
        const shared = [...(old.tags ?? [])].filter((t) => tags.has(t)).length;
        return shared >= Math.min(2, tags.size);
      })
      .map((old) => compare(next, old, PASS2_REVIEW_SIMILARITY)),
  );
}
