# Task Breakdown: Ultra-Modern Screen Overhaul

- [ ] **Phase 1: 100% Indian Domestic & Grassroots Curation**
  - [ ] Update `mobile/lib/features/feed/data/fixture_feed.dart` with authentic Indian domestic stories (Ranji, Duleep, Vijay Hazare, SMAT, Irani Cup) and Indian grassroots talent (`nxtspot`).
  - [ ] Audit backend seed data (`backend/scripts/showcase_data.py`, `backend/scripts/seed.py`) to eliminate any foreign domestic tournaments and enforce Indian domestic coverage.
  - [ ] Ensure ~60-word curated summaries with author attribution and media house tags.

- [ ] **Phase 2: Ultra-Modern News Card View & Home Feed Overhaul**
  - [ ] Refactor `NewsCardView` (`mobile/lib/features/feed/presentation/news_card_view.dart`):
    - [ ] 16:9 hero image with gradient overlay and source badge.
    - [ ] Bookmark and share icon actions.
    - [ ] Bold typography hook + curated 60-word body + author credit.
    - [ ] Bottom "Tap to read full story" trigger to `InAppWebSheet`.
    - [ ] Clean EN / HI language toggle.
  - [ ] Enhance `FeedScreen` with "New Feed Available" floating pill and smooth tab indicators.
  - [ ] Modernize `ad_views.dart` (Full-page ad card, bottom footer ad banner, sponsored story card).
  - [ ] **Verification**: Ensure `video_short_view.dart` and the `Video` tab remain 100% intact and untouched.

- [ ] **Phase 3: Search & Discovery Screen Overhaul**
  - [ ] Overhaul `SearchScreen` (`mobile/lib/features/search/presentation/search_screen.dart`):
    - [ ] Modern glassmorphic search input.
    - [ ] Indian cricket category pills (Ranji, SMAT, Bumrah, WPL, Nxtspot).
    - [ ] Trending news list with media thumbnails and source badges.
    - [ ] Recent search query history.

- [ ] **Phase 4: Profile, Bookmarks & Settings Overhaul**
  - [ ] Overhaul `ProfileScreen` (`mobile/lib/features/profile/presentation/profile_screen.dart`):
    - [ ] User profile header with avatar, fan level, and reading stats.
    - [ ] Bookmarked stories view with category filters and empty states.
    - [ ] Edit Profile dialog for user name, bio, and favorite state team.
    - [ ] Granular settings list (Night Mode, Language, HD Images, Autoplay, Text Size, Feedback).

- [ ] **Phase 5: Verification, Git Deployment & Production Verification**
  - [ ] Run `flutter analyze` and `flutter test` to ensure zero errors or regressions.
  - [ ] Test mobile web layout in Playwright across target mobile viewports (360x740, 390x844, 412x915).
  - [ ] Commit locally with conventional commits (`feat: ultra-modern screen overhaul and Indian domestic curation`).
  - [ ] Push to GitHub `main`.
  - [ ] Deploy to production server `137.23.51.182` via Git pull.
  - [ ] Verify live production URL with Playwright browser inspection.
