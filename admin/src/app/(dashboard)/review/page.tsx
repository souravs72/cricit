import type { Metadata } from "next";
import { PostsTable } from "@/components/newsroom/posts-table";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Review queue" };

/** GET /admin/v1/review. Permission posts:write. Schema PostListItem. */

export default async function ReviewPage() {
  const { data, error } = await loadOrLogin<PostRow[]>("/admin/v1/review");
  return (
    <NewsroomShell
      title="Review queue"
      description="Cards from sources set to review, possible duplicates, and every Nxtspot draft land here before readers see them."
      error={error}
    >
      <PostsTable
        rows={data ?? []}
        emptyTitle="No cards waiting."
        emptyBody="When the worker drafts a card that needs an editor, it shows up here."
      />
    </NewsroomShell>
  );
}
