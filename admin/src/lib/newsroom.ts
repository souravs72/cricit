/** Shapes returned by GET /admin/v1/* list endpoints (Pydantic SourceOut, PostListItem, …).
 * Importers: dashboard pages via loadOrLogin.
 */

/** Types for GET /admin/v1/sources and /posts. Callers: dashboard pages, review-queue, sources-manager.
 * User: "Check what is tobe built now into this - build it"
 */
export type SourceRow = {
  id: string;
  name: string;
  type: string;
  adapter: string | null;
  default_category: string;
  trust_level: string;
  is_active: boolean;
  consecutive_failures: number;
  last_error: string | null;
  last_fetched_at: string | null;
  feed_url?: string | null;
  fetch_interval_min?: number;
};

export type PostRow = {
  id: string;
  kind: string;
  status: string;
  category: string;
  headline: string;
  summary?: string;
  author_credit: string | null;
  published_at: string | null;
  prompt_version: string | null;
  tags: string[];
  original_url?: string | null;
  possible_duplicate_of?: string | null;
  duplicate_headline?: string | null;
};

export type AdRow = {
  id: string;
  advertiser: string;
  format: string;
  title: string | null;
  is_active: boolean;
  start_at: string;
  end_at: string;
  daily_cap: number | null;
  impressions_today?: number;
  clicks_today?: number;
};

export type AuditRow = {
  id: string;
  action: string;
  entity: string;
  entity_id: string | null;
  ts: string;
  note: string | null;
};

export type NxtspotRow = {
  id: string;
  submitter_name: string;
  location: string | null;
  status: string;
  raw_text: string;
};

export type Overview = {
  cards_published_today: number;
  waiting_for_review: number;
  readers_today: number;
  ai_cost_today: string;
  review: PostRow[];
  sources: SourceRow[];
};
