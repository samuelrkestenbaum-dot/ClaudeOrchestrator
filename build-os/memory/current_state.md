# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS orchestrator framework (packets, receipts,
  memory). Companion deliverable repo: `/home/user/Happymediumsetlist` — Happy
  Medium setlist lyrics .docx generator.
- **Primary branch / base:** `claude/song-lyrics-docx-ksh0qr` (both repos;
  Happymediumsetlist branch pushed to origin).
- **Build/test command (deliverable repo):** `python3 test_generate.py`
  (6 tests); regenerate docx with `python3 generate_setlist_docx.py`.

## Where we are

- **Last closed packet:** P-001 — Happy Medium setlist, one-page-per-song
  lyrics .docx (44 songs, 3 sets 17/15/12). Receipt:
  `build-os/receipts/P-001.md`.
- **Now:** none.
- **Next:** likely "paste real lyrics + regenerate/refit", or a PDF/print
  follow-up if requested.

## Stable facts (slow-changing)

- Deliverable repo layout (`/home/user/Happymediumsetlist`):
  - `setlist.json` is the single source of truth for songs, sets, titles, keys.
  - `lyrics/<song-slug>.txt` bodies render **verbatim** into the docx (no
    header inside the txt; titles/keys come from setlist.json).
  - `generate_setlist_docx.py` auto-fits lyric font 12→7pt with an exact line
    rule (`Pt(font_pt * 1.15)`); one page per song, 2-column body.
- Copyright rule: no lyric text is ever generated — user pastes lyrics.
- "Free Fallin'" key: F (original recording key; D shapes capo 3).

---
_Updated by the archivist on close of P-001 (2026-07-02)._
