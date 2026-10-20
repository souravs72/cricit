CREATE TABLE `ad_campaigns` (
	`id` text PRIMARY KEY NOT NULL,
	`advertiser` text NOT NULL,
	`format` text NOT NULL,
	`creative_url` text NOT NULL,
	`click_url` text NOT NULL,
	`title` text,
	`body` text,
	`start_at` integer NOT NULL,
	`end_at` integer NOT NULL,
	`frequency` integer DEFAULT 6 NOT NULL,
	`daily_cap` integer,
	`is_active` integer DEFAULT true NOT NULL,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `ad_stats_daily` (
	`campaign_id` text NOT NULL,
	`day` text NOT NULL,
	`impressions` integer DEFAULT 0 NOT NULL,
	`clicks` integer DEFAULT 0 NOT NULL,
	PRIMARY KEY(`campaign_id`, `day`),
	FOREIGN KEY (`campaign_id`) REFERENCES `ad_campaigns`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `admin_recovery_codes` (
	`id` text PRIMARY KEY NOT NULL,
	`admin_id` text NOT NULL,
	`code_hash` text NOT NULL,
	`used_at` integer,
	FOREIGN KEY (`admin_id`) REFERENCES `admins`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `admins` (
	`id` text PRIMARY KEY NOT NULL,
	`email` text NOT NULL,
	`name` text NOT NULL,
	`password_hash` text,
	`role` text NOT NULL,
	`totp_secret_enc` text,
	`is_active` integer DEFAULT true NOT NULL,
	`failed_logins` integer DEFAULT 0 NOT NULL,
	`locked_until` integer,
	`invite_token_hash` text,
	`invite_expires_at` integer,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `admins_email_unique` ON `admins` (`email`);--> statement-breakpoint
CREATE TABLE `ai_jobs` (
	`id` text PRIMARY KEY NOT NULL,
	`post_id` text,
	`model` text NOT NULL,
	`prompt_version` text NOT NULL,
	`input_tokens` integer DEFAULT 0 NOT NULL,
	`output_tokens` integer DEFAULT 0 NOT NULL,
	`cost_inr_micros` integer DEFAULT 0 NOT NULL,
	`status` text NOT NULL,
	`error` text,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE TABLE `audit_log` (
	`id` text PRIMARY KEY NOT NULL,
	`admin_id` text,
	`action` text NOT NULL,
	`entity` text NOT NULL,
	`entity_id` text,
	`diff` text DEFAULT '{}' NOT NULL,
	`ip` text,
	`ts` integer NOT NULL,
	FOREIGN KEY (`admin_id`) REFERENCES `admins`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE INDEX `ix_audit_ts` ON `audit_log` (`ts`);--> statement-breakpoint
CREATE TABLE `bookmarks` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`post_id` text NOT NULL,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE UNIQUE INDEX `uq_bookmarks_user_post` ON `bookmarks` (`user_id`,`post_id`);--> statement-breakpoint
CREATE TABLE `devices` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text,
	`fcm_token` text NOT NULL,
	`platform` text NOT NULL,
	`app_version` text NOT NULL,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE UNIQUE INDEX `devices_fcm_token_unique` ON `devices` (`fcm_token`);--> statement-breakpoint
CREATE TABLE `nxtspot_submissions` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text,
	`submitter_name` text NOT NULL,
	`location` text,
	`raw_text` text NOT NULL,
	`media_urls` text DEFAULT '[]' NOT NULL,
	`status` text DEFAULT 'new' NOT NULL,
	`post_id` text,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE set null,
	FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE TABLE `post_sources` (
	`id` text PRIMARY KEY NOT NULL,
	`post_id` text NOT NULL,
	`source_id` text,
	`url` text NOT NULL,
	FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`source_id`) REFERENCES `sources`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE UNIQUE INDEX `uq_post_sources_post_url` ON `post_sources` (`post_id`,`url`);--> statement-breakpoint
CREATE TABLE `post_stats_daily` (
	`post_id` text NOT NULL,
	`day` text NOT NULL,
	`views` integer DEFAULT 0 NOT NULL,
	`opens` integer DEFAULT 0 NOT NULL,
	`shares` integer DEFAULT 0 NOT NULL,
	`bookmarks` integer DEFAULT 0 NOT NULL,
	PRIMARY KEY(`post_id`, `day`),
	FOREIGN KEY (`post_id`) REFERENCES `posts`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `posts` (
	`id` text PRIMARY KEY NOT NULL,
	`kind` text NOT NULL,
	`status` text DEFAULT 'draft' NOT NULL,
	`category` text NOT NULL,
	`headline` text NOT NULL,
	`summary` text DEFAULT '' NOT NULL,
	`headline_hi` text,
	`summary_hi` text,
	`image_url` text,
	`original_url` text,
	`url_hash` text,
	`source_id` text,
	`possible_duplicate_of` text,
	`video_id` text,
	`author_credit` text,
	`tags` text DEFAULT '[]' NOT NULL,
	`trending_score` real DEFAULT 0 NOT NULL,
	`is_pinned` integer DEFAULT false NOT NULL,
	`prompt_version` text,
	`published_at` integer,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	FOREIGN KEY (`source_id`) REFERENCES `sources`(`id`) ON UPDATE no action ON DELETE set null
);
--> statement-breakpoint
CREATE UNIQUE INDEX `uq_posts_url_hash` ON `posts` (`url_hash`);--> statement-breakpoint
CREATE INDEX `ix_posts_feed` ON `posts` (`status`,`category`,`published_at`,`id`);--> statement-breakpoint
CREATE INDEX `ix_posts_status_published` ON `posts` (`status`,`published_at`,`id`);--> statement-breakpoint
CREATE TABLE `sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`principal_type` text NOT NULL,
	`principal_id` text NOT NULL,
	`family_id` text NOT NULL,
	`refresh_hash` text NOT NULL,
	`previous_hash` text,
	`device_id` text,
	`user_agent` text,
	`expires_at` integer NOT NULL,
	`absolute_expires_at` integer NOT NULL,
	`revoked_at` integer,
	`revoked_reason` text,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `sessions_refresh_hash_unique` ON `sessions` (`refresh_hash`);--> statement-breakpoint
CREATE INDEX `ix_sessions_principal` ON `sessions` (`principal_type`,`principal_id`);--> statement-breakpoint
CREATE INDEX `ix_sessions_family` ON `sessions` (`family_id`);--> statement-breakpoint
CREATE INDEX `ix_sessions_previous` ON `sessions` (`previous_hash`);--> statement-breakpoint
CREATE TABLE `sources` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`type` text NOT NULL,
	`adapter` text,
	`adapter_config` text DEFAULT '{}' NOT NULL,
	`default_category` text DEFAULT 'international' NOT NULL,
	`trust_level` text DEFAULT 'review' NOT NULL,
	`priority` integer DEFAULT 5 NOT NULL,
	`fetch_interval_min` integer DEFAULT 10 NOT NULL,
	`is_active` integer DEFAULT true NOT NULL,
	`verified_at` integer,
	`consecutive_failures` integer DEFAULT 0 NOT NULL,
	`etag` text,
	`last_modified` text,
	`last_fetched_at` integer,
	`last_error` text,
	`logo_url` text,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `users` (
	`id` text PRIMARY KEY NOT NULL,
	`phone` text NOT NULL,
	`firebase_uid` text NOT NULL,
	`name` text,
	`bio` text,
	`avatar_url` text,
	`language` text DEFAULT 'en' NOT NULL,
	`prefs` text DEFAULT '{}' NOT NULL,
	`last_seen_at` integer,
	`deleted_at` integer,
	`created_at` integer DEFAULT (unixepoch() * 1000) NOT NULL,
	`updated_at` integer DEFAULT (unixepoch() * 1000) NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_phone_unique` ON `users` (`phone`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_firebase_uid_unique` ON `users` (`firebase_uid`);