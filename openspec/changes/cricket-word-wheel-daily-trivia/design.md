# Technical & UX Design: The "Daily Over" 6-Ball Cricket Trivia & Profile Points

## 1. System Architecture

```
[Cron / Ingestion Engine]
       │
       ▼ (Generates 6 daily questions)
[PostgreSQL: daily_trivia_sets, trivia_questions, user_trivia_history, users.trivia_points]
       │
       ▼
[FastAPI Endpoints]
   ├── GET /v1/trivia/daily?date=YYYY-MM-DD
   └── POST /v1/trivia/submit (Bearer Auth) -> awards points to user
       │
       ▼
[Mobile Riverpod State: triviaControllerProvider & settingsProvider]
       ├── Search Screen: "_QuizBanner" -> opens "The Daily Over" Sheet
       ├── Daily Trivia Sheet: 6-Ball Flow with 1 pt per correct answer
       └── Profile Screen: Cricket IQ Points Card & Fan Tier
```

## 2. Interactive 6-Ball Flow (Current Fashion Preserved)
The trivia modal retains the exact beloved visual fashion already in `search_screen.dart`:
- Clean modal bottom sheet with rounded top corners and drag handle.
- Header: Cricket icon badge + *"THE DAILY OVER"* + *"Ball {X} of 6"*.
- Progress Bar: 6 ball indicators at the top:
  - ⚪ Unplayed ball
  - 🟢 Dot / 1 Run (Correct: +1 pt)
  - 🔴 Wicket / Missed (Incorrect: 0 pt)
- Question Card: Green/Dark tinted card with clear bold question text.
- Options: 4 choices (A, B, C, D) with letter badge and border highlight.
- Instant Reveal:
  - On tap: correct option glows green with checkmark icon; selected incorrect option glows red with cancel icon.
  - Haptic feedback (light for correct, double tap for incorrect).
  - Explanation box expands underneath with historical fact/trivia breakdown.
- Next Action Button:
  - For Balls 1-5: *"Next Ball →"*
  - For Ball 6: *"Finish Over & View Scorecard"*
- Over Summary & Scorecard:
  - Over Result: e.g. **5 / 6 Correct** (+5 Points earned!).
  - If **Logged In**: Shows *"🏆 5 Points added to your Profile! Current Total: 42 Pts"*.
  - If **Guest (Not Logged In)**: Shows *"⭐ You scored 5/6! Log in with your phone to save your points to your profile."* with an instant *"Sign In Now"* button.

## 3. Database Schema & API Contract

### 3.1 Database Schema
```sql
-- 1. Daily Trivia Questions Table
CREATE TABLE daily_trivia_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    puzzle_date DATE NOT NULL,
    ball_number INT NOT NULL CHECK (ball_number BETWEEN 1 AND 6),
    category VARCHAR(50) NOT NULL, -- domestic, grassroots, trending, ipl, international, rules
    question TEXT NOT NULL,
    options JSONB NOT NULL,        -- ["A", "B", "C", "D"]
    correct_index INT NOT NULL CHECK (correct_index BETWEEN 0 AND 3),
    explanation TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_daily_ball UNIQUE (puzzle_date, ball_number)
);

-- 2. Add trivia_points to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS trivia_points INT NOT NULL DEFAULT 0;

-- 3. User Daily Trivia History (prevents duplicate points exploit)
CREATE TABLE user_trivia_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    puzzle_date DATE NOT NULL,
    points_earned INT NOT NULL CHECK (points_earned BETWEEN 0 AND 6),
    answers JSONB NOT NULL,
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_user_daily_trivia UNIQUE (user_id, puzzle_date)
);
```

### 3.2 REST API Endpoints
1. `GET /v1/trivia/daily?date=YYYY-MM-DD`
   - Public endpoint (accessible to guests and logged-in users).
   - Returns 6 questions for the day with questions, options, and explanations (or hides correct_index if strict mode enabled).
2. `POST /v1/trivia/submit`
   - Requires `Authorization: Bearer <token>`.
   - Payload:
     ```json
     {
       "date": "2026-11-25",
       "answers": [0, 1, 2, 3, 0, 1],
       "correct_count": 5
     }
     ```
   - Validates answers on backend, prevents double-submitting the same day, updates `users.trivia_points += points_earned`, records `user_trivia_history`, and returns:
     ```json
     {
       "points_earned": 5,
       "total_points": 47,
       "streak_days": 4
     }
     ```
3. `GET /v1/auth/me` or `GET /v1/users/profile`
   - Returns user details including `trivia_points` and `streak`.

## 4. Mobile Profile Integration
In `mobile/lib/features/profile/presentation/profile_screen.dart`:
- Directly under the user avatar, display a high-contrast **Cricket IQ & Points Card**:
  - If **Logged In**:
    ```
    ┌─────────────────────────────────────────────────────┐
    │ 🏏 CRICKET IQ POINTS              🔥 5 Day Streak    │
    │                                                     │
    │  47 Points                        Tier: Ranji Star  │
    │  Today's Over: 5/6 (Completed)                      │
    └─────────────────────────────────────────────────────┘
    ```
  - If **Not Logged In (Guest)**:
    ```
    ┌─────────────────────────────────────────────────────┐
    │ 🏏 CRICKET IQ POINTS                                │
    │                                                     │
    │  Log in with your phone to earn points & rank up    │
    │  [ Log In to Track Points ]                         │
    └─────────────────────────────────────────────────────┘
    ```
