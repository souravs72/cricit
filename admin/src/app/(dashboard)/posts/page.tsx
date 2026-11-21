import type { Metadata } from "next";
import Link from "next/link";
import { CheckSquare, Sparkles } from "lucide-react";
import { PostsTable } from "@/components/newsroom/posts-table";
import { NewsroomShell } from "@/components/newsroom/shell";
import { Button } from "@/components/ui/button";
import { loadOrLogin } from "@/lib/api/server";
import type { PostRow } from "@/lib/newsroom";

export const metadata: Metadata = { title: "Posts & Stories" };

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
  const rows = data ?? [];

  return (
    <NewsroomShell
      title="Posts & Stories"
      description="Manage all cricket cards across domestic, international, grassroots, and IPL categories. Filter by status, search, or sort."
      badge={
        <span className="rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-semibold text-primary">
          {rows.length} total
        </span>
      }
      actions={
        <div className="flex items-center gap-2">
          <Button asChild variant="outline" size="sm" className="gap-1.5 text-xs">
            <Link href="/studio">
              <Sparkles className="h-3.5 w-3.5 text-primary" />
              AI Studio
            </Link>
          </Button>
          <Button asChild size="sm" className="gap-1.5 text-xs">
            <Link href="/review">
              <CheckSquare className="h-3.5 w-3.5" />
              Review Queue
            </Link>
          </Button>
        </div>
      }
      error={error}
    >
      <PostsTable
        rows={rows}
        emptyTitle="No posts found."
        emptyBody="Run autonomous ingestion or seed the database to populate cricket stories."
      />
    </NewsroomShell>
  );
}
