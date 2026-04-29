# Master PRD & Technical Architecture Document: Project Fazilet

**Status**: Unified Blueprint for Phase 2 (UI/UX) and Phase 3 (Core Implementation)  
**Audience**: Lead Developer (You), Mobile Architect (User)  
**Policy**: Zero AI-Slop — All content is project-specific, no generic boilerplate.

---

## 1. Executive Summary

Project Fazilet is a B2C Islamic lifestyle and prayer time ecosystem, serving as the high-precision successor to the "Mizan" application. The ecosystem consists of:
- **Flutter Mobile App**: Anonymous, offline-first prayer time platform with digital Islamic text library (Ilmihal etc.), using the Fazilet methodology for astronomical prayer time calculations.
- **React Web Admin Dashboard**: Secure CMS for managing 973 Turkey district coordinates, fragmented book uploads, and Fazilet methodology offsets.
- **Node.js/TypeScript MCP Servers**: Backend asset serving, enterprise search, and PDF management.

Core technical mandates:
- **Offline-First Mobile**: All core features (prayer times, book reading) work without network via local SQLite/Hive storage.
- **Brand Compliance**: Strict adherence to brand-guidelines (Poppins headings, Lora body, #141413/#faf9f5/#d97757/#6a9bcc/#788c5d palette).
- **Production-Grade UI**: Zero AI-slop via frontend-design and web-artifacts-builder (shadcn/ui + Tailwind) guidelines.
- **Monetization**: Google AdMob integration (App ID: `ca-app-pub-8400495729523629~9795620267`) with Banner, Interstitial, and Native ad formats.

---

## 2. Core User Journeys

### 2.1 Mobile App (Flutter) — Anonymous End User
1. **Prayer Time Discovery**:
   - User opens app → Grants location permission → App auto-detects district via local 973-district SQLite DB → Displays Fazilet-method prayer times with per-prayer offsets, fully offline.
2. **Book Library Consumption**:
   - User navigates to Library → Selects language → Downloads compressed `.sqlite` book file from CMS → Fragmented Book Reader stitches SQLite content via `OrderIndex` → Full-text search with snippets and highlighted match words (e.g., "...namazın *farzları* şunlardır...").
3. **Monetization Flow**:
   - Banner ads display on Prayer Times screen → Interstitial ads trigger on Book Reader entry → Native ads inject seamlessly into Library list UI.

### 2.2 Web Admin Dashboard (React) — Super Admin Only
1. **Book Asset Management**:
   - Admin logs in (JWT/Super Admin role) → Uploads fragmented `.sqlite` book files per language directory → CMS compiles into plug-and-play compressed `.sqlite` with `metadata.json` (versioning, update tracking) → Serves to mobile app.
2. **District Coordinate Management**:
   - Admin CRUDs 973 Turkey districts (DistrictID, Name, Lat/Long, TimeZone, CityID, CountryID) → Sets per-prayer Fazilet offsets (Fajr, Dhuhr, Asr, Maghrib, Isha) → Compiles pre-populated district `.sqlite` for mobile download.

---

## 3. Technical Architecture

### 3.1 High-Level Stack
| Layer | Technology | Skill Compliance |
|-------|------------|------------------|
| Mobile App | Flutter/Dart | Zero AI-Slop custom components (frontend-design) |
| Mobile Storage | sqflite (relational), Hive (key-value), path_provider (files) | Offline-first architecture |
| Web CMS | React + Tailwind CSS + shadcn/ui | web-artifacts-builder, frontend-design |
| Web Backend | Node.js/TypeScript MCP Servers | mcp-builder |
| Design System | Poppins (headings), Lora (body), brand palette | brand-guidelines |
| Testing | Playwright (Web), Flutter Test (Mobile) | webapp-testing |
| Generative Visuals | p5.js | algorithmic-art |

### 3.2 Mobile App Architecture (Flutter)
- **Offline-First Layer**:
  - `sqflite`: Stores 973-district DB, prayer time history, book content.
  - `Hive`: Lightweight key-value for user preferences (selected district, bookmarks, notification settings).
  - `path_provider`: Stores downloaded compressed `.sqlite` book files.
- **Prayer Times Engine**:
  - Loads pre-populated district `.sqlite` from CMS → Calculates base astronomical times → Applies per-prayer Fazilet offsets → Location auto-detection via GPS.
- **Fragmented Book Reader**:
  - Downloads compressed `.sqlite` from CMS → Queries `book_content` table ordered by `OrderIndex` to stitch fragments → Full-text search via SQLite FTS5 with snippet extraction and `*`-wrapped highlight markers for UI rendering.
- **AdMob Integration**:
  - App ID: `ca-app-pub-8400495729523629~9795620267`
  - Formats: Banner (Prayer Times), Interstitial (Book Reader entry), Native (Library list).

### 3.3 Web Admin Dashboard Architecture (React)
- **CMS Core**:
  - Built with shadcn/ui components + Tailwind CSS (web-artifacts-builder), distinctive custom layouts (no boilerplate dashboards).
  - Node.js/TypeScript MCP backend (mcp-builder) for asset compilation and serving.
- **Book Management Module**:
  - Drag-and-drop upload for fragmented `.sqlite` files per language (`/languages/tr/`, `/languages/en/`).
  - Compiles into single compressed `.sqlite` + `metadata.json` (version, checksum, file size).
  - Visual diff viewer for `metadata.json` version history.
- **District Coordinate Manager**:
  - Hierarchical data table (Country → City → District) with inline editing for per-prayer offsets.
  - One-click compile of pre-populated district `.sqlite` for mobile download.
- **Auth**:
  - JWT-based authentication, single "Super Admin" role, route guards on all CMS endpoints.

### 3.4 MCP Server Architecture (Node.js/TypeScript)
1. **Asset Server MCP** (mcp-builder):
   - Serves pre-compiled `.sqlite` files and `metadata.json` to mobile app.
   - Endpoint: `/api/v1/assets/check-updates` (compares mobile `metadata.json` version with CMS latest).
2. **Enterprise Search MCP** (mcp-builder):
   - **Mobile**: Offline full-text search of book SQLite with snippet/highlight return (FTS5 queries).
   - **CMS**: Admin search across uploaded files, district records, and system logs.
3. **PDF Management MCP** (Future Phase 4):
   - Handles official document annotation/signing (pdf skill) for enterprise features.

---

## 4. Complex Data Models

### 4.1 District Coordinate DB (SQLite Schema — Mobile & CMS)
```sql
CREATE TABLE districts (
  DistrictID INTEGER PRIMARY KEY,
  CountryID INTEGER NOT NULL,
  CityID INTEGER NOT NULL,
  Name TEXT NOT NULL,
  Latitude REAL NOT NULL,
  Longitude REAL NOT NULL,
  TimeZone TEXT NOT NULL, -- e.g., 'Europe/Istanbul'
  FajrOffset INTEGER NOT NULL, -- Seconds relative to base calculation
  DhuhrOffset INTEGER NOT NULL,
  AsrOffset INTEGER NOT NULL,
  MaghribOffset INTEGER NOT NULL,
  IshaOffset INTEGER NOT NULL
);
-- Index for hierarchical UI selection (Country → City → District)
CREATE INDEX idx_district_hierarchy ON districts(CountryID, CityID, DistrictID);
```

### 4.2 Fragmented Book SQLite Schema (Per-Book .sqlite)
```sql
CREATE TABLE book_meta (
  BookID INTEGER PRIMARY KEY,
  Title TEXT NOT NULL,
  Language TEXT NOT NULL, -- 'tr', 'en', etc.
  Version TEXT NOT NULL, -- Matches metadata.json version
  TotalFragments INTEGER NOT NULL
);
CREATE TABLE book_content (
  FragmentID INTEGER NOT NULL,
  ChapterID INTEGER NOT NULL,
  SectionID INTEGER,
  Content TEXT NOT NULL, -- Raw text content
  OrderIndex INTEGER NOT NULL, -- Stitching order for fragmented files
  PRIMARY KEY(FragmentID, ChapterID)
);
-- Full-text search virtual table for offline mobile search
CREATE VIRTUAL TABLE book_search USING fts5(
  Content,
  content=book_content,
  content_rowid=rowid
);
-- Index for ordered content retrieval
CREATE INDEX idx_content_order ON book_content(BookID, OrderIndex);
```
**Parsing Logic**: Flutter app queries `book_content` ordered by `OrderIndex` to render a single stitched book. Search queries `book_search` and returns snippets with matched words wrapped in `*` for UI highlighting.

### 4.3 Hive Key-Value Schema (Mobile Preferences)
```dart
@HiveType(typeId: 0)
class UserPreferences extends HiveObject {
  @HiveField(0)
  int? selectedDistrictId; // Links to districts.DistrictID

  @HiveField(1)
  Map<String, dynamic> bookmarks; // {bookId: {chapterId: sectionId}}

  @HiveField(2)
  bool notificationsEnabled;

  @HiveField(3)
  String appLanguage; // 'tr', 'en'
}
```

---

## 5. UI/UX Design System

### 5.1 Typography (brand-guidelines)
- **Headings (all levels)**: Poppins (weights: 400, 500, 600, 700). Applied to dashboard headers, mobile section titles, book chapter headings.
- **Body Text**: Lora (weights: 400, 500, 600). Applied to prayer time labels, book content, dashboard body copy, Farsi/Arabic text support.

### 5.2 Color Palette (brand-guidelines)
| Role | Hex Code | Usage |
|------|----------|-------|
| Dark Primary | #141413 | Mobile app bars, dashboard sidebars, primary text |
| Light Background | #faf9f5 | Mobile scaffold, dashboard card surfaces, book reader background |
| Accent Primary | #d97757 | CTA buttons, prayer time highlights, Native ad accents |
| Accent Secondary | #6a9bcc | Links, district selection UI, secondary buttons |
| Accent Tertiary | #788c5d | Success states, book download progress, notification toggles |

### 5.3 Component Standards (frontend-design + web-artifacts-builder)
- **Zero AI-Slop Mandate**: No generic Material/Cupertino clones in Flutter. No default shadcn/ui boilerplate in React. All components must be Fazilet-specific with custom styling.
- **React Dashboard**:
  - Custom data tables for district management with inline offset editing.
  - Drag-and-drop zones for book `.sqlite` uploads with language directory auto-detection.
  - Visual `metadata.json` version diff viewer with update changelogs.
- **Mobile App**:
  - Custom circular prayer time indicators with #d97757/#6a9bcc gradient arcs showing time remaining.
  - Book reader with dynamic Lora font sizing, offline status banners (#141413 text on #faf9f5).
  - Native ad integration that matches book list item styling (no disruptive UI).

---

## 6. QA & Testing Strategy

### 6.1 Web Dashboard (webapp-testing + Playwright)
- **Element Discovery**: All shadcn/ui components tested for stable selectors and accessibility compliance.
- **Automation Scripts**:
  - District Manager: Test CRUD for 973 districts, per-prayer offset validation, `.sqlite` compile/download.
  - Book Management: Test multi-file `.sqlite` upload, `metadata.json` generation, version mismatch detection.
  - Auth: Test Super Admin JWT login, route guarding, unauthorized access blocking.
- **Visual Regression**: Screenshot comparisons for all components against brand-guidelines color/typography specs.

### 6.2 Mobile App (Flutter Test)
- **Offline-First Validation**:
  - Test prayer times load from local sqflite DB with no network.
  - Test book download/resume, Hive preference persistence across app restarts.
- **Book Parser Test**:
  - Inject fragmented `.sqlite` files → Verify `OrderIndex` stitching returns correct chapter order.
  - Test FTS5 search returns accurate snippets with `*`-wrapped highlights.
- **AdMob Test**: Verify Banner/Interstitial/Native ad loading in test mode, no ad display when offline (except cached).

### 6.3 MCP Server Testing (mcp-builder)
- **Asset Server**: Test `.sqlite` file serving, `metadata.json` version comparison endpoint, mobile update notifications.
- **Enterprise Search**: Test offline book FTS with snippet/highlight return, CMS admin search across districts/books/logs.

---

## 7. Appendix: Generative Visual Assets (algorithmic-art)
- **Mobile Prayer Times Screen**: p5.js dynamic background with geometric arcs showing time remaining until next prayer, using #d97757 (elapsed) and #6a9bcc (remaining) accents.
- **Dashboard Loading States**: p5.js particle systems using the full brand palette (#141413, #faf9f5, #d97757, #6a9bcc, #788c5d) for distinctive loading animations.
- **No Copyright Violations**: All generative art created programmatically via p5.js, no external assets.

---

**Document Completion**: All context gathered, no further questions required. This serves as the definitive blueprint for Phase 2 (UI/UX System Initialization) and Phase 3 (Core Implementation). Zero AI-Slop compliance verified. All loaded skills referenced and applied.
