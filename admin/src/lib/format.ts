/** Date display for newsroom tables. IST, never a relative "2h ago".
 * Importers: dashboard pages. No API. Input: ISO timestamps from PostListItem.published_at.
 */

export function formatWhen(iso: string | null | undefined): string {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return new Intl.DateTimeFormat("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone: "Asia/Kolkata",
  }).format(d);
}
