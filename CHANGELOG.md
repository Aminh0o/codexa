# Changelog

All notable changes to **Codexa** are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses
semantic versioning.

## [1.0.0] — 2026-09-20

First public pre-release. Android build signed with the project release key.

### Added

- **Offline-first library** — books, documents, sections, search, bookmarks and
  reading progress are served entirely from a local SQLite database, with no
  connectivity required to read downloaded material.
- **Google Drive source** — sign in with Google and mirror a Drive folder as a
  book, with subfolders as sections and PDFs as documents, including PDF
  metadata and cover extraction.
- **Download manager** — queued downloads with progress, pause, resume, cancel,
  retry, and per-book / global storage totals.
- **Reader** — PDF reading with page position restored across app restarts.
- **Localization** — Arabic (default, full RTL), English and French.
- **Theming** — light, dark and system modes on the Codexa design system.
- **Settings storage view** — downloaded size, document counts and device
  storage breakdown.
- **Regression suite** — 66 tests covering sync merge atomicity, discovery
  safety, download state transitions and storage accounting.
- **CI** — analyze, tests and a release build on every push and pull request.

### Changed

- Removed misleading wording for local-download actions: it now clearly states
  that files are removed from the device only, never from Google Drive.
- Download pause and cancel are reported truthfully instead of collapsing into a
  failed state; a paused item stays queued and resumes correctly.

### Fixed

- Storage aggregates are recomputed atomically when a download is removed, so
  book and Settings totals drop to the correct value immediately.
- A successful but empty Drive listing can no longer wipe a book's structure.
- Documents that are fully downloaded locally are never deleted during sync
  discovery, protecting reading progress and bookmarks from cascading deletes.
- Library search failures now surface a visible, retryable error state.
- Renaming a book no longer accepts an empty name silently.
- Stale download states left by an interrupted session are reset on launch.
- Google sign-in errors are mapped to readable messages instead of raw status
  codes.

### Known limitations

- Release builds require the signing keystore's SHA-1 fingerprint to be
  registered in the Google Cloud / Firebase OAuth client.
- iOS is buildable but has not been submitted to the App Store.
- EPUB and non-PDF formats are not supported yet.

[1.0.0]: https://github.com/Aminh0o/codexa/releases/tag/v1.0.0
