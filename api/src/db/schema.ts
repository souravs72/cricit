/**
 * D1 (SQLite) schema. Change this file, then `npm run db:generate` to create a migration in
 * /migrations, review it, and apply with `npm run db:migrate:local|staging|production`.
 *
 * Conventions: ids are UUIDv7 text; times are integer epoch milliseconds (UTC);
 * arrays/objects are JSON text columns.
 */
import { sql } from "drizzle-orm";
import { index, integer, primaryKey, real, sqliteTable, text, uniqueIndex } from "drizzle-orm/sqlite-core";

const id = () => text("id").primaryKey();
const createdAt = () =>
  integer("created_at", { mode: "number" })
    .notNull()
    .default(sql`(unixepoch() * 1000)`);
const updatedAt = () =>
  integer("updated_at", { mode: "number" })
    .notNull()
    .default(sql`(unixepoch() * 1000)`);

export const sources = sqliteTable("sources", {
  id: id(),
  name: text("name").notNull(),
  type: text("type", { enum: ["news", "youtube_channel", "youtube_search", "x"] }).notNull(),
  adapter: text("adapter", { enum: ["rss", "sitemap", "html"] }),
  adapterConfig: text("adapter_config", { mode: "json" }).$type<Record<string, unknown>>().notNull().default({}),
  defaultCategory: text("default_category", { enum: ["domestic", "international", "grassroots"] })
    .notNull()
    .default("international"),
  trustLevel: text("trust_level", { enum: ["auto", "review"] })
    .notNull()
    .default("review"),
  priority: integer("priority").notNull().default(5),
  fetchIntervalMin: integer("fetch_interval_min").notNull().default(10),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  verifiedAt: integer("verified_at"),
  consecutiveFailures: integer("consecutive_failures").notNull().default(0),
  etag: text("etag"),
  lastModified: text("last_modified"),
  lastFetchedAt: integer("last_fetched_at"),
  lastError: text("last_error"),
  logoUrl: text("logo_url"),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const posts = sqliteTable(
  "posts",
  {
    id: id(),
    kind: text("kind", { enum: ["read", "video", "nxtspot"] }).notNull(),
    status: text("status", { enum: ["draft", "review", "published", "archived"] })
      .notNull()
      .default("draft"),
    category: text("category", { enum: ["domestic", "international", "grassroots"] }).notNull(),
    headline: text("headline").notNull(),
    summary: text("summary").notNull().default(""),
    headlineHi: text("headline_hi"),
    summaryHi: text("summary_hi"),
    imageUrl: text("image_url"),
    originalUrl: text("original_url"),
    urlHash: text("url_hash"),
    sourceId: text("source_id").references(() => sources.id, { onDelete: "set null" }),
    possibleDuplicateOf: text("possible_duplicate_of"),
    videoId: text("video_id"),
    authorCredit: text("author_credit"),
    tags: text("tags", { mode: "json" }).$type<string[]>().notNull().default([]),
    trendingScore: real("trending_score").notNull().default(0),
    isPinned: integer("is_pinned", { mode: "boolean" }).notNull().default(false),
    promptVersion: text("prompt_version"),
    publishedAt: integer("published_at"),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    uniqueIndex("uq_posts_url_hash").on(t.urlHash),
    index("ix_posts_feed").on(t.status, t.category, t.publishedAt, t.id),
    index("ix_posts_status_published").on(t.status, t.publishedAt, t.id),
  ],
);

export const postSources = sqliteTable(
  "post_sources",
  {
    id: id(),
    postId: text("post_id")
      .notNull()
      .references(() => posts.id, { onDelete: "cascade" }),
    sourceId: text("source_id").references(() => sources.id, { onDelete: "set null" }),
    url: text("url").notNull(),
  },
  (t) => [uniqueIndex("uq_post_sources_post_url").on(t.postId, t.url)],
);

export const users = sqliteTable("users", {
  id: id(),
  phone: text("phone").notNull().unique(),
  firebaseUid: text("firebase_uid").notNull().unique(),
  name: text("name"),
  bio: text("bio"),
  avatarUrl: text("avatar_url"),
  language: text("language", { enum: ["en", "hi"] })
    .notNull()
    .default("en"),
  prefs: text("prefs", { mode: "json" }).$type<Record<string, unknown>>().notNull().default({}),
  lastSeenAt: integer("last_seen_at"),
  deletedAt: integer("deleted_at"),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const devices = sqliteTable("devices", {
  id: id(),
  userId: text("user_id").references(() => users.id, { onDelete: "set null" }),
  fcmToken: text("fcm_token").notNull().unique(),
  platform: text("platform").notNull(),
  appVersion: text("app_version").notNull(),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const bookmarks = sqliteTable(
  "bookmarks",
  {
    id: id(),
    userId: text("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    postId: text("post_id")
      .notNull()
      .references(() => posts.id, { onDelete: "cascade" }),
    createdAt: createdAt(),
  },
  (t) => [uniqueIndex("uq_bookmarks_user_post").on(t.userId, t.postId)],
);

export const nxtspotSubmissions = sqliteTable("nxtspot_submissions", {
  id: id(),
  userId: text("user_id").references(() => users.id, { onDelete: "set null" }),
  submitterName: text("submitter_name").notNull(),
  location: text("location"),
  rawText: text("raw_text").notNull(),
  mediaUrls: text("media_urls", { mode: "json" }).$type<string[]>().notNull().default([]),
  status: text("status", { enum: ["new", "drafted", "published", "rejected"] })
    .notNull()
    .default("new"),
  postId: text("post_id").references(() => posts.id, { onDelete: "set null" }),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const admins = sqliteTable("admins", {
  id: id(),
  email: text("email").notNull().unique(),
  name: text("name").notNull(),
  passwordHash: text("password_hash"),
  role: text("role", { enum: ["owner", "editor", "viewer"] }).notNull(),
  /** AES-GCM encrypted with TOTP_ENCRYPTION_KEY; never stored in plain text. */
  totpSecretEnc: text("totp_secret_enc"),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  failedLogins: integer("failed_logins").notNull().default(0),
  lockedUntil: integer("locked_until"),
  inviteTokenHash: text("invite_token_hash"),
  inviteExpiresAt: integer("invite_expires_at"),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

export const adminRecoveryCodes = sqliteTable("admin_recovery_codes", {
  id: id(),
  adminId: text("admin_id")
    .notNull()
    .references(() => admins.id, { onDelete: "cascade" }),
  codeHash: text("code_hash").notNull(),
  usedAt: integer("used_at"),
});

/** One login on one device. Refresh tokens rotate within a family; reuse revokes the family. */
export const sessions = sqliteTable(
  "sessions",
  {
    id: id(),
    principalType: text("principal_type", { enum: ["user", "admin"] }).notNull(),
    principalId: text("principal_id").notNull(),
    familyId: text("family_id").notNull(),
    refreshHash: text("refresh_hash").notNull().unique(),
    previousHash: text("previous_hash"),
    deviceId: text("device_id"),
    userAgent: text("user_agent"),
    expiresAt: integer("expires_at").notNull(),
    absoluteExpiresAt: integer("absolute_expires_at").notNull(),
    revokedAt: integer("revoked_at"),
    revokedReason: text("revoked_reason"),
    createdAt: createdAt(),
    updatedAt: updatedAt(),
  },
  (t) => [
    index("ix_sessions_principal").on(t.principalType, t.principalId),
    index("ix_sessions_family").on(t.familyId),
    index("ix_sessions_previous").on(t.previousHash),
  ],
);

export const auditLog = sqliteTable(
  "audit_log",
  {
    id: id(),
    adminId: text("admin_id").references(() => admins.id, { onDelete: "set null" }),
    action: text("action").notNull(),
    entity: text("entity").notNull(),
    entityId: text("entity_id"),
    diff: text("diff", { mode: "json" }).$type<Record<string, unknown>>().notNull().default({}),
    ip: text("ip"),
    ts: integer("ts").notNull(),
  },
  (t) => [index("ix_audit_ts").on(t.ts)],
);

export const adCampaigns = sqliteTable("ad_campaigns", {
  id: id(),
  advertiser: text("advertiser").notNull(),
  format: text("format", { enum: ["full_page", "footer", "sponsored_card"] }).notNull(),
  creativeUrl: text("creative_url").notNull(),
  clickUrl: text("click_url").notNull(),
  title: text("title"),
  body: text("body"),
  startAt: integer("start_at").notNull(),
  endAt: integer("end_at").notNull(),
  frequency: integer("frequency").notNull().default(6),
  dailyCap: integer("daily_cap"),
  isActive: integer("is_active", { mode: "boolean" }).notNull().default(true),
  createdAt: createdAt(),
  updatedAt: updatedAt(),
});

/** Rolled up hourly from KV/DO counters (T26). No raw event rows are stored. */
export const postStatsDaily = sqliteTable(
  "post_stats_daily",
  {
    postId: text("post_id")
      .notNull()
      .references(() => posts.id, { onDelete: "cascade" }),
    day: text("day").notNull(), // YYYY-MM-DD (UTC)
    views: integer("views").notNull().default(0),
    opens: integer("opens").notNull().default(0),
    shares: integer("shares").notNull().default(0),
    bookmarks: integer("bookmarks").notNull().default(0),
  },
  (t) => [primaryKey({ columns: [t.postId, t.day] })],
);

export const adStatsDaily = sqliteTable(
  "ad_stats_daily",
  {
    campaignId: text("campaign_id")
      .notNull()
      .references(() => adCampaigns.id, { onDelete: "cascade" }),
    day: text("day").notNull(),
    impressions: integer("impressions").notNull().default(0),
    clicks: integer("clicks").notNull().default(0),
  },
  (t) => [primaryKey({ columns: [t.campaignId, t.day] })],
);

export const aiJobs = sqliteTable("ai_jobs", {
  id: id(),
  postId: text("post_id").references(() => posts.id, { onDelete: "set null" }),
  model: text("model").notNull(),
  promptVersion: text("prompt_version").notNull(),
  inputTokens: integer("input_tokens").notNull().default(0),
  outputTokens: integer("output_tokens").notNull().default(0),
  costInrMicros: integer("cost_inr_micros").notNull().default(0),
  status: text("status", { enum: ["ok", "invalid", "error"] }).notNull(),
  error: text("error"),
  createdAt: createdAt(),
});

export type Post = typeof posts.$inferSelect;
export type NewPost = typeof posts.$inferInsert;
