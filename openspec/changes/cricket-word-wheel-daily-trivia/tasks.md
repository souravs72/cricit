# Implementation Tasks: "The Daily Over" 6-Ball Cricket Trivia & Profile Points

- [x] **Phase 1: Backend Architecture & Database Migrations**
  - [x] Create Alembic migration to add `trivia_points` to `users`, and create `daily_trivia_questions` and `user_trivia_history` tables.
  - [x] Implement SQLAlchemy models in `backend/app/models/trivia.py`.
  - [x] Add `GET /v1/trivia/daily` and `POST /v1/trivia/submit` in `backend/app/api/v1/routes.py`.
  - [x] Ensure 1 point per correct answer, capped at 6 points per date per user.
  - [x] Populate database with a robust seed of authentic 6-ball sets (Indian domestic, grassroots, IPL, international, rules).
  - [x] Add unit tests for answer validation, idempotency (no double scoring for the same day), and point accrual (`tests/test_trivia.py` with 20/20 passing).

- [x] **Phase 2: Mobile Domain & Offline Seed Bank**
  - [x] Implement `TriviaQuestion` domain model and `DailyOver` state model in `mobile/lib/features/trivia/domain/trivia.dart`.
  - [x] Create `daily_trivia_seed.dart` with 30 authentic 6-ball daily overs (180 questions) so offline users never see a blank sheet.
  - [x] Implement `TriviaRepository` in `mobile/lib/features/trivia/data/trivia_repository.dart` with Dio client and network-first / offline-fallback guarantees.

- [x] **Phase 3: Search Screen & 6-Ball Trivia Sheet Redesign**
  - [x] Refactor `_QuizBanner` on `SearchScreen` to show "The Daily Over" and "Daily cricket quiz" badge.
  - [x] Refactor `_CricketTriviaSheetState` in `search_screen.dart` into a 6-question sequential over:
    - [x] 6 ball indicators (⚪ / 🟢 / 🔴) tracking current over progress.
    - [x] Retain existing question card styling, 4 options (A,B,C,D), instant tap reveal, and trivia fact explanation.
    - [x] "Bowl Next Ball" button transition to advance from Ball 1 through Ball 6.
    - [x] Over scorecard finish screen displaying runs scored (points earned).
    - [x] If logged in: Syncs with backend/local state and banks points to profile.
    - [x] If guest: Displays prompt with "Sign In to Save Points" CTA to bank points.

- [x] **Phase 4: Profile Screen Cricket IQ Points Card**
  - [x] Refactor `profile_screen.dart` to add the "Cricket IQ & The Daily Over" card (`_TriviaStatsCard`).
  - [x] Logged-in view: Displays total points, rank tier (Debutant, Club Cricketer, State Player, Test Legend), active streak, and progress bar to next tier.
  - [x] Guest view: Profile remains clean, points feature is gated to signed-in users.

- [x] **Phase 5: Automated Verification & User Gate**
  - [x] Run `flutter analyze` (Zero issues found!).
  - [x] Run `flutter test` (All 39 mobile tests passed, including dedicated `trivia_test.dart`).
  - [x] Run backend tests (`uv run pytest tests/test_trivia.py tests/test_route_auth.py` -> 20 passed).
  - [ ] User manual verification of uncommitted changes (Per instruction: **"Ensure that, you don't commit after completing the changes. I will verify them myself."**).
  - [ ] Commit locally with conventional commit standards upon user approval.
  - [ ] Push to GitHub `main`.
  - [ ] Pull and deploy on production server `137.23.51.182` via Git.
