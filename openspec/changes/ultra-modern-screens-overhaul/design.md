# Technical & UI/UX Design: Ultra-Modern Screen Overhaul

## 1. Architectural Architecture & Component Hierarchy

```
lib/
├── features/
│   ├── feed/
│   │   ├── presentation/
│   │   │   ├── feed_screen.dart           # Tab coordinator with "New Feed Available" pill
│   │   │   ├── news_card_view.dart        # Overhauled Inshorts-style card layout
│   │   │   ├── video_short_view.dart      # UNTOUCHED: preserved edge-to-edge reel
│   │   │   ├── ad_views.dart              # Overhauled full-page, bottom banner, and sponsored card
│   │   │   └── feed_controller.dart       # State management for tab feeds and pagination
│   │   ├── domain/
│   │   │   └── news_card.dart             # Model with curated fields (source, author, 60-word summary)
│   │   └── data/
│   │       ├── fixture_feed.dart          # 100% Indian domestic and grassroots curated data
│   │       └── feed_repository.dart       # Local + Remote repository
│   ├── search/
│   │   └── presentation/
│   │       └── search_screen.dart         # Overhauled search, trending list & category chips
│   ├── profile/
│   │   └── presentation/
│   │       ├── profile_screen.dart        # Overhauled profile header, bookmarks tab & settings
│   │       └── widgets/
│   │           ├── edit_profile_modal.dart
│   │           └── settings_tile.dart
│   └── auth/
│       └── presentation/                  # Polished welcome, phone, OTP, setup screens
```

## 2. Screen Specifications

### 2.1 News Card View (`news_card_view.dart`)
- **Visual Grid**:
  - Top Hero: 16:9 high-definition image container with rounded corners (16px), subtle top gradient overlay.
  - Floating Badges: Category pill (e.g. "Ranji Trophy", "Syed Mushtaq Ali", "Nxtspot Talent") on top-left; Bookmark + Share icon buttons on top-right with tap animations.
  - Media Attribution: Source icon + Media house name (e.g. Cricbuzz, ESPNcricinfo, BCCI) + publication timestamp.
  - Headline Hook: Bold, modern typography (20-22px, `FontWeight.w700`, line height 1.25).
  - Curated Summary: Clean 60-word paragraph with optimized line spacing (1.45) and contrast.
  - Metadata Footer: Author name ("By Shayan Acharya") + Media House.
  - Footer Action Bar: "Tap to read full story" with subtle animated arrow, triggering `InAppWebSheet`.
  - Language Switcher: Quick EN / HI chip toggle directly accessible.

### 2.2 Domestic & Nxtspot Data Enforcement
- **Domestic Tab**:
  - Filter rule: `category == 'domestic'`
  - Content Guarantee: BCCI domestic fixtures only (Ranji Trophy, Duleep Trophy, Vijay Hazare Trophy, Syed Mushtaq Ali Trophy, Irani Cup, WPL domestic feeder, State tournaments). Zero foreign domestic content.
- **Nxtspot Tab**:
  - Filter rule: `category == 'grassroots' || kind == 'nxtspot'`
  - Content Guarantee: Indian grassroots talent, district tournaments, school/college leagues (Harris Shield, Cooch Behar), talent trials.

### 2.3 Search Screen (`search_screen.dart`)
- **Header**: Ultra-modern search bar with debounce, leading search icon, trailing clear button.
- **Quick Action Pills**: Indian Cricket, Ranji Trophy, SMAT, Bumrah, Kohli, WPL, Nxtspot Prodigies, CSK, MI.
- **Trending Headlines**: List of breaking stories with rich media thumbnails, source badges, and timestamps.
- **Recent Searches**: Chip cloud with one-tap recall and clear history.

### 2.4 Profile Screen (`profile_screen.dart`)
- **Header**: Circular avatar with edit badge, user name ("Cricket Fan"), favorite Indian team badge, and stats row (Articles Read, Videos Watched, Saved Stories).
- **Bookmarks Section**:
  - Tab view: All Saved | Articles | Reels.
  - Beautiful empty state when no bookmarks exist with "Explore Feed" button.
- **Settings & Preferences**:
  - Display: Night Mode (Light / Dark / System), HD Images toggle, Text Size (Standard / Large).
  - Playback: Video Autoplay toggle (defaults to on).
  - Localization: Language selector (English / Hindi).
  - Community & Legal: Share Cricit, Rate Us, Privacy Policy, Terms, App Version.

### 2.5 Ad Placements (`ad_views.dart`)
- **Full-Page Ad Card**: In-stream card matching the vertical deck with "Sponsored" tag and branded CTA button.
- **Bottom Footer Banner**: Slim non-intrusive banner above bottom navigation.
- **Short Post Sponsored Card**: Inshorts-style sponsored read with "Tap to know more" CTA.
