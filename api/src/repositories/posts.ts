/** All SQL for posts lives here. */
import { and, desc, eq, inArray, lt, or, sql } from "drizzle-orm";
import type { DrizzleD1Database } from "drizzle-orm/d1";

import { posts, type Post } from "../db/schema";

export type Db = DrizzleD1Database<Record<string, never>>;

/** Newest first, keyset-paginated on (published_at, id) so new posts never shift pages. */
export async function listPublished(
  db: Db,
  opts: { category: Post["category"] | null; after: { t: number; id: string } | null; limit: number },
): Promise<Post[]> {
  const conditions = [eq(posts.status, "published")];
  if (opts.category) conditions.push(eq(posts.category, opts.category));
  if (opts.after) {
    conditions.push(
      or(lt(posts.publishedAt, opts.after.t), and(eq(posts.publishedAt, opts.after.t), lt(posts.id, opts.after.id)))!,
    );
  }
  return db
    .select()
    .from(posts)
    .where(and(...conditions))
    .orderBy(desc(posts.publishedAt), desc(posts.id))
    .limit(opts.limit);
}

/** Turn free text into a safe FTS5 query: each word quoted, prefix-matched, AND-ed. */
export function toFtsQuery(input: string): string {
  const words = input
    .normalize("NFKC")
    .split(/\s+/)
    .map((w) => w.replace(/["*^:(){}[\]]/g, ""))
    .filter((w) => w.length > 0)
    .slice(0, 8);
  return words.map((w) => `"${w}"*`).join(" ");
}

export async function searchPublished(db: Db, query: string, limit = 20): Promise<Post[]> {
  const fts = toFtsQuery(query);
  if (!fts) return [];
  const rows = await db.all<{ id: string }>(
    sql`SELECT p.id FROM posts_fts f JOIN posts p ON p.rowid = f.rowid
        WHERE posts_fts MATCH ${fts} AND p.status = 'published'
        ORDER BY bm25(posts_fts), p.published_at DESC LIMIT ${limit}`,
  );
  if (rows.length === 0) return [];
  const ids = rows.map((r) => r.id);
  const found = await db.select().from(posts).where(inArray(posts.id, ids));
  const order = new Map(ids.map((id, i) => [id, i]));
  return found.sort((a, b) => order.get(a.id)! - order.get(b.id)!);
}
