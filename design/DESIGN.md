# OpenWushu — Design (v0)

Status: first clickable prototype, for discussion. No app code yet; the tech stack is chosen after the design is agreed.

## Goal

An educational, community-maintained web app listing wushu **规定套路 (guīdìng tàolù — compulsory routines)**. Each routine has a video, a top-down carpet path diagram and the list of movements. Selecting a movement (e.g. #12) shows its details, seeks the video to that movement and highlights it on the carpet. Members open threads to tell contributors when something is wrong or has changed.

Sample content: **二十四式简化太极拳 (24-Form Simplified Taijiquan)**, with 42式 as the next routine.

## Decisions so far

| Topic | Decision |
|---|---|
| Platform | Responsive web app (desktop + phone) |
| Video | Self-hosted uploads; each movement stores a start/end timestamp |
| Map | Top-down diagram of the 14 m × 8 m competition carpet showing the athlete's path |
| Languages | **Chinese (characters + pinyin) is always shown** — it is the source. The switcher only changes the translation: English ↔ Bahasa Indonesia. Chinese terms stay inline in descriptions, e.g. 左虚步 zuǒ xūbù |
| Colors | Blue `#50A0FF` + white. Navy `#06152B` text on the blue (white on `#50A0FF` is only ~2.6:1). Deeper `#1766C7` for blue text on white. Light tint `#F5F9FF` background. Amber only for warning badges, red only for error labels |
| Type | Noto Serif SC (Chinese display), Noto Sans SC + Inter (body) |
| Footer | Educational disclaimer is always pinned to the bottom of the screen |

## Screens

1. **Library (规定套路)** — routines grouped by style (太极拳, 长拳, 南拳, 器械). Search matches Chinese, pinyin with or without tones, English and Indonesian ("gao tan ma" → 高探马).
2. **Routine page** — video, movement timeline (one segment per movement), carpet map and movement list, all kept in sync. Controls: play/pause, previous/next movement, loop movement, 0.5× / 0.75× / 1×.
3. **Movement detail** — steps (动作过程), key points (要点), common mistakes (易犯错误), facing direction, "Draft · needs expert review" badge, link to the movement's threads. Empty state invites a contributor to write it.
4. **Discussions (讨论)** — list of routines with thread counts by status; each opens the routine's Discussion tab. Thread types: Error, Suggest change, Question, Rule update. Status: Open → Under review → Accepted / Rejected.
5. **Report an issue** — type, movement, part (name/translation, steps, key points, video timing, carpet path), summary, details, source, email-me option. Contributors of the routine are emailed.
6. **Contribute (贡献)** — step 1: choose a routine; step 2: choose a task — write descriptions, upload video (with rights confirmation, then mark movement start times), or check EN/ID translations. Everything is submitted for review.
7. **Sign in / Sign up / Verify email** — email + password or Google; sign-up asks display name, preferred translation, optional club, and acceptance of community guidelines. Contribute and Report an issue require signing in; reading never does.

## Content model (draft)

- **Routine**: style, name {zh, pinyin, en, id}, description, videos, carpet size, official source
- **Movement**: routine, number, name {zh, pinyin, en, id}, steps / key points / common mistakes {en, id}, facing, video start/end, carpet path points (metres)
- **Thread**: type, target (routine / movement / field), status, posts, watchers
- **Revision**: every content change is versioned (who, when, diff) and can be rolled back

## Roles and moderation (proposed)

| Role | How | Can |
|---|---|---|
| Visitor | no account | read, watch |
| Member | sign up + verify email | discuss, suggest edits (go to review queue) |
| Contributor | apply, approved by moderator, or after ~5 accepted suggestions | edit text/translations, upload video — still reviewed |
| Maintainer | appointed per routine (coach / certified judge) | approve or reject changes for that routine |
| Admin | project owner | appoint maintainers, ban, roll back |

Plus: sources required for content changes, rate limits for new accounts, all videos reviewed before publishing, report/ban.

## Open questions

- Illustrations or photo frames per movement, besides video?
- Multiple videos per routine (front/side, different athletes)?
- Strict invite-only contributors at launch?
- 讨论 tǎolùn vs 交流 jiāoliú for the Discussions label (avoid confusion with 套路 tàolù)?
- Next screens: request contributor access, maintainer review queue, profile & notifications.

## Prototype

`prototype/Main.dc.html` (+ `canvas.json`) is the source of the interactive prototype. It is a Design Component file that runs inside the Claude Artifact design canvas (it depends on that runtime's `support.js`), so it does not open as a standalone page. All sample content is illustrative: the video is simulated, timings and the carpet path are not measured, and the Indonesian translations and the #1 / #12 descriptions need review by a practitioner.
