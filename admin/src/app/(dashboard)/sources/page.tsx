import type { Metadata } from "next";
import { SourcesManager } from "@/components/newsroom/sources-manager";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { SourceRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Sources" };

/** Next.js route /sources. Callers: sidebar. API: GET /admin/v1/sources. Schema: SourceRow.
 * User: "Check what is tobe built now into this - build it"
 */

export default async function SourcesPage() {
  const { data, error } = await loadOrLogin<SourceRow[]>("/admin/v1/sources");
  return (
    <NewsroomShell
      title="Sources"
      description="Verified news sites and official YouTube channels. We fetch RSS or a listing page; we never store the article body."
      error={error}
    >
      <SourcesManager rows={data ?? []} />
    </NewsroomShell>
  );
}
