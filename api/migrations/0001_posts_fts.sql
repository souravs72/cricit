-- Full-text search over published card text (English + Hindi). Kept in sync by triggers.
CREATE VIRTUAL TABLE `posts_fts` USING fts5(
	`headline`, `summary`, `headline_hi`, `summary_hi`,
	content='posts', content_rowid='rowid', tokenize='unicode61 remove_diacritics 2'
);
--> statement-breakpoint
CREATE TRIGGER `posts_fts_ai` AFTER INSERT ON `posts` BEGIN
	INSERT INTO posts_fts(rowid, headline, summary, headline_hi, summary_hi)
	VALUES (new.rowid, new.headline, new.summary, new.headline_hi, new.summary_hi);
END;
--> statement-breakpoint
CREATE TRIGGER `posts_fts_ad` AFTER DELETE ON `posts` BEGIN
	INSERT INTO posts_fts(posts_fts, rowid, headline, summary, headline_hi, summary_hi)
	VALUES ('delete', old.rowid, old.headline, old.summary, old.headline_hi, old.summary_hi);
END;
--> statement-breakpoint
CREATE TRIGGER `posts_fts_au` AFTER UPDATE OF headline, summary, headline_hi, summary_hi ON `posts` BEGIN
	INSERT INTO posts_fts(posts_fts, rowid, headline, summary, headline_hi, summary_hi)
	VALUES ('delete', old.rowid, old.headline, old.summary, old.headline_hi, old.summary_hi);
	INSERT INTO posts_fts(rowid, headline, summary, headline_hi, summary_hi)
	VALUES (new.rowid, new.headline, new.summary, new.headline_hi, new.summary_hi);
END;
