# Semestra — MVP Redesign + Google OAuth Onboarding

**Date:** 2026-09-05
**Status:** Approved design (pending final spec review)

## Goal

Bring the Flutter app in line with the 18-screen design handoff
(`Semestra.dc.html`) and add a real Google Sign-In onboarding flow, while
preserving the app's offline-first, local-storage model.

## Decisions (locked)

- **OAuth:** Real `google_sign_in`. App must remain runnable before Google
  Cloud credentials are configured (show a "sign-in not configured" hint
  instead of crashing). User supplies OAuth client IDs / console setup.
- **Scope:** Full redesign to match the handoff (4 tabs + compose ring, gold
  theme, all 18 screens).
- **Fonts:** Bundle Instrument Sans (400/500/600) `.ttf` into
  `assets/fonts/`, register in pubspec, no runtime download.

## Auth approach: identity-only gate (chosen)

`google_sign_in` provides the Google identity (email, name, photo). We store a
local profile, gate the app behind sign-in, and keep all app data on-device.
No Firebase, no backend. Username is validated locally (length/charset/format);
global uniqueness is a future concern. Rejected: Firebase Auth wrapper (adds
config, no benefit for offline MVP) and a full backend for unique usernames
(separate service, out of scope).

## Section 1 — Auth & onboarding architecture

New `features/auth/` module (clean architecture, matching existing features):

- **Entity:** `UserProfile { googleId, email, displayName, photoUrl, username,
  onboardedAt }`.
- **DB:** new `user_profile` table (single row); bump `DatabaseHelper` to v6.
  Existing `onUpgrade` drops/recreates safely and preserves `items`/`subjects`
  via the legacy-migration path.
- **Service:** `AuthService` wrapping `google_sign_in`
  (signIn / signOut / silent restore). If OAuth client IDs are unconfigured,
  sign-in surfaces a clear "not configured" state; UI shows a setup hint.
- **Provider:** `authNotifierProvider` exposing
  `AuthState { unknown, signedOut, needsUsername, needsSetup, ready }`.
- **Router gate:** `appRouter` gains a `redirect` driven by auth state:
  - `unknown` → splash
  - `signedOut` → `/welcome`
  - `needsUsername` → `/onboarding/username`
  - `needsSetup` → `/onboarding/subjects`
  - `ready` → `/today`

Onboarding routes (screens 01–05): `/welcome`, `/sign-in`,
`/onboarding/username`, `/onboarding/subjects`, `/onboarding/schedule`.
Subjects + class-times steps reuse the existing subject/schedule providers so
onboarding writes real data.

## Section 2 — Navigation restructure

Shell: 5 tabs → **4 tabs + center compose ring**: **Today** (`/today`),
**Planner** (`/planner`), **Subjects** (`/subjects`), **Notes** (`/notes`).
The compose ring (gold outlined circle) opens the compose sheet (screen 09:
Assignment / Task / Note / Study block).

Route remap:

- `/dashboard` → **`/today`** (dashboard feature becomes Today)
- `/workspace` → removed; **`/subjects`** becomes a real tab
- `/progress` → removed; folded into **Semester** (screen 17, from Today header)
- `/profile` → removed; folded into **Settings** (screen 18, from Semester header)
- **`/notes`** becomes a real tab (item feature filtered to notes)
- Pushed routes: `/assignments` (screen 10), `/assignments/edit`,
  `/notes/edit`, `/subjects/:id` (screen 14), `/semester` (screen 17),
  `/settings` (screen 18).

Untracked `features/workspace`, `features/progress`, `features/profile` dirs
are removed (surviving ideas live in Subjects/Semester/Settings). Legacy
redirects keep old links alive.

**Assignments (10–12)** are pushed pages (off Today's "All assignments" link
and the compose sheet), not a top-level tab — consistent with the 4-tab model.

## Section 3 — Theme overhaul

Rewrite `AppTheme` to the handoff's warm/gold system:

- **Bg** `#F3F2F2`, **elevated** `#EAE9E9`, **ink** `#201F1D`; muted/faint via
  opacity.
- **Gold `#B68235` is stroke-only** — borders, active tab, priority labels, the
  compose ring, focus states. Never a large fill. Deeper gold `#7D5411` for
  gold text.
- **Subjects differentiated by a 2px tonal spine**, not competing hues. Palette:
  `#7D5411 / #C28D41 / #605D5D / #9B9797 / #BAB6B6`. Helper maps a subject's
  index/color to a spine tone.
- **Font:** bundle **Instrument Sans** (400/500/600), set as `fontFamily`.
  Tabular numerals via `fontFeatures: [FontFeature.tabularFigures()]` on a
  `tnum` text style so times/dates/counts align.
- Dark theme retained but retuned to warm neutrals.

## Section 4 — Screen rebuild (the 18)

- **Auth (01–05):** welcome, sign-in, username, add-subjects, class-times.
- **Today (06):** week-of banner, "Now" live class, "Later today", "Due next",
  semester-progress card, Saved chip. Header links to Semester.
- **Planner (07–08):** Week/Day segmented toggle; week grid (weekdays,
  deadlines listed below) + day timeline.
- **Compose (09):** bottom sheet, 4 choices.
- **Assignments (10–12):** grouped by urgency (Overdue/This week/Later),
  priority as stroked label, hairline progress, empty state, editor (11) with
  subject chips + steps + reminder toggle.
- **Subjects (13–14):** card list with counts + next-due; detail with
  Overview/Notes/Tasks/Info tabs.
- **Notes (15–16):** grouped by recency, subject filter chips, two-line
  previews; editor with subject chip, autosave stamp, formatting rail.
- **Semester (17):** 14 week-blocks spine, three figures (replaces Progress),
  per-subject completion. Settings icon → Settings.
- **Settings (18):** "Your data" (offline story, export/restore/sync toggle),
  Semester, Reminders, plus **Account** (signed-in-as + sign out).

Data wiring uses existing providers (`itemNotifierProvider`, `subjectProvider`,
`scheduleProvider`, `semesterProvider`, `settingsNotifierProvider`); computed
views (urgency grouping, week grid) are derived in the presentation layer or
small selector providers.

## Section 5 — Testing & verification

- Widget tests: auth-state routing (each state → correct redirect) and username
  validation.
- DB migration test: v5→v6 keeps items/subjects, adds profile.
- `flutter analyze` + `flutter test` clean before done.
- Manual run confirming onboarding → today flow.

## What the user provides (not blocking the build)

Google Cloud OAuth setup — client IDs, Android SHA-1, iOS URL scheme. Build
proceeds against the real package with a `docs/` setup guide; the app runs with
a "sign-in not configured" hint until credentials are plugged in.
