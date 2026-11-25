# Proposal: The "Daily Over" 6-Ball Cricket Trivia & Profile Points System

## 1. Problem Statement & Refinement
The user explicitly specified:
- We want pure **question-based trivia** (not an anagram word game).
- An over in cricket has **6 balls**, so the user receives exactly **6 questions every day** ("The Daily Over").
- Questions are presented in the **current proven fashion**: clean bottom sheet with a question card, 4 choices (A, B, C, D), instant green/red tap feedback, and an insightful explanation fact.
- **Points Economy**:
  - Each correct guess awards **1 Point** (up to 6 points per day).
  - Users can track and view their accumulated points and trivia stats on their **Profile screen**.
- **Authentication Gating**:
  - **Points only accrue and save when the user is logged in with valid credentials.**
  - Guest/unauthenticated users can still play the daily 6 questions for fun, but are gracefully shown an in-sheet prompt to sign in to bank and accumulate their points.

## 2. Core Strategic Pillars
1. **The Daily Over (6 Balls / Day)**:
   - Ball 1: Trending News & Recent Highlights
   - Ball 2: 100% Indian Domestic (Ranji Trophy / SMAT / Vijay Hazare)
   - Ball 3: Indian Grassroots (Nxtspot prodigies / district tournaments / school cricket)
   - Ball 4: IPL & T20 Master (Auction records, franchise history, death-over drama)
   - Ball 5: International Cricket & World Cups
   - Ball 6: The Super Over Finale (Deep cricket records, legendary dismissals, or MCC laws)
2. **Profile Points & Gamification**:
   - `Trivia Points` counter displayed on the Profile header.
   - Lifetime points, streak (consecutive days played), and accuracy percentage.
   - Fan Levels: *Gully Cricketer* (0-25 pts), *Club Batter* (26-75 pts), *Ranji Star* (76-150 pts), *National Cap* (151-300 pts), *Cricket Legend* (300+ pts).
3. **Seamless Auth Integration**:
   - Phone OTP sign-in integrates directly with user account stats.
   - Instant points sync when logged in via `/v1/trivia/submit`.
