import type { Metadata } from "next";
import { ReviewQueue } from "@/components/newsroom/review-queue";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Review queue" };

/** Next.js route /review. Callers: sidebar. API: GET /admin/v1/review. Schema: PostRow.
 * User: "Check what is tobe built now into this - build it"
 */

export default async function ReviewPage() {
  const { data, error } = await loadOrLogin<PostRow[]>("/admin/v1/review");
  return (
    <NewsroomShell
      title="Review queue"
      description="Cards from sources set to review, possible duplicates, and every Nxtspot draft land here before readers see them."
      error={error}
    >
      <ReviewQueue rows={data ?? []} />
    </NewsroomShell>
  );
}
