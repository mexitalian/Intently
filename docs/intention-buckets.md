# Feature Investigation: Intention Buckets (App Filtering by Intent)

> Status: Exploration / Feasibility
> Date: 2026-11-07

## Goal

Filter the app drawer (and potentially home screen) by "intention buckets" — e.g.
"Think" shows AI assistants, note-taking, and knowledge apps. Apps can satisfy
multiple intents, so classification is inherently loose; the goal is a useful
first-pass filter, not a perfect taxonomy.

## What Android Exposes to a Launcher

### Available without special permission

| Signal | Source | Usefulness for intentions |
|---|---|---|
| **Package name** | `LauncherApps.getActivityList()` | Strongest signal — `com.obsidian.md`, `com.openai.chatgpt` are instantly recognizable |
| **App label** | `ActivityInfo.loadLabel()` | Good for keyword matching ("Notes", "AI", "Chat") |
| **ApplicationInfo.category** | API 26+ (Play Store metadata) | 10 categories (see below). Coarse but useful |
| **Intent filters** | `PackageManager.queryIntentActivities()` | Functional capability: apps handling ACTION_SEND, ACTION_VIEW, ACTION_EDIT |
| **Icon** | `ActivityInfo.loadIcon()` | Visual only |
| **Install time / last updated** | `PackageInfo` | Could weight recency |
| **System vs user app** | `ApplicationInfo.flags` | Filter system apps from intention lists |

### Available with permission

| Signal | Permission | Usefulness |
|---|---|---|
| **Usage stats** (screen time, frequency, last-used) | `PACKAGE_USAGE_STATS` | Can infer usage habits (morning vs evening) but not semantic intent |
| **App usage events** (foreground/background transitions) | `PACKAGE_USAGE_STATS` | Timeline of app usage — could cluster co-occurring apps |

### NOT available to launchers

- App's internal content or data
- App descriptions (unless fetched from Play Store API — network + ToS concerns)
- User's in-app behavior
- Runtime permission grants (only declared permissions in manifest)

## Android `ApplicationInfo.category` (API 26+)

| Constant | Value | Description |
|---|---|---|
| `CATEGORY_GAME` | 0 | Games |
| `CATEGORY_AUDIO` | 1 | Audio/music (music players) |
| `CATEGORY_VIDEO` | 2 | Video/movies (streaming) |
| `CATEGORY_IMAGE` | 3 | Images/photos (camera, gallery) |
| `CATEGORY_SOCIAL` | 4 | Social (messaging, email, social networks) |
| `CATEGORY_NEWS` | 5 | News (newspapers, magazines, sports) |
| `CATEGORY_MAPS` | 6 | Maps/navigation |
| `CATEGORY_PRODUCTIVITY` | 7 | Productivity (cloud storage, workplace) |
| `CATEGORY_ACCESSIBILITY` | 8 (API 31+) | Accessibility (screen readers) |
| `CATEGORY_UNDEFINED` | -1 | Undefined — **most apps fall here** |

**Limitation:** Most apps report `CATEGORY_UNDEFINED` because developers don't set
the `android:category` attribute. So this alone is very coarse — ~90% of apps
would be "undefined."

### Google Play Store Categories (NOT on-device)

~30+ categories: Art & Design, Auto & Vehicles, Beauty, Books & Reference,
Business, Comics, Communication, Dating, Education, Entertainment, Events,
Finance, Food & Drink, Games (many subcategories), Health & Fitness, House &
Home, Libraries & Demo, Lifestyle, Maps & Navigation, Medical, Music & Audio,
News & Magazines, Parenting, Personalization, Photography, Productivity,
Shopping, Social, Sports, Tools, Travel & Local, Video Players & Editors, Weather.

These require the Play Store API (network + ToS concerns) — not practical for an
offline launcher.

### What's NOT Categorized at All (on-device)

- AI assistants (ChatGPT, Claude, Gemini, Perplexity)
- Note-taking (Obsidian, Notion, Logseq, Evernote)
- Browsers
- Calculators, clocks, calendars
- File managers
- Most utility apps

## Approaches for Intention Buckets

### 1. Heuristic rules (no ML, fully offline)

Map package names and categories to buckets:

```
"Think"  → category=PRODUCTIVITY, packages matching {obsidian, notion, evernote,
           chatgpt, claude, perplexity, gemini, onenote, roam, logseq}
"Read"   → category=NEWS or BOOKS, packages matching {kindle, pocket, feedly,
           medium, instapaper}
"Create" → category=PHOTO or VIDEO or MUSIC, packages matching {capcut, lightroom,
           procreate, garageband, flstudio}
"Move"   → category=HEALTH or MAPS or FITNESS, packages matching {strava,
           googlefit, maps, waze}
```

**Pros:** Instant, offline, deterministic.
**Cons:** Requires maintaining a curated package-name list; misses new apps.

### 2. Intent-filter capability analysis

Query which apps handle specific intents:

| Intent | Implies |
|---|---|
| `ACTION_SEND` (text/plain) | "Share" capability |
| `ACTION_VIEW` (text/*) | "Read" capability |
| `ACTION_EDIT` (text/*) | "Write" capability |
| `ACTION_DIAL` | "Communicate" |
| `ACTION_CAPTURE` / camera | "Capture" |

Functional capabilities, not semantic intentions. Needs combining with other signals.

### 3. Usage-pattern clustering

With `PACKAGE_USAGE_STATS`, group apps by co-occurrence (apps opened within 5 min).
Apps used together → same intention cluster. Unsupervised, adapts to user.

**Pros:** Personalized, learns actual behavior.
**Cons:** Needs permission, cold start, noisy clustering.

### 4. User-assigned tags (most reliable)

Let the user tag apps into buckets. Store in `Prefs` (like the existing rename-label
pattern: package → tag). Show untagged apps in a "suggestions" list.

**Pros:** 100% accurate to user intent.
**Cons:** Requires user effort; empty until tagged.

### 5. Hybrid (recommended for Intently)

1. **Seed with heuristics** — map known package names + Android categories to buckets
   on first run. Gives ~60-70% correct starting point.
2. **User override** — move apps between buckets (drag or long-press → "Move to Think").
3. **Usage-weighted ordering** — within each bucket, sort by usage frequency (if
   usage stats granted).
4. **Learn from corrections** — if user repeatedly moves apps from bucket A to B,
   adjust future heuristic suggestions.

## What's Available in Intently's Codebase Today

- `ApplicationInfo` is already accessed (for system-app detection) — `.category` is
  available on API 26+ (minSdk is 24, so guard with `Build.VERSION.SDK_INT >= 26`).
- `LauncherApps.getActivityList()` gives package name, label, icon, and
  `applicationInfo` — everything needed for heuristic classification.
- `Prefs` already stores per-app data (rename labels, hidden apps, swipe shortcuts)
  — adding a "bucket tag" per package is trivial.
- No usage stats permission is currently requested — would need to add
  `PACKAGE_USAGE_STATS` and a Settings toggle.

## Recommended Implementation Path

1. **Define bucket enum** (Think, Read, Create, Move, Connect, Play, etc.) —
   user-configurable list.
2. **Heuristic classifier** — a `Map<String, IntentionBucket>` seeded from known
   package names + `ApplicationInfo.category` mapping.
3. **Per-app override storage** in `Prefs` (package → bucket, like the existing
   rename-label pattern).
4. **Filter in app drawer** — show only apps matching the selected bucket; "All"
   shows everything.
5. **Optional usage stats** — for sorting within buckets (not classification).

## Signal Coverage Summary

| Signal | Coverage | Reliability |
|---|---|---|
| Package name heuristics | ~60% of apps | High for known apps, zero for unknowns |
| App label keywords | ~40% | Medium |
| Android category | ~10% | High when set, but rarely set |
| Intent filters | ~30% | Medium — functional, not semantic |
| User tagging | 100% | Perfect, but requires user effort |

The loosest part is the heuristic seeding, and apps often satisfy multiple intents.
The hybrid approach handles this: heuristics give a starting guess, the user
corrects, and the system learns.