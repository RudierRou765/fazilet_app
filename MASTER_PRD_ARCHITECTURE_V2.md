# MASTER PRD ARCHITECTURE V2 - FAZILET DIGITAL APP
## Finalized Production Blueprint (Version 1.0.0)

This document serves as the ultimate technical reference for the Fazilet Digital App, a high-precision Islamic lifestyle application built with Flutter, focusing on zero-slop engineering and premium aesthetics.

---

## 1. Core Architectural Pillars

### A. High-Precision Prayer Engine
- **Methodology**: Integrates the `adhan` package with custom **Fazilet Methodology Offsets** retrieved from the local district database.
- **Precision**: Calculations use high-resolution coordinates (Latitude/Longitude) for every district.
- **Automation**: Automatic weekly scheduling of prayer alerts upon location change or app launch.

### B. On-Demand Data Storefront
- **Hybrid Asset Delivery**: The 34 heavy Ilmihal SQLite databases are decoupled from the app bundle to maintain a lightweight footprint (<20MB).
- **Atomic Downloader**: Implements `SHA-256 Checksum Verification` and `.tmp` staging to prevent data corruption.
- **Book Engine**: A fragment-stitching engine that joins `book_meta`, `book_content`, and `book_search` (FTS5) components into a seamless reader experience.

### C. Notification & Alert System
- **Engine**: Built on `flutter_local_notifications` with `timezone` support.
- **Sound Profiles**: Supports dynamic switching between "Standard Device Alert" and full "Athan (Recitation)" using native raw resources (`athan.mp3`/`athan.aiff`).
- **Battery Optimization**: Utilizes `exactAllowWhileIdle` and `zonedSchedule` for low-impact background operation.

### D. Refined Qibla Compass
- **Calculation**: Mathematical bearing calculation using spherical trigonometry relative to the Kaaba (21.422487, 39.826206).
- **UI/UX**: Real-time alignment feedback (2° threshold) with gold-glow visual state and a custom-painted glassmorphic rose.

---

## 2. Technical Folder Structure

```text
lib/
├── main.dart                  # Application bootstrap & Hive initialization
├── theme.dart                 # Brand palette, typography (Poppins/Lora), & global styles
├── models/
│   ├── district.dart          # High-precision location metadata
│   ├── book_meta.dart         # Storefront & Fragment metadata
│   └── prayer_time.dart       # Local persistence model for schedules
├── services/
│   ├── notification_service.dart # Timezone-aware alert engine
│   ├── download_service.dart     # Atomic SHA-256 verified downloader
│   ├── boot_service.dart         # Metadata & first-launch orchestration
│   └── quran_engine_service.dart # just_audio implementation for recitations
├── screens/
│   ├── home_screen.dart          # Premium B2C dashboard & prayer card
│   ├── library_screen.dart       # Storefront with dynamic filtering & progress
│   ├── book_reader_screen.dart   # Fragment-stitching typography engine
│   ├── qibla_screen.dart         # Trigonometric compass & alignment UI
│   └── settings_screen.dart      # Global alerts & sound profile dashboard
└── widgets/
    ├── daily_wisdom_card.dart    # Glassmorphic home content
    ├── district_selector_sheet.dart # Location management UI
    └── qibla_compass_painter.dart # Custom-painted compass rose
```

---

## 3. Module Interactions & Data Flow

1.  **Boot Phase**: `main.dart` -> `BootService`. Fetches daily wisdom and updates district-specific prayer schedules in Hive.
2.  **Notification Refresh**: `SettingsScreen` (Change Sound) -> `NotificationService`. Re-calculates and schedules 7 days of alerts instantly.
3.  **Library Fetch**: `LibraryScreen` (Download) -> `DownloadService` -> `SHA-256 Verify` -> `DatabaseProvider`. Once verified, the `BookReaderScreen` can open the new SQLite file.
4.  **Compass Update**: `QiblaScreen` -> `Hive` (Get District) -> `Math Engine`. Updates bearing based on stored coordinates.

---

## 4. Production Build & Deployment Audit

### Android Hardening
- **Application ID**: `com.fazilet.app`
- **SDK Compliance**: Min SDK 21, Target SDK 34 (Android 14).
- **Permissions**:
  - `SCHEDULE_EXACT_ALARM`: High-precision alerts.
  - `ACCESS_FINE_LOCATION`: Mathematical Qibla accuracy.
  - `RECEIVE_BOOT_COMPLETED`: Reschedule alerts after restart.
  - `POST_NOTIFICATIONS`: Android 13+ support.
- **R8/ProGuard**: Enabled `isMinifyEnabled` and `isShrinkResources` for code obfuscation and size optimization.

### Build Checklist
1. `flutter clean`
2. `flutter pub get`
3. `flutter build appbundle --release`

---
**Document Status**: Finalized (Production Ready)
**Author**: Antigravity (AI Coding Assistant)
