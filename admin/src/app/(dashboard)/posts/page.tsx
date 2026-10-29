import type { Metadata } from "next";
import { PostsTable } from "@/components/newsroom/posts-table";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Posts" };

/** Next.js route /posts. API: GET /admin/v1/posts. Schema: PostRow.
 * User: "Check what is tobe built now into this - build it"
 */

export default async function PostsPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; category?: string }>;
}) {
  const sp = await searchParams;
  const q = new URLSearchParams();
  if (sp.status) q.set("status", sp.status);
  if (sp.category) q.set("category", sp.category);
  const path = q.size ? `/admin/v1/posts?${q.toString()}` : "/admin/v1/posts";
  const { data, error } = await loadOrLogin<PostRow[]>(path);
  return (
    <NewsroomShell
      title="Posts"
      description="Every card in the database — published, in review, or still a draft. Add ?status=review or ?category=domestic to filter."
      error={error}
    >
      <PostsTable
        rows={data ?? []}
        emptyTitle="No posts yet."
        emptyBody="Run make seed locally to load sixty published cards and three in review."
      />
    </NewsroomShell>
  );
}
