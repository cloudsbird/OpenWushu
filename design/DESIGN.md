# OpenWushu — Design (v0)

Status: first clickable prototype, for discussion. No app code yet; the tech stack is chosen after the design is agreed.

## Goal

An educational, community-maintained web app listing wushu **规定套路 (guīdìng tàolù — compulsory routines)**. Each routine has a video, a top-down carpet path diagram and the list of movements. Selecting a movement (e.g. #12) shows its details, seeks the video to that movement and highlights it on the carpet. Members open threads to tell contributors when something is wrong or has changed.

Sample content: **四十二式太极拳 (42-Form Competition Taijiquan)** from the main reference, with **#2 右揽雀尾** as the fully worked example (steps, key points, mistakes, illustrations, threads, revisions). The library lists the reference's other nine competition routines.

## Decisions so far

| Topic | Decision |
|---|---|
| Platform | Responsive web app (desktop + phone) |
| Video | Self-hosted uploads; each movement stores a start/end timestamp |
| Map | Top-down diagram of the 14 m × 8 m competition carpet showing the athlete's path, the front edge (正面), and the judges' table (裁判席) below it with the head judge (裁判长) in the centre. Seat count is configurable per competition rules |
| Languages | **Chinese (characters + pinyin) is always shown** — it is the source. The switcher only changes the translation: English ↔ Bahasa Indonesia. Chinese terms stay inline in descriptions, e.g. 左虚步 zuǒ xūbù |
| Colors | Blue `#50A0FF` + white. Navy `#06152B` text on the blue (white on `#50A0FF` is only ~2.6:1). Deeper `#1766C7` for blue text on white. White paper background; seal and blue text `#1766C7`. Amber only for warning badges, red only for error labels |
| Visual style | **拳谱 training manual × 青花 blue-and-white porcelain**: reads like a printed manual, not a generic app. Square corners, hairline rules, a 3 px ink rule on top of each panel and a double rule under the header; page titles set vertically in Chinese (规定套路, 讨论, 贡献…) beside the English title; movements numbered 十二 over 12, "第二式" in the detail; steps numbered 一 二 三; logo is a blue seal stamp (印章) reading 武术; avatars and markers are square like small seals (only the judges' seats stay round) |
| Type | **Ma Shan Zheng** 楷书 brush script for vertical page titles, the seal and 第二式; **Noto Serif SC** 宋体 for movement names, Chinese headings and numerals (brush for titles, printed Song for text, as in Chinese books); **Alegreya** for English headings and *italic pinyin*; **Alegreya Sans** for body/UI (16 px); **IBM Plex Mono** for timestamps and counts |
| Pinyin rule | Every Latin font must contain all tone-marked vowels (ā á ǎ à … ǖ ǘ ǚ ǜ), or the browser mixes in a fallback mid-word. Checked against Google Fonts: Alegreya, Alegreya Sans, IBM Plex Mono, Noto, Source Serif 4, EB Garamond pass; Newsreader, Spectral, Crimson Pro, Lora, Fraunces, Work Sans, Public Sans, JetBrains Mono fail |
| Footer | Educational disclaimer + "Content licensed CC BY-SA 4.0" + "Source code on GitHub" links, always pinned to the bottom of the screen. The Contribute page also has an "Are you a developer?" box linking to the repo |
| License | Code: **AGPL-3.0** (`LICENSE`) — modified versions run as a public website must share their source. Content — descriptions, translations, carpet paths, threads and uploaded videos: **CC BY-SA 4.0** (`LICENSE-CONTENT`) |

## Licensing in the product

- **Sign up**: the community-guidelines checkbox states that contributions are published under CC BY-SA 4.0.
- **Upload video**: the rights checkbox reads "I have the right to share this video and agree to publish it under CC BY-SA 4.0". Uploaders keep their copyright and grant the license.
- **Contribute**: the note under every submit button says published content is licensed CC BY-SA 4.0.
- **Attribution**: each movement/routine page credits its contributors (revision history), which satisfies the license's attribution requirement for reusers.
- **Sources**: contributors write descriptions in their own words and cite the source; text copied from official books or rulebooks is not accepted, since it is copyrighted by its publisher.

## Screens

1. **Library (规定套路)** — routines grouped by style (太极拳, 长拳, 南拳, 器械). Search matches Chinese, pinyin with or without tones, English and Indonesian ("lan que wei" → 揽雀尾). Under each available routine, a **动作名称 movement index** lists every movement by section (第一段 … 第四段), numbered the book's way （一）（二）… with Chinese, pinyin and translation; clicking one opens the routine at that movement (video, carpet and detail panel). The index can be hidden.
2. **Routine page** — video, movement timeline (one segment per movement), carpet map and movement list, all kept in sync. Controls: play/pause, previous/next movement, loop movement, 0.5× / 0.75× / 1×.
3. **Movement detail** — steps (动作过程), key points (要点), common mistakes (易犯错误), facing direction, "Draft · needs expert review" badge, link to the movement's threads. Empty state invites a contributor to write it.
4. **Discussions (讨论)** — list of routines with thread counts by status; each opens the routine's Discussion tab. Thread types: Error, Suggest change, Question, Rule update. Status: Open → Under review → Accepted / Rejected.
   - **Thread page**: opening a thread shows the original post, replies (each author with their role badge: Member, Verified · Judge / coach, Verified · School owner, Maintainer), status changes inline in the timeline, and an "Accepted answer" marker. Signed-in members can reply (replies are public, CC BY-SA 4.0) and **Watch** the thread to get emails; posting a reply watches it automatically. Signed-out visitors see "Sign in to reply".
   - **One language per thread**: every thread is written in 中文, English or Bahasa Indonesia, shown as a language tag. The thread list has a language filter (All / 中文 / English / Bahasa Indonesia) that defaults to the viewer's translation language; the Discussions page shows thread counts per language. Replies stay in the thread's language ("Reply in Bahasa Indonesia"). Times and status-change events are generated by the app, so they follow the viewer's UI language. Maintainers see threads in every language.
5. **Report an issue** — type, language of the thread, movement, part (name/translation, steps, key points, video timing, carpet path), summary, details, source, email-me option. Contributors of the routine are emailed.
6. **Contribute (贡献)** — step 1: choose a routine; step 2: choose a task — write descriptions, upload video (with rights confirmation, then mark movement start times), or check EN/ID translations. Everything is submitted for review.
7. **Sign in / Sign up / Verify email** — email + password or Google; sign-up asks display name, preferred translation, optional club, and acceptance of community guidelines. Contribute and Report an issue require signing in; reading never does.

8. **Review queue (审核)** — maintainers only (a "Review" tab with a pending count appears in the header). Two tabs:
   - *Content changes*: list + detail with a **before/after diff** (removed text struck through on red, added text underlined on blue), field and language, contributor badge, source, linked thread. Actions: **Approve and publish**, **Request changes**, **Reject** — the last two require a note to the contributor. Video uploads show a preview with how many movement start times are marked.
   - *Contributor applications*: Path A shows credential, level, association, expiry and the document; Path B shows school, lineage, founded, city and evidence. A **reviewer checklist** (e.g. "Checked the association's public registry", "Both vouching contributors confirmed"). Actions: **Approve**, **Ask for a video call**, **Reject**. Documents are visible only to admins and deleted on decision.
   - Maintainers never review their own submissions.
9. **Revision history (修订)** — opened from "History · n revisions" in the movement detail. Lists every revision (r1 created from the official list … current), each with summary, author + badge, who approved it, field, language, source and a before/after diff. Maintainers can **Restore this version** (saved as a new revision, so nothing is lost). Doubles as the CC BY-SA attribution record.
10. **Video timings & path editor** — a Contribute task for verified contributors. Play the video (±0.5 s), select a movement, **Set start to [current time]** (must fall between the previous and next movement), then **click on the carpet** where the movement ends; x / y fields give a keyboard alternative, plus facing direction. Shows start times and how many path points are placed; submitted for review.
11. **Profile (个人)** — seal-style avatar, badge, email; **my contributions** with status (in review / changes requested / published) linking to history; **watched threads** with unwatch; **email notifications** (switches for replies, status changes, reviews, new threads on maintained routines, monthly news), frequency (right away / daily digest) and email language; **your data** (download / delete under UU PDP). The prototype adds a "view as" role switcher (member / verified judge / verified school owner / maintainer).
12. **Email templates** (separate artboard `prototype/Emails.dc.html`, EN/ID): verify email, new reply in a watched thread (quotes the reply in the thread's language), change published (with reviewer note), contributor approved (badge + documents deleted). Each has a reason line, "Manage email settings" and an unsubscribe/stop link.

13. **图解 Illustrations** — in the movement detail, between the name and the steps: line-drawing figures in the classic textbook style (clean figure, dashed curved arrows for the motion path), one per step, captioned 图 2-1, 2-2… Clicking a figure enlarges it, highlights the matching step (一 二 三 四) and jumps the video to that moment. Each figure shows how it was made and who reviewed it; a **Reference** line cites the source book and page. Verified contributors add figures through the **Upload illustrations** task (movement, how it was made, license, one file per step, reference used); the review queue shows figure submissions with their provenance.

## Sources and illustrations

OpenWushu uses **one modern wushu reference as its only source**: a collection of **competition routines (竞赛套路)**, available to the project only as a 720-page scan (PDF created July 2008). The scan has no title page or 版权页, so the title, publisher, year and ISBN are unknown; cite it as **"Competition routines collection (scan)"** with routine, page and figure. Each routine has 动作名称 (movement names), 动作说明 (steps with 要点 and 教法提示) and line-drawing figures numbered by a routine letter:

| Book page | Routine | Figures |
|---|---|---|
| 1 | 长拳 Changquan (58 movements + 起势/收势, 4 sections) | 图 A-… |
| 69 | 刀术 Broadsword | 图 B-… |
| 153 | 剑术 Straight sword | 图 C-… |
| 233 | 棍术 Staff | 图 D-… |
| 325 | 枪术 Spear | 图 E-… |
| 420 | 南拳 Southern fist | 图 F-… |
| 482 | 南刀 Southern broadsword | 图 G-… |
| 535 | 南棍 Southern staff | 图 H-… |
| 596 | 太极拳 42-form competition Taijiquan (4 sections) | 图 I-… |
| 660 | 太极剑 Taiji sword | 图 J-… |

Book page *n* is PDF page *n + 1*. The scan itself is never committed (`*.pdf` is in `.gitignore`). It is a modern publication and must be treated as copyrighted, so:

- **Allowed:** using it for facts (movement order, directions, the idea behind a key point), writing descriptions in our own words, citing it ("Reference: [title], p. 280, 图 D-95"), and imitating its *style* of line drawings.
- **Not allowed without the publisher's written permission:** scans, crops or tracings of its figures; its 要点 / 教法提示 text copied word for word or translated as-is; AI redraws of its figures.
- **Illustrations** are therefore drawn new — ideally generated from OpenWushu's own videos (frame at each step → pose detection → clean line figure → motion arrows), or hand-drawn / traced from contributors' own photos. Every figure records **how it was made** (hand-drawn · traced from own photo/video · generated from own video · AI-assisted from own images · public-domain scan), its **license** (CC BY-SA 4.0 own work · public domain · used with written permission) and the reference used, and is checked in the review queue.

## Content model (draft)

- **Routine**: style, name {zh, pinyin, en, id}, description, videos, carpet size, official source
- **Movement**: routine, number, name {zh, pinyin, en, id}, steps / key points / common mistakes {en, id}, facing, video start/end, carpet path points (metres)
- **Thread**: type, target (routine / movement / field), status, posts, watchers
- **Revision**: every content change is versioned (who, when, diff) and can be rolled back

## Roles and moderation (proposed)

| Role | How | Can |
|---|---|---|
| Visitor | no account | read, watch |
| Member | sign up + verify email | discuss, report issues, check translations (reviewed) |
| Verified contributor | apply through Path A or Path B below, approved by an admin | write steps / key points / mistakes, upload demonstration videos, add traditional notes — still reviewed |
| Maintainer | appointed per routine (accredited judge or senior coach) | approve or reject changes for that routine; final approval for compulsory routines against the official standard |
| Admin | project owner | verify applications, appoint maintainers, ban, roll back |

Plus: sources required for content changes, rate limits for new accounts, all videos reviewed before publishing, report/ban.

## Becoming a verified contributor

Two paths, because many traditional school owners (师父) never took association exams:

- **Path A: Association accreditation.** Judge certificate, coach licence, duan rank (段位) or athlete competition record. Fields: credential type, level (international / national / provincial / club), issuing association, full name, certificate number (optional), valid until, document upload, styles known.
- **Path B: School owner or traditional master.** School name, style and lineage, teacher (师父), year founded, city, plus **at least two** kinds of evidence: school registration or permit; public presence (website, social media, map); lineage / discipleship certificate (拜师帖); cultural-heritage or media recognition; video of teaching or performing; vouching by two verified contributors.
- **Review:** an admin checks the evidence (and public registries where they exist), may do a short video call, then approves or rejects. Status: Submitted → Reviewing evidence → Verified.
- **Privacy (UU PDP):** documents are used only to verify, deleted after review; only the badge, its type and the date checked are kept. Expiring credentials are re-checked.
- **Badges** show the kind of expertise, not a ranking: "Verified · Judge / coach", "Verified · School owner". They appear in the header, on profiles and on every contribution ("Reviewed by a verified national judge").
- **Traditional notes (传统要点):** a section in the movement detail where verified school owners describe how their lineage teaches a movement. It is shown separately from the competition key points, which stay the standard for scoring.
- **Gating in Contribute:** members can check translations; writing descriptions and uploading videos show a "Verified contributors only" panel with an Apply button (or the pending status).

## Open questions

- Illustrations or photo frames per movement, besides video?
- Multiple videos per routine (front/side, different athletes)?
- Strict invite-only contributors at launch?
- 讨论 tǎolùn vs 交流 jiāoliú for the Discussions label (avoid confusion with 套路 tàolù)?
- Still to design: about/landing, community guidelines, privacy policy & terms, empty/error/404/offline states, full search results page.

## Prototype

`prototype/Main.dc.html` (+ `canvas.json`) is the source of the interactive prototype. It is a Design Component file that runs inside the Claude Artifact design canvas (it depends on that runtime's `support.js`), so it does not open as a standalone page. All sample content is illustrative: the video is simulated, timings and the carpet path are not measured, and the Indonesian translations and the #1 / #12 descriptions need review by a practitioner.
