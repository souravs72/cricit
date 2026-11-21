# Tech Stack Specification — CRICIT

## Architectural Constraints & Technology Matrix

### 1. Mobile & Web Frontend (Flutter)
- **Framework**: Flutter 3.24+ / Dart 3.5+
- **Platforms**: Mobile (Android APK, iOS), Flutter Web (Desktop & Mobile Browser UAT)
- **State Management**: `flutter_riverpod: ^3.0.0`
- **Routing**: `go_router: ^14.6.0`
- **Networking**: `dio: ^5.7.0`
- **Media & Caching**: `cached_network_image: ^3.4.1`, `url_launcher: ^6.3.1`
- **Video Subsystem**:
  - Web: Hardware-accelerated HTML iframe (`youtube-nocookie.com`) via `ui_web.platformViewRegistry` and `dart:ui_web` with zero pointer-blocking barriers.
  - Native Mobile / Hybrid: Embedded responsive player with instant poster fallback and direct external application handoff (`launchUrl`).
  - Gesture Layer: Vertical and horizontal gesture arenas with explicit `IgnorePointer` wrapping on decorative scrims and HUD elements.

### 2. Design System & Tokens
- **Theme Standard**: Material 3 + Custom Sports Tokens (`CricitColors`, `CricitRadius`, `CricitSpace`).
- **Typography**: Barlow Condensed (Display/Headlines), Source Sans 3 (Body/Summary), Noto Sans Devanagari (Hindi translation).
- **Touch Target Standard**: WCAG 2.1 AA / Android 48dp minimum interactive touch bounding box with haptic confirmation.
- **Latency Target**: Sub-100ms UI response time on touch interaction; instant poster render before iframe hydration.

### 3. Backend & Newsroom Administration
- **API Engine**: FastAPI / Python 3.12 (`uvicorn` + `gunicorn`)
- **Database**: PostgreSQL 16 (asyncpg + SQLAlchemy)
- **Caching & Challenge Store**: Redis 7
- **Admin Portal**: Next.js 15 (React 19, Tailwind CSS, Radix UI)
- **Reverse Proxy**: Caddy 2 (TLS, Brotli/Zstandard, HTTP/2)
