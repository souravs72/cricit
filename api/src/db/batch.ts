/**
 * D1 allows at most 100 bound parameters per statement, so multi-row inserts must be chunked.
 * Chunks run in one D1 batch, which is atomic: all rows land or none do.
 */
import { getTableColumns } from "drizzle-orm";
import type { BatchItem } from "drizzle-orm/batch";
import type { DrizzleD1Database } from "drizzle-orm/d1";
import type { SQLiteTable } from "drizzle-orm/sqlite-core";

const D1_MAX_PARAMS = 100;

export async function insertMany<T extends SQLiteTable>(
  db: DrizzleD1Database<Record<string, never>>,
  table: T,
  rows: T["$inferInsert"][],
): Promise<void> {
  if (rows.length === 0) return;
  // Drizzle binds every column of the table (defaults included), not just the keys passed in.
  const columns = Object.keys(getTableColumns(table)).length;
  const perChunk = Math.max(1, Math.floor((D1_MAX_PARAMS - 1) / columns));
  const statements: BatchItem<"sqlite">[] = [];
  for (let i = 0; i < rows.length; i += perChunk) {
    statements.push(db.insert(table).values(rows.slice(i, i + perChunk)));
  }
  await db.batch(statements as [BatchItem<"sqlite">, ...BatchItem<"sqlite">[]]);
}
