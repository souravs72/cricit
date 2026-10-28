import type { Metadata } from "next";
import { PostsTable } from "@/components/newsroom/posts-table";
import { NewsroomShell } from "@/components/newsroom/shell";
import { loadOrLogin } from "@/lib/api/server";
import type { PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Posts" };

/** GET /admin/v1/posts. Permission dashboard:view. Schema PostListItem. */

export default async function PostsPage() {
  const { data, error } = await loadOrLogin<PostRow[]>("/admin/v1/posts");
  return (
    <NewsroomShell
      title="Posts"
      description="Every card in the database — published, in review, or still a draft."
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
