# CODEXA — Product Requirements Document
## A library of your own

**Document:** Product Requirements Document  
**Product:** Codexa  
**Tagline:** A library of your own  
**Version:** 1.1  
**Status:** Product baseline / implementation-ready specification  
**Platform:** Mobile-first native application for Android and iOS  
**Primary framework:** Flutter / Dart  
**Primary cloud source:** Google Drive  
**Core promise:** Turn a user's Google Drive book folders into a beautiful, organized, offline-first personal library.

---

# 0. Document Purpose

This PRD defines the product, user experience, functional behavior, data requirements, synchronization model, non-functional requirements, security expectations, technical boundaries, MVP scope, acceptance criteria, and delivery phases for Codexa.

It is intended to be the authoritative product specification for:

- product decisions
- UI/UX implementation
- engineering implementation
- QA and acceptance testing
- future technical documentation
- AI coding agents and development assistants

The associated Codexa Design System is the visual source of truth for the application's brand and interface language.

---

# 1. Product Definition

## 1.1 Product name

**Codexa**

## 1.2 Tagline

**A library of your own**

## 1.3 Product category

Personal digital library / offline document reader / Google Drive library companion.

## 1.4 Product statement

Codexa allows users to connect their Google Drive account, select folders containing books and PDFs, and transform those folders into a structured personal library.

Codexa preserves the user's Drive organization while creating a dedicated reading experience:

**Drive Folder → Book → Parts / Sections → Documents → Pages**

Books can be synchronized to the device and read offline.

## 1.5 Product vision

Create the most elegant and focused personal reading experience for people who already own a collection of digital books but do not want to experience those books as ordinary cloud files.

Codexa should make digital books feel **collected, preserved, organized, and readable**.

## 1.6 Product philosophy

> **Ancient knowledge. Modern interface.**

Codexa should feel inspired by scholarly libraries, archival books, editorial publishing, and carefully preserved manuscripts while behaving like a fast contemporary mobile application.

The product must never become a museum replica or an ornamental file manager.

---

# 2. Problem Statement

Many users already have books stored in Google Drive, but Drive is not designed primarily as a dedicated reading library.

A typical collection may look like:

```text
My Drive/
├── The Feynman Lectures/
│   ├── Part I/
│   │   ├── Chapter 01.pdf
│   │   ├── Chapter 02.pdf
│   │   └── Chapter 03.pdf
│   ├── Part II/
│   │   ├── Chapter 04.pdf
│   │   └── Chapter 05.pdf
│   └── Part III/
│       └── ...
├── Meditations/
│   └── Meditations.pdf
└── Origin of Species/
    └── Origin.pdf
```

The files exist, but the experience is fragmented.

Users need to:

- repeatedly browse Drive
- remember folder structures
- wait for network access
- manually find documents
- tolerate a file-management interface while reading
- manage downloads separately from their conceptual library

Codexa solves this by introducing a dedicated library layer over the user's existing Drive organization.

---

# 3. Product Goals

## 3.1 Primary goals

### G1 — Create a personal library

Users can turn Drive folders into books and see them in one coherent library.

### G2 — Enable reliable offline reading

Downloaded books must remain readable without network access.

### G3 — Preserve meaningful structure

Drive folder hierarchy should become:

**Book → Part / Section → Document**

without requiring users to manually recreate the structure.

### G4 — Make reading the center of the experience

Codexa must feel like a reading application, not a cloud-storage client.

### G5 — Make synchronization understandable

Users should always understand whether their library is:

- synchronized
- updating
- partially downloaded
- offline
- missing content
- requiring attention

### G6 — Provide a premium identity

The application should have a distinctive visual language based on editorial publishing, scholarly archives, parchment, ink, engraving, and restrained antique details.

### G7 — Remain technically lightweight

The application must work reliably on ordinary mobile devices and must not require permanent network access to read downloaded books.

---

# 4. Product Success Criteria

The MVP is successful when a new user can:

1. Install Codexa.
2. Authenticate with Google.
3. Grant the required Drive access.
4. Browse Drive folders.
5. Select a folder as a book.
6. See the discovered book structure.
7. Start or complete the initial synchronization.
8. Open a downloaded PDF.
9. Read it without network access.
10. Close and reopen the app.
11. Continue from the previous reading position.
12. Return online and synchronize changes from Drive.
13. Manage local storage.
14. Remove a book without accidentally deleting the original Drive content.

---

# 5. Target Users

## 5.1 Primary user

A person who stores books, manuals, academic documents, or PDF collections in Google Drive and wants a dedicated reading library.

Characteristics:

- already uses Google Drive
- owns multiple digital books
- uses folders to organize books
- wants offline reading
- values organization and visual quality
- does not want to manually maintain a second copy of the library structure

## 5.2 Secondary user

A user with unstable or limited connectivity who needs previously downloaded books available locally.

## 5.3 Advanced user

A user with dozens of books and hundreds of documents who needs:

- search
- synchronization
- storage management
- reading progress
- structured navigation

---

# 6. User Needs

Users need to:

- understand what Codexa does immediately
- connect their Drive without confusion
- choose books quickly
- know what has been downloaded
- read without internet
- find a book quickly
- resume reading
- understand synchronization
- recover from failed downloads
- control local storage
- disconnect their Google account
- trust that removing a local book does not delete the Drive original

---

# 7. Core User Stories

## Authentication

**US-001**
As a user, I can sign in with my Google account so that Codexa can access my selected Drive content.

**US-002**
As a user, I can understand what access Codexa requests before granting permission.

**US-003**
As a user, I can disconnect my Google account.

---

## Library creation

**US-010**
As a user, I can browse folders in Google Drive.

**US-011**
As a user, I can select a folder and add it to Codexa as a book.

**US-012**
As a user, I can preview the discovered structure before committing to the import.

**US-013**
As a user, I can see whether a book is currently syncing.

---

## Organization

**US-020**
As a user, I can view all books in my library.

**US-021**
As a user, I can navigate Book → Part / Section → Document.

**US-022**
As a user, I can locally rename a book or section without modifying Google Drive.

**US-023**
As a user, I can remove a book from Codexa without deleting its Drive source.

---

## Reading

**US-030**
As a user, I can open a downloaded PDF inside Codexa.

**US-031**
As a user, I can read a downloaded PDF without network access.

**US-032**
As a user, I can navigate pages.

**US-033**
As a user, I can zoom the document.

**US-034**
As a user, I can enter a page number.

**US-035**
As a user, I can bookmark a page.

**US-036**
As a user, Codexa remembers where I stopped reading.

---

## Synchronization

**US-040**
As a user, I can manually synchronize a book.

**US-041**
As a user, Codexa detects new PDFs in a tracked Drive folder.

**US-042**
As a user, Codexa detects changed PDFs.

**US-043**
As a user, Codexa handles PDFs deleted or moved in Drive without silently destroying my local copy.

**US-044**
As a user, I can retry failed synchronization.

---

## Search

**US-050**
As a user, I can search books by title.

**US-051**
As a user, I can search sections and document names.

---

## Localization

- First-time users see the application in Arabic by default.
- Arabic interface uses proper RTL layout.
- English and French can be selected from Settings.
- Switching languages updates the interface without losing library state.
- Directional icons behave correctly in RTL and LTR.

## Theme

- Light Mode is available.
- Dark Mode is available.
- System Default is available.
- Theme preference persists after app restart.
- Theme preference works offline.
- Dark Mode is designed as a dedicated Codexa theme rather than a raw color inversion.

## Automatic Reading Position

- Reading position is saved automatically.
- Page changes persist without requiring a Save action.
- Leaving the reader preserves the latest reliable position.
- Closing and reopening the app restores the saved position.
- Continue Reading opens the correct document and page.
- Automatic progress saving works offline.
- Rapid page changes do not create unnecessary database-write load.

## Storage

**US-060**
As a user, I can see how much device storage Codexa uses.

**US-061**
As a user, I can remove downloaded files while retaining library metadata.

**US-062**
As a user, I can download content again later.

---

# 8. Product Principles

## P1 — Library over files

The user should think in terms of books, not Drive files.

## P2 — Reading over administration

Administrative actions must never dominate the reading experience.

## P3 — Offline is a first-class state

Offline access is not an error state.

## P4 — Never silently destroy user content

Local deletion and cloud deletion are separate concepts.

## P5 — Explicit synchronization

The user should always understand what Codexa is doing with their files.

## P6 — Local-first reading

Once content is downloaded, reading must not depend on the cloud.

## P7 — Preserve source structure

Drive is the source of truth for cloud structure unless the user explicitly creates local presentation overrides.

## P8 — Calm interaction

Motion and feedback should be restrained and intentional.

## P9 — Premium without ornament overload

The visual language should feel archival and scholarly without becoming decorative clutter.

---

# 9. Scope

## 9.1 MVP — Must Have

- Google authentication
- Google Drive access
- Drive folder browsing
- Add Drive folder as book
- Recursive PDF discovery
- Book/section hierarchy
- Local metadata database
- Local PDF storage
- Initial download
- Offline PDF reader
- Page navigation
- Zoom
- Last reading position
- Library
- Book detail
- Search by book/title
- Search by section/document name
- Manual synchronization
- New PDF detection
- Changed PDF detection
- Missing/deleted source detection
- Download status
- Storage management
- Remove book locally
- Account disconnect
- Settings
- Error states
- Empty states
- Basic bookmarks

## 9.2 MVP — Should Have

- Continue Reading
- Recently Added
- Reading progress
- Download individual documents
- Download complete book
- Pause/cancel downloads where technically reliable
- Retry failed downloads
- Local renaming of book and section labels
- Book cover selection
- Library sorting

## 9.3 Post-MVP

Potential future capabilities:

- collections independent of Drive folders
- favorites
- richer metadata
- automatic cover generation
- full-text PDF search
- annotations
- highlights
- notes
- reading statistics
- multiple Drive roots
- additional cloud providers
- cross-device local reading progress synchronization
- advanced reader themes
- smart recommendations

These features are not required for the initial release.

---

# 10. Non-Goals

The MVP is not:

- a cloud storage replacement
- a Google Drive replacement
- a document editor
- an EPUB publishing platform
- a social reading platform
- a book marketplace
- a DRM platform
- a full document management suite

Codexa does not modify the user's original Drive files unless a future feature explicitly introduces write operations.

---

# 11. Information Architecture

The core information architecture is:

```text
Codexa
│
├── Library
│   ├── Continue Reading
│   ├── Recently Added
│   └── Books
│
├── Browse
│   └── Google Drive
│       ├── Folders
│       └── PDFs
│
├── Downloads
│   ├── Downloaded
│   ├── Downloading
│   ├── Pending
│   └── Failed
│
└── Settings
    ├── Account
    ├── Appearance
    ├── Reader
    ├── Storage
    ├── Synchronization
    └── About
```

Book hierarchy:

```text
Book
│
├── Metadata
├── Reading Progress
├── Sync Status
│
├── Part / Section
│   ├── Document
│   ├── Document
│   └── Document
│
└── Part / Section
    └── Document
```

---

# 12. Primary Navigation

Mobile navigation:

1. **Library**
2. **Browse**
3. **Downloads**
4. **Settings**

The active destination must be visually clear without relying only on color.

---

# 13. Screen Requirements

## 13.1 Splash

Purpose:
- establish brand
- transition into application

Content:
- Codexa emblem
- CODEXA wordmark
- tagline

Behavior:
- first launch may use the full brand animation
- subsequent launches should use a short transition
- the animation must never delay access unnecessarily

---

## 13.2 Onboarding

The onboarding should communicate three concepts:

### Your books, together.
Turn Drive folders into organized books.

### Read anywhere.
Download books and read them offline.

### Your library, preserved.
Keep your Drive organization while enjoying a dedicated reading experience.

Onboarding must be skippable where appropriate.

---

## 13.3 Authentication

Requirements:

- Google sign-in
- clear explanation of Drive access
- loading state
- cancellation state
- authentication error state
- permission-denied state
- retry

The app must not expose unnecessary permissions.

---

## 13.4 Library

Primary hierarchy:

1. Header / brand
2. Library title
3. Continue Reading
4. Recently Added
5. Books
6. Empty state if necessary
7. Synchronization indication

Each book can display:

- cover
- title
- author if available
- part/section count
- document count
- reading progress
- sync status

---

## 13.5 Continue Reading

Show the most recently opened reading location.

Display:

- book
- current document
- current chapter/section
- page number
- progress percentage
- Continue Reading action

The action must open the correct local document and restore the last page.

---

## 13.6 Browse

The Drive browser must:

- start at a logical Drive location
- display folders
- navigate into folders
- display PDFs
- provide breadcrumbs
- support pagination where needed
- provide Add as Book

The UI should feel like Codexa, not like a clone of Google Drive.

---

## 13.7 Add Book

Recommended flow:

```text
Select Drive Folder
        ↓
Inspect Structure
        ↓
Preview Book
        ↓
Confirm "Add to Codexa"
        ↓
Create Local Metadata
        ↓
Start Synchronization
```

Preview should show:

- folder name
- detected sections
- number of PDFs
- estimated download size where available
- unsupported/empty content warnings

---

## 13.8 Book Detail

Book detail must show:

- cover
- title
- metadata
- progress
- last-read position
- Continue Reading
- synchronization state
- download management
- section structure

Each section should contain its documents in stable, predictable ordering.

Actions:

- Continue Reading
- Sync
- Download
- Manage Downloads
- Rename Locally
- Remove from Codexa

---

## 13.9 Downloads

Downloads must distinguish:

- downloaded
- downloading
- queued
- paused
- failed
- unavailable
- requires sync

For active downloads show:

- book/document
- progress
- bytes where available
- percentage
- current state
- retry/cancel action where supported

---

## 13.10 PDF Reader

The reader must prioritize the document.

Required capabilities:

- open local PDF
- next/previous page
- page number
- zoom
- bookmark
- restore last page
- contents/navigation
- reader controls
- error state if local file is missing/corrupt

Controls should remain visually quiet and may auto-hide during reading.

---

## 13.11 Search

MVP search scope:

- book title
- section/part name
- document/PDF filename

Search should work against local metadata so basic library search remains available offline.

Full PDF content search is post-MVP unless implementation feasibility is established.

---

## 13.12 Settings

### Account

- signed-in account
- connection status
- disconnect

### Appearance

- interface appearance
- typography preference where supported

### Reader

- reading mode
- page behavior
- progress visibility
- available reader preferences

### Storage

- total Codexa storage
- downloaded content size
- remove downloads
- clear local data

### Synchronization

- last sync
- sync behavior
- retry failed operations

### About

- version
- legal/privacy links
- support information

---

# 14. Functional Requirements

## 14.1 Authentication

**FR-AUTH-001**
The application shall support Google authentication.

**FR-AUTH-002**
The application shall request only permissions required for the implemented Drive functionality.

**FR-AUTH-003**
Authentication credentials/tokens shall be stored using platform-secure mechanisms.

**FR-AUTH-004**
The application shall handle authentication cancellation without crashing.

**FR-AUTH-005**
The application shall handle expired/invalid authorization and provide a recovery path.

**FR-AUTH-006**
The application shall allow the user to disconnect the Google account.

---

## 14.2 Drive Access

**FR-DRIVE-001**
The application shall browse Drive folders.

**FR-DRIVE-002**
The application shall list supported PDF files.

**FR-DRIVE-003**
Drive listing shall support pagination.

**FR-DRIVE-004**
The application shall identify the selected folder by its stable Drive ID.

**FR-DRIVE-005**
The application shall not rely on folder names as unique identifiers.

**FR-DRIVE-006**
Drive API errors shall be surfaced as understandable product states.

---

## 14.3 Book Mapping

**FR-BOOK-001**
A selected Drive folder shall become the root of a Codexa book.

**FR-BOOK-002**
The root folder name shall be used as the default book title.

**FR-BOOK-003**
Subfolders shall become sections/parts.

**FR-BOOK-004**
PDFs shall become book documents.

**FR-BOOK-005**
Nested folders shall be supported to a reasonable depth.

**FR-BOOK-006**
The application shall preserve source folder identifiers.

**FR-BOOK-007**
Users shall be able to create local presentation names without modifying Drive.

**FR-BOOK-008**
Empty folders shall not create meaningless empty sections unless explicitly preserved for structure.

---

## 14.4 PDF Discovery

**FR-PDF-001**
The application shall recursively discover PDFs under a selected book root.

**FR-PDF-002**
Non-PDF files shall not be imported as readable book documents in MVP.

**FR-PDF-003**
Unsupported files may be reported in the import preview.

**FR-PDF-004**
Each discovered PDF shall retain its Drive file ID.

**FR-PDF-005**
The application shall retain the source parent relationship needed to reconstruct the book hierarchy.

---

## 14.5 Local Storage

**FR-LOCAL-001**
Book metadata shall be stored locally.

**FR-LOCAL-002**
Section metadata shall be stored locally.

**FR-LOCAL-003**
Document metadata shall be stored locally.

**FR-LOCAL-004**
Downloaded PDFs shall be stored in application-controlled storage.

**FR-LOCAL-005**
Local storage shall not expose internal files unnecessarily to unrelated applications.

**FR-LOCAL-006**
The application shall track download state independently from cloud state.

---

# 15. Synchronization Model

Synchronization is a core subsystem, not a UI afterthought.

## 15.1 Source of truth

Google Drive is the source of truth for:

- cloud folder existence
- cloud folder names
- cloud document existence
- cloud document names
- cloud modification state
- cloud file IDs

Codexa is the source of truth for:

- local presentation names
- reading progress
- bookmarks
- local download state
- local storage state

---

## 15.2 Sync lifecycle

```text
IDLE
 ↓
CHECKING
 ↓
DISCOVERING
 ↓
COMPARING
 ↓
QUEUED
 ↓
DOWNLOADING
 ↓
VERIFYING
 ↓
UPDATED
```

Failure path:

```text
ANY STATE
   ↓
ERROR
   ↓
RETRY
```

---

## 15.3 Sync comparison

For each tracked Drive document, compare available cloud metadata against local metadata.

At minimum track:

- Drive file ID
- name
- parent ID
- MIME type
- cloud modified timestamp
- local download timestamp
- local path
- download state
- file size where available

A change should result in the document being marked for update.

---

## 15.4 New files

When a new PDF is detected:

1. Add metadata.
2. Add it to the appropriate section.
3. Mark it as not downloaded.
4. Notify the user through the library/download state.
5. Offer or initiate download according to configured sync behavior.

---

## 15.5 Changed files

When a tracked PDF has changed:

1. Detect changed cloud metadata.
2. Mark local copy as outdated.
3. Preserve the existing local copy until replacement is successfully downloaded.
4. Download replacement.
5. Verify successful completion.
6. Atomically replace the local file.
7. Update metadata.

This prevents a failed update from destroying a previously valid offline copy.

---

## 15.6 Deleted or inaccessible files

If a source PDF is no longer available:

- do not immediately delete the local copy
- mark the cloud source as missing
- clearly indicate the state
- allow the user to remove the local copy
- preserve local reading data unless the user explicitly removes the document

---

## 15.7 Interrupted downloads

Downloads should be resilient to:

- temporary network loss
- application backgrounding
- app restart
- device restart where platform capabilities permit

The system should resume or safely restart downloads without creating corrupt documents.

---

# 16. Download Strategy

The product should support:

### Book download

Download all discovered PDFs.

### Section download

Download all PDFs in a section.

### Document download

Download a single PDF.

### Remove local copy

Remove the local PDF while retaining metadata.

The UI must clearly distinguish:

**Remove from device**

from:

**Remove book from Codexa**

and both must be clearly separate from any hypothetical cloud deletion.

Codexa MVP must not delete the original Drive file.

---

# 17. Reading Progress

For every readable PDF, Codexa should store:

- current page
- total page count where available
- last opened timestamp
- reading progress percentage
- optional bookmarked pages

Progress must survive:

- app restart
- device restart
- offline usage

Progress should be available without a network connection.

---

# 17A. Automatic Reading Position & Resume

Reading position persistence is a core Codexa feature and shall be **automatic by default**.

The user should never need to manually press a Save button to preserve their reading position.

## 17A.1 Automatic save

Codexa shall automatically save the user's reading position while reading a document.

At minimum, store:

- current page
- document ID
- book ID
- reading progress percentage
- last opened timestamp

Where technically reliable, the reader may additionally preserve a more precise position within a page.

## 17A.2 Save timing

The reading position should be persisted:

- when the user changes page
- after a meaningful reading-position change
- when the reader is closed
- when the application moves to the background
- before the application terminates where platform lifecycle allows

The implementation should avoid excessive database writes by debouncing rapid updates.

## 17A.3 Resume behavior

When a user opens a document they have previously read:

- Codexa should automatically restore the last saved position.
- If no saved position exists, open from the beginning or the configured default page.
- The user should not have to manually search for their previous page.

When opening a book from **Continue Reading**, Codexa must open the correct document and restore the saved page automatically.

## 17A.4 User control

Automatic progress saving is enabled by default.

If a future setting allows it to be disabled, the application must clearly explain that disabling it prevents automatic resume.

Manual bookmarks remain separate from automatic reading-position saving.

## 17A.5 Offline behavior

Reading position must be saved locally and must work fully offline.

If future cross-device synchronization is implemented, reading progress may be synchronized separately from PDF content.


# 18. Bookmarks

MVP bookmarks should store:

- document ID
- page number
- created timestamp
- optional local label

Bookmarks are local Codexa metadata and do not modify the source PDF.

---

# 19. Search Requirements

Search shall operate against local metadata.

MVP indexed fields:

- book title
- local book title
- section title
- document filename
- local section title

Search must remain usable offline.

Search results should identify:

- book
- section
- document

Full-text PDF indexing is explicitly outside MVP.

---

# 20. Sorting and Ordering

Default ordering should respect source structure.

Where Drive does not provide a meaningful order, Codexa should use deterministic alphabetical ordering.

The user may later be allowed to configure local ordering.

Ordering must be stable between sessions.

---

# 21. Book Covers

A book may have:

1. user-provided cover
2. source-derived cover where technically available
3. generated Codexa placeholder cover

Default placeholder covers should use the Codexa editorial visual system.

Book covers are presentation metadata and do not modify Drive.

---

# 22. Local Naming

Codexa may allow local names for:

- book
- section

Local names must not overwrite the corresponding Drive names.

The UI should communicate this clearly:

**Local title**

rather than suggesting the Drive file has been renamed.

---

# 23. Storage Management

The application shall provide:

- total local Codexa storage
- storage used by books
- per-book size
- download state
- remove local downloads
- clear local library data

Before destructive local operations, provide confirmation.

The confirmation must explain what is and is not deleted.

---

# 24. Offline Behavior

## 24.1 Fully offline

The user can:

- open downloaded books
- read PDFs
- navigate pages
- use bookmarks
- view reading progress
- browse local library
- search local metadata
- manage already downloaded files

## 24.2 Offline limitations

The user cannot:

- browse new Drive content
- synchronize
- download cloud content
- authenticate against Drive if authorization is unavailable

The UI should explain this without treating offline mode as a system failure.

---

# 25. Error Handling

Every network-dependent operation must have an explicit error state.

Required categories:

- authentication failure
- permission denied
- Drive unavailable
- network unavailable
- rate limit
- file unavailable
- file changed
- download failed
- local storage full
- corrupt/incomplete PDF
- invalid local metadata
- synchronization conflict/state mismatch

Every recoverable error should provide a clear action where possible:

- Retry
- Reconnect
- Refresh
- Free storage
- View details

Errors should use calm, understandable language.

---

# 26. Empty States

Examples:

### Empty library

**Your library is empty.**

> Every library begins with a first volume.

CTA:

**Add a book**

### No search results

**Nothing found.**

> Try another title, section, or document name.

### No downloads

**Nothing is available offline yet.**

CTA:

**Browse your library**

---

# 27. Design Requirements

Codexa uses the associated **Archival Modernist / Codexa Design System**.

The design language is editorial minimalism with tactile archival influence.

Core principles:

- parchment and ink
- generous whitespace
- high-quality editorial typography
- precise hairline borders
- restrained antique gold
- subtle paper texture
- engraved visual language
- sharp geometric book covers
- quiet motion
- modern usability

The current design system specifies Bodoni Moda for major editorial headings, Literata for reading-oriented text, and Hanken Grotesk for interface metadata. fileciteturn2file5L756-L799

The design system also establishes the core color architecture around warm parchment surfaces and ink text, with Antique Gold, Oxide Red, and Forest Ink used sparingly. fileciteturn2file4L590-L606

The interface should feel like:

> A 19th-century scholarly library redesigned by a world-class modern product designer.

It must not look like a generic SaaS dashboard or a literal historical recreation. fileciteturn2file1L312-L324

---

# 28. Responsive Requirements

The product is mobile-first.

## Phone

Priorities:

- one-handed interaction
- readable typography
- comfortable touch targets
- bottom navigation
- bottom sheets for secondary actions
- distraction-free reader

## Tablet

Support:

- larger book grids
- two-column layouts
- persistent section navigation where appropriate
- wider reader margins
- additional information density

The interface must adapt without simply stretching phone layouts.

---

# 28A. Localization, Language & RTL

Codexa shall be multilingual from the beginning rather than adding localization as a later retrofit.

## 28A.1 Supported languages

The initial application shall support:

- **Arabic**
- English
- French

Additional languages may be added later through the same localization architecture.

## 28A.2 Default language

**Arabic shall be the default application language for first-time users.**

The application should use Arabic as the initial interface language unless the user explicitly selects another language.

The language must be changeable at any time from Settings.

Changing the application language must not alter:

- Drive file names
- book titles sourced from Drive
- document names
- reading progress
- bookmarks
- downloaded files

## 28A.3 Right-to-left support

Arabic must use a proper **RTL layout**, not merely translated strings.

When Arabic is active:

- interface layout follows RTL conventions
- navigation order follows RTL conventions
- text alignment follows RTL conventions
- menus and sheets open according to RTL conventions
- directional icons must be mirrored where their meaning is directional
- non-directional icons must not be unnecessarily mirrored
- book/document content must retain its native document direction
- page navigation must remain intuitive and must not incorrectly reverse PDF page order

English and French use LTR layouts.

## 28A.4 Typography

The typography system must support Arabic script with fonts that remain consistent with Codexa's editorial identity.

Arabic typography must prioritize:

- readability
- proper Arabic shaping
- adequate line height
- clear distinction between headings and metadata
- comfortable reading at mobile sizes

Arabic UI text must not be rendered using a font that produces broken shaping or poor legibility merely to imitate the Latin wordmark.

## 28A.5 Localization architecture

All interface strings must be externalized from application code.

Do not hard-code user-facing interface text inside widgets or business logic.

The localization system must support:

- translated strings
- pluralization
- interpolation
- RTL/LTR switching
- future language additions
- fallback strings
- locale-aware formatting


# 28B. Appearance & Theme Modes

Codexa shall support both **Light Mode** and **Dark Mode**.

## 28B.1 Light Mode

Light Mode is the primary Codexa visual expression.

It uses the archival/editorial language:

- warm parchment surfaces
- ink typography
- restrained antique-gold accents
- subtle borders
- tactile paper-inspired surfaces

## 28B.2 Dark Mode

Dark Mode must be a genuine Codexa theme, not a simple inversion of the light theme.

It should use:

- deep ink / charcoal surfaces
- warm off-white typography
- restrained antique-gold accents
- carefully adjusted borders and dividers
- reduced visual glare for reading

Pure `#000000` should not be used as the default application background unless required for a specific immersive reader state.

## 28B.3 Theme selection

The user shall be able to choose:

- **Light**
- **Dark**
- **System Default**

**System Default** follows the device operating-system appearance setting.

The selected preference must persist locally and remain available offline.

## 28B.4 Reader appearance

The reader may provide an independent reading-surface preference in the future.

The application theme and PDF reading surface must not be treated as the same setting unless the implementation intentionally links them.


# 29. Accessibility Requirements

Codexa shall:

- maintain strong text contrast
- use readable text sizes
- provide accessible labels for icons
- avoid communicating state through color alone
- maintain usable touch targets
- support system text scaling where technically practical
- ensure important states are visible in both text and visual form
- avoid decorative textures that reduce legibility

The archival aesthetic must never reduce usability.

---

# 30. Security & Privacy

## 30.1 Authentication security

OAuth credentials/tokens must use secure platform storage.

No tokens may be written to:

- logs
- analytics events
- crash reports
- plain-text local files

## 30.2 Drive permissions

Request the minimum scope required by the implemented functionality.

The product must avoid unnecessary access to the user's Drive.

The exact Google OAuth scope must be finalized during implementation based on the required folder-browsing behavior and Google's current authorization requirements.

## 30.3 Local files

Downloaded PDFs are user-controlled content.

The application should:

- keep them inside controlled application storage
- avoid exposing unnecessary internal metadata
- remove them securely according to platform capabilities when the user deletes local content

## 30.4 Privacy

Codexa should minimize collection of user data.

Do not collect or transmit the contents of user PDFs for analytics.

Do not upload user documents to a Codexa backend in MVP.

---

# 31. Data Model

A local relational database is recommended for predictable relationships and synchronization state.

Core entities:

## UserSession

- id
- provider
- account identifier
- authenticated state
- createdAt
- lastAuthenticatedAt

## Book

- id
- driveFolderId
- sourceName
- localTitle
- coverPath
- addedAt
- lastSyncedAt
- syncStatus
- totalDocuments
- downloadedDocuments
- totalBytes
- downloadedBytes

## BookSection

- id
- bookId
- driveFolderId
- parentSectionId
- sourceName
- localTitle
- order

## BookDocument

- id
- bookId
- sectionId
- driveFileId
- sourceName
- localPath
- MIME type
- cloudModifiedAt
- localDownloadedAt
- fileSize
- checksum where practical
- downloadStatus
- availabilityStatus

## ReadingProgress

- id
- documentId
- currentPage
- totalPages
- progressPercent
- lastOpenedAt

## Bookmark

- id
- documentId
- page
- label
- createdAt

## SyncOperation

- id
- bookId
- documentId nullable
- operationType
- status
- progress
- startedAt
- completedAt
- errorCode
- retryCount

---

# 32. Recommended Architecture

Use a layered architecture.

```text
Presentation
    ↓
Application / Use Cases
    ↓
Domain
    ↓
Repositories
    ↓
Data Sources
 ┌───────────────┬────────────────┐
 │ Google Drive  │ Local Database │
 │ API           │ + File System  │
 └───────────────┴────────────────┘
```

## Presentation

Flutter screens, widgets, navigation, state.

## Application

Use cases such as:

- SignIn
- BrowseDrive
- AddBook
- DiscoverBookStructure
- SyncBook
- DownloadDocument
- RemoveLocalDownload
- SearchLibrary
- OpenDocument
- SaveReadingProgress
- AddBookmark

## Domain

Core models and business rules.

## Data

Implementations of:

- Drive repository
- local repository
- download manager
- PDF/document repository

---

# 33. State Management

Use **Riverpod** unless implementation constraints require an alternative.

State should be separated by concern:

- authentication state
- library state
- Drive browsing state
- book detail state
- sync state
- download queue state
- reader state
- settings state

Avoid putting the entire application into one global state object.

---

# 34. Local Database Recommendation

Use SQLite-compatible relational persistence for the primary metadata model.

Reason:

- Book → Section → Document relationships
- synchronization queries
- sorting
- search indexes
- progress tracking
- transactional updates
- predictable migrations

The PDF binary files should remain in the file system rather than inside the database.

---

# 35. File Storage Layout

Recommended conceptual layout:

```text
Codexa/
├── books/
│   ├── {bookId}/
│   │   ├── documents/
│   │   │   ├── {documentId}.pdf
│   │   │   └── ...
│   │   └── cover/
│   │       └── cover.*
│   └── ...
└── database/
```

The exact filesystem implementation is platform-specific.

---

# 36. Download Manager

The download manager must provide a controlled queue rather than starting unlimited simultaneous downloads.

It should support:

- queued
- active
- completed
- failed
- canceled
- retrying

Concurrency should be tuned for device/network performance.

The manager must avoid:

- corrupt partial files being treated as complete
- duplicate downloads
- uncontrolled parallel downloads
- silent failures

---

# 37. Performance Requirements

## PRF-001

Library metadata should render from local storage without requiring network access.

## PRF-002

Opening a previously downloaded PDF must not require Drive access.

## PRF-003

Drive listings must use pagination.

## PRF-004

Large libraries must not require loading every document into memory.

## PRF-005

PDF files must be streamed/downloaded rather than loaded entirely into memory.

## PRF-006

The application should remain responsive while synchronization is active.

## PRF-007

UI rendering must not be blocked by filesystem or network operations.

---

# 38. Scalability Target

Initial target:

- dozens of books
- hundreds of PDFs
- large individual PDFs
- multiple nested sections

The architecture should avoid assumptions that only one book or a few documents exist.

---

# 39. Reliability Requirements

The application must survive:

- app restart during download
- temporary network loss
- offline launch
- partial synchronization
- Drive API errors
- expired authorization
- low storage
- missing local file
- deleted cloud source

A failed synchronization must never leave the local library in an unknowable state.

---

# 40. Analytics

MVP analytics should be minimal and privacy-conscious.

Potential product events:

- onboarding_completed
- google_sign_in_success
- book_added
- sync_started
- sync_completed
- sync_failed
- document_opened
- reading_session_started
- bookmark_created
- book_removed

Do not log:

- PDF contents
- document text
- Drive file contents
- OAuth tokens
- sensitive user data

Analytics should be optional and compliant with the product privacy policy.

---

# 41. Acceptance Criteria

## Authentication

- User can authenticate successfully.
- Permission denial is handled.
- Tokens are not exposed in logs.
- User can disconnect.

## Drive

- User can browse folders.
- User can navigate nested folders.
- User can identify supported PDFs.
- Pagination works.

## Book creation

- Selected folder becomes a book.
- Nested folders become sections.
- PDFs are discovered recursively.
- Empty/unsupported content is handled.

## Download

- PDF downloads to local storage.
- Progress is visible.
- Failed downloads can be retried.
- Completed PDFs open offline.
- Interrupted downloads do not become falsely marked as complete.

## Library

- All added books appear.
- Books can be opened offline.
- Continue Reading works.
- Reading progress is retained.

## Reader

- PDF opens locally.
- Page navigation works.
- Zoom works.
- Last page is restored.
- Bookmarks work if included in MVP.

## Sync

- New PDFs are detected.
- Changed PDFs are detected.
- Missing source files are clearly marked.
- Existing valid local content is protected during failed replacement downloads.
- Sync status is understandable.

## Search

- Book titles are searchable.
- Section names are searchable.
- Document names are searchable.
- Search works offline against local metadata.

## Storage

- Storage usage is visible.
- Local files can be removed.
- Metadata can remain when appropriate.
- Removing local data does not delete Drive source content.

---

# 42. MVP Release Definition

MVP is release-ready only when:

- all Must Have requirements are implemented
- critical flows have no known blocking defects
- offline reading has been tested without network access
- synchronization has been tested with new/changed/deleted files
- large PDFs have been tested
- interrupted downloads have been tested
- low-storage behavior has been tested
- authentication recovery has been tested
- local data remains consistent after app restart
- UI follows the Codexa Design System
- accessibility baseline is verified
- privacy/security review is completed for the implemented data flows

---

# 43. QA Strategy

Testing layers:

## Unit tests

Test:

- folder-to-book mapping
- hierarchy construction
- sync comparison
- state transitions
- progress calculations
- search indexing
- storage calculations

## Integration tests

Test:

- Google authentication
- Drive listing
- Drive download
- local persistence
- synchronization
- download queue
- PDF opening

## End-to-end tests

Test:

1. Sign in
2. Browse Drive
3. Add book
4. Download
5. Open PDF
6. Read
7. Close
8. Relaunch offline
9. Continue reading
10. Reconnect
11. Synchronize

## Failure testing

Explicitly test:

- network loss
- Drive permission loss
- app termination during download
- storage full
- corrupted file
- deleted Drive source
- changed Drive source
- duplicate import attempt

---

# 44. Delivery Phases

## Phase 0 — Foundation

- Flutter project
- architecture
- navigation
- design tokens
- local database
- secure storage
- logging/error infrastructure

## Phase 1 — Authentication

- Google sign-in
- Drive permission flow
- account state
- logout/disconnect

## Phase 2 — Drive Browser

- folder browsing
- breadcrumbs
- pagination
- PDF discovery
- Add Book

## Phase 3 — Library

- book creation
- local metadata
- library screen
- book detail
- structure mapping

## Phase 4 — Download System

- download queue
- progress
- local file storage
- retry
- interruption recovery

## Phase 5 — Reader

- local PDF reader
- page navigation
- zoom
- progress
- bookmarks
- continue reading

## Phase 6 — Synchronization

- metadata comparison
- new files
- changed files
- missing files
- safe replacement
- retry

## Phase 7 — Search & Storage

- local search
- storage management
- download management

## Phase 8 — Hardening

- performance
- accessibility
- security
- failure testing
- offline testing
- visual refinement

---

# 45. Product Quality Gates

A feature cannot be considered complete merely because its happy path works.

Every feature must have:

1. happy state
2. loading state
3. empty state
4. offline state where relevant
5. error state
6. retry/recovery state
7. destructive confirmation where relevant
8. accessibility behavior

---

# 45A. Localization & Reading UX Rules

## Rule A1

Arabic is the default interface language for first-time users.

## Rule A2

RTL must be implemented at the layout/system level, not simulated by manually changing individual labels.

## Rule A3

The user's Drive content must not be translated or renamed automatically merely because the interface language changes.

## Rule A4

Reading progress is automatic. A reader should never have to think about saving their place.

## Rule A5

Continue Reading must restore the exact last reliable reading position whenever possible.

## Rule A6

Light and Dark themes must both preserve Codexa's archival identity.


# 46. Critical UX Rules

## Rule 1

Never make the user wonder whether a file is local or cloud-only.

## Rule 2

Never imply that removing a local copy deletes the Drive source.

## Rule 3

Never hide a failed synchronization.

## Rule 4

Never require network access to open a fully downloaded PDF.

## Rule 5

Never make the reader compete visually with navigation.

## Rule 6

Never make Codexa feel like a generic Drive client.

## Rule 7

Never use decorative visual effects that reduce readability.

---

# 47. Future Product Direction

Codexa can eventually evolve from a Drive reading companion into a broader personal knowledge library.

Possible future model:

```text
Library
│
├── Books
├── Collections
├── Favorites
├── Recent
├── Bookmarks
└── Notes
```

Potential future integrations:

- Google Drive
- other cloud providers
- local import
- EPUB
- advanced PDF annotations

However, the central promise should remain:

> **A library of your own.**

---

# 48. Open Decisions Before Implementation

These should be explicitly resolved during technical kickoff rather than silently assumed:

1. Exact Google Drive OAuth scope required by the final folder-browsing behavior.
2. Minimum Android/iOS versions supported by the final Flutter/package stack.
3. PDF rendering package.
4. Background download implementation per platform.
5. Exact automatic-vs-manual download behavior after adding a book.
6. Whether full bookmarks are included in the first public MVP.
7. Whether book covers can be selected from Drive in MVP.
8. Final analytics provider, if any.
9. Final crash reporting provider, if any.

These are implementation decisions, not reasons to delay the product definition.

---

# 49. Recommended Technical Baseline

Unless implementation testing identifies a blocker:

- Flutter / Dart
- Riverpod
- SQLite-compatible local database
- platform secure storage
- Google Sign-In
- Google Drive API v3
- controlled download queue
- local application filesystem
- offline-capable PDF renderer

Package versions should be selected and locked during implementation based on the current compatible ecosystem rather than permanently hard-coded in this PRD.

---

# 50. Definition of Done

A Codexa feature is Done when:

- product behavior matches this PRD
- UI matches the Codexa Design System
- loading/empty/error/offline states exist
- data is persisted correctly
- failure paths are handled
- tests cover the critical behavior
- no sensitive data is logged
- the feature works after app restart
- offline behavior is correct where applicable
- accessibility baseline is met
- performance is acceptable on target devices
- documentation is updated where architecture or behavior changed

---

# 51. Final Product Definition

Codexa is not primarily a PDF viewer.

Codexa is not primarily a Google Drive browser.

Codexa is not primarily a download manager.

Codexa is a **personal digital library**.

Google Drive provides the source.

Codexa provides the library.

The user should open the application and feel:

> **My books are here.**

Then:

> **I know exactly where I left off.**

Then:

> **I can read, even without internet.**

And when the user returns:

> **Codexa remembered my place.**

The interface should welcome the user in Arabic by default, while allowing English and French, with proper RTL/LTR behavior and a complete Light/Dark/System appearance system.

And the visual experience should communicate:

> **This is a place for knowledge, not a place for files.**

---

# 52. Brand Reference

**Product:** Codexa  
**Tagline:** A library of your own  
**Design language:** Archival Modernist / Editorial Minimalism  
**Core metaphor:** Personal scholarly library  
**Visual metaphor:** Codex / archive / moonlit reading  
**Primary surfaces:** Parchment / Warm White  
**Primary text:** Ink  
**Primary accent:** Antique Gold  
**Secondary emphasis:** Oxide Red / Forest Ink  
**Typography:** Bodoni Moda + Literata + Hanken Grotesk  
**Logo direction:** C-shaped crescent / codex emblem, without stars  
**Motion principle:** Calm, editorial, page-like  
**Default interface language:** Arabic  
**Supported languages:** Arabic, English, French  
**Layout directions:** RTL for Arabic, LTR for English/French  
**Appearance modes:** Light, Dark, System Default  
**Reading progress:** Automatic save and automatic resume  
**Experience principle:** Ancient knowledge. Modern interface.

---

# 53. Document Authority

This PRD defines **what Codexa must do**.

The Codexa Design System defines **how Codexa must look and behave visually**.

Technical architecture documentation will define **how Codexa is implemented**.

When these documents are used together:

```text
PRD
 ↓
What the product does

Design System
 ↓
How the product looks and interacts

Technical Specification
 ↓
How the product is built

QA Specification
 ↓
How the product is verified
```

All implementation decisions should preserve the product's central promise:

# Codexa
## A library of your own
