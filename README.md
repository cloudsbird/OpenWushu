# OpenWushu
Community-maintained wushu taolu reference — scoring guides, deduction tables, compulsory sequences, and rule changelog. AI-assisted, certified-judge-verified.

## Background

Wushu **规定套路 (guīdìng tàolù — compulsory routines)** such as 四十二式太极拳 (42-Form Competition Taijiquan) are standardised: every athlete performs the same sequence of movements, and judges score them against the same standard. Yet learning one accurately is still hard:

- **The material is scattered.** Students piece a routine together from their coach, YouTube videos and printed or PDF books. No single place shows the movement, the video and where it happens on the floor at the same time.
- **Much of it is only in Chinese.** Official names and descriptions come from Chinese sources. Learners in Indonesia and elsewhere often rely on loose translations and lose the original terms.
- **The floor path is rarely shown.** Where each movement happens on the 14 m × 8 m carpet, and which way the athlete faces the judges, matters in competition but is seldom documented.
- **Corrections get lost.** When a detail is wrong or a rule changes, the fix stays in a chat group or a coach's head instead of reaching everyone.

OpenWushu brings these together in one open reference:

- Each routine shows its **video, carpet path and movement list in sync**. Select movement #2 and the video jumps to it while the carpet highlights where it happens.
- **Chinese names and pinyin are always kept** as the source, with translations in **English and Bahasa Indonesia**.
- Content is **community-maintained but verified**: anyone can read; members discuss and report mistakes in threads tied to a specific movement; verified contributors (accredited judges, coaches, or traditional school owners) write and review the content.
- Everything is **open**: the code under AGPL-3.0 and the content under CC BY-SA 4.0, so it stays free for clubs, schools and learners.

OpenWushu is for **educational purposes only**. Content may contain errors; always learn under a qualified coach.

## Design

The first design (screens, decisions, roles and an interactive prototype source) is in [`design/DESIGN.md`](design/DESIGN.md).

## Development

OpenWushu is a Ruby on Rails 8.1 app: PostgreSQL 18 with Solid Queue, Cache and Cable, Hotwire (Turbo and Stimulus) through import maps, and plain CSS. You need Ruby and PostgreSQL, with no Node build step.

PostgreSQL 18 on Debian or Ubuntu (including WSL), from the PostgreSQL project's own packages:

```sh
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
sudo apt install -y postgresql-18 libpq-dev
sudo service postgresql start          # WSL without systemd starts it this way
sudo -u postgres createuser -s "$USER" # lets Rails connect as you, without a password
```

To use another server, set `PGHOST`, `PGPORT`, `PGUSER` and `PGPASSWORD`.

```sh
# Ruby 4.0.9 (see .ruby-version)
bundle install
bin/rails db:prepare db:seed   # 42-form Taijiquan plus the other routines from the reference book
bin/dev                        # http://localhost:3000
bin/rails test                 # model and integration tests
bin/rubocop && bin/brakeman    # style and security checks
```

Emails in development are written to `tmp/mails/<address>` instead of being sent (open the link from there), and can be previewed at http://localhost:3000/rails/mailers.

In production, Kamal runs PostgreSQL 18 as the `db` accessory on the same server (`config/deploy.yml`); set `POSTGRES_PASSWORD` in your environment before deploying, and back the database up off the server. Also set `APP_HOST` (the domain used in email links) and `MAIL_FROM`, and add SMTP settings with `bin/rails credentials:edit`:

```yaml
smtp:
  address: smtp.example.com
  port: 587
  user_name: ...
  password: ...
```

Where things are:

- `app/models`: `Routine` and `Movement`. Chinese names are plain columns. `name_en` and `name_id` are the translations, and `name_tr` picks the one for the current locale.
- `app/javascript/controllers/routine_player_controller.js`: keeps the video, timeline, carpet path and movement list in sync. Without an uploaded video it runs a practice clock.
- `app/javascript/lib/figure3d.js`: draws the 图解 figures from 3D poses.
- `config/locales/{en,id}.yml`: UI strings. Chinese labels stay in the views and are never translated. `auth.{en,id}.yml` holds the account pages and emails.
- Accounts use Rails' built-in authentication plus sign-up and email verification (`RegistrationsController`, `EmailVerificationsController`). Reading never needs an account. Unverified members can sign in but not post (`User#verified?`).
- `db/seeds/routines.json`: seed content. Movement names and order come from the reference book; descriptions are in our own words and cite its pages.

## License

- **Code** is licensed under the [GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0). You may use, study, change and share it. If you distribute a modified version, **or let people use a modified version over a network (for example, run it as a website)**, you must make its source available under AGPL-3.0 too.
- **Content** — movement descriptions, translations, carpet paths, discussion threads and uploaded videos — is licensed under [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](LICENSE-CONTENT). You may share and adapt it, including commercially, as long as you credit OpenWushu and its contributors and release your changes under the same license.
