# Codexa Design System
## A library of your own

**Version:** 1.0  
**Product:** Codexa  
**Platform:** Mobile-first Flutter application (iOS + Android)  
**Design language:** Editorial warmth + digital precision

---

# 1. Brand Foundation

## 1.1 Brand statement

**Codexa — A library of your own**

Codexa transforms books stored in Google Drive into a beautiful, organized, offline-first personal library.

The experience should feel like opening a carefully curated scholarly library, while behaving like a fast, modern mobile application.

## 1.2 Design philosophy

> **Ancient knowledge. Modern interface.**

The visual language combines:
- old scholarly books
- archival libraries
- editorial typography
- engraved illustrations
- parchment and ink
- restrained antique details
- modern mobile interaction
- generous whitespace

The interface must never become a museum replica. It should borrow the **atmosphere** of old books while retaining the usability, clarity and responsiveness of a contemporary application.

## 1.3 Personality

Codexa is:
- Scholarly
- Timeless
- Warm
- Intelligent
- Quiet
- Precise
- Curious
- Premium
- Personal

Codexa is not:
- childish
- ornamental for the sake of ornament
- dark cyberpunk
- futuristic neon
- generic SaaS
- heavily skeuomorphic
- visually noisy

---

# 2. Logo & Identity

## 2.1 Primary logo concept

The Codexa emblem is an **architectural arch enclosing an open codex**.

Symbolic layers:
- outer arch = library / archive
- open pages = books / knowledge
- central descending mark = bookmark / reading journey
- negative space subtly suggests the letter **C**

The logo should resemble an elegant **engraved library seal** rather than a generic book icon.

## 2.2 Logo variants

Create:
1. Primary horizontal logo — emblem + CODEXA wordmark
2. Stacked logo — emblem above CODEXA
3. Symbol-only mark — emblem
4. Monogram — simplified C/codex mark
5. One-color stamp version
6. Reversed version for dark backgrounds
7. App icon
8. Favicon

## 2.3 Clear space

Maintain clear space around the logo equal to at least the height of the central bookmark element.

Never:
- stretch the logo
- rotate it
- add arbitrary shadows
- use gradients inside the emblem
- place it on a visually noisy background
- alter the wordmark proportions

---

# 3. Color System

The core visual relationship is **paper + ink**.

## 3.1 Foundation colors

| Token | Hex | Usage |
|---|---|---|
| Ink 950 | #191714 | Primary text, strongest contrast |
| Ink 900 | #24201B | Headers, dark surfaces |
| Ink 800 | #342F28 | Secondary headings |
| Ink 700 | #514A40 | Secondary text |
| Ink 500 | #766D60 | Muted text |
| Parchment 50 | #FBF7EF | Main app background |
| Parchment 100 | #F4EBDD | Primary surfaces |
| Parchment 200 | #E9DDC9 | Secondary surfaces |
| Parchment 300 | #DCCDB5 | Dividers and subtle borders |
| Warm White | #FFFDF8 | Reading surface |

## 3.2 Accent colors

| Token | Hex | Usage |
|---|---|---|
| Antique Gold | #B08A4A | Active states, premium accents, progress |
| Oxide Red | #8C3F32 | Important actions, alerts, selected emphasis |
| Forest Ink | #34483C | Success, synced state, secondary accent |

Accents must be restrained. Never allow accent colors to dominate the interface.

## 3.3 Semantic colors

- Success: Forest Ink
- Warning: Antique Gold
- Error: Oxide Red
- Info: Ink 700
- Disabled: Ink 500 at reduced opacity

---

# 4. Typography

## 4.1 Typeface pairing

### Display / Editorial
Preferred:
- Cormorant Garamond
- EB Garamond
- Crimson Pro

### Interface / Utility
Preferred:
- Inter
- Manrope
- IBM Plex Sans

Use one serif family consistently and one sans-serif family consistently.

## 4.2 Type hierarchy

| Style | Suggested size | Weight | Typeface |
|---|---:|---|---|
| Display | 34–40 | Medium/Semibold | Serif |
| H1 | 28–32 | Semibold | Serif |
| H2 | 22–26 | Semibold | Serif |
| H3 | 18–20 | Semibold | Serif |
| Body Large | 17 | Regular | Sans |
| Body | 15–16 | Regular | Sans |
| Caption | 12–13 | Medium | Sans |
| Label | 11–12 | Semibold | Sans |
| Book metadata | 12–14 | Regular | Sans |

Titles should feel editorial; controls should remain extremely readable.

---

# 5. Spacing

Use an 8-point base system.

Core spacing:
- 4 — micro
- 8 — tight
- 12 — compact
- 16 — standard
- 24 — comfortable
- 32 — section
- 40 — large
- 48 — major
- 64 — editorial

Prefer generous vertical spacing over dense information blocks.

---

# 6. Shape Language

Codexa should not use excessive rounded cards.

## Radius

- 4px — tiny controls
- 8px — compact surfaces
- 12px — standard cards
- 16px — prominent containers
- 24px — special sheets / large interactive surfaces

Buttons should generally be 10–14px radius rather than pill-shaped.

Pills are reserved for:
- status
- filters
- tags
- compact metadata

---

# 7. Borders & Shadows

## Borders

Use subtle warm borders:
- 1px solid Parchment 300
- stronger borders only for selected/focused elements

Avoid harsh pure-black borders.

## Shadows

Codexa uses soft, low-elevation shadows.

Cards should feel like slightly raised paper, not floating glass.

Avoid:
- huge blur
- neon glow
- excessive elevation
- glassmorphism

---

# 8. Texture

Texture is an accent, not a background gimmick.

Use extremely subtle:
- paper grain
- fibers
- faint ink variation
- engraved line motifs

Texture opacity should remain low enough that text and controls stay perfectly clear.

Do not place heavy paper textures behind every screen.

---

# 9. Iconography

Icons should feel like **modern line icons influenced by engraved illustrations**.

Rules:
- 1.75–2px stroke
- rounded or carefully finished line endings
- restrained detail
- consistent geometry
- no filled cartoon icons unless necessary

Core icons:
- Library
- Book
- Bookmark
- Search
- Download
- Sync
- Cloud
- Offline
- Settings
- Chevron
- Back
- More
- Contents
- Brightness
- Zoom
- Favorite
- Storage

---

# 10. Navigation

Primary navigation should be extremely simple.

Recommended mobile structure:

**Library**
**Collections**
**Downloads**
**Settings**

The current section should be communicated through:
- ink emphasis
- small antique-gold marker
- subtle underline
- icon state

Avoid large modern floating navigation bars that visually overpower the books.

---

# 11. Library Screen

The Library is the emotional center of Codexa.

Hierarchy:

1. Brand/header
2. Greeting or library title
3. Continue Reading
4. Recently Added
5. All Books / collections
6. Sync status

## Book cards

Book cards should resemble refined book covers.

Each card may contain:
- cover
- title
- author if available
- chapter/section count
- reading progress
- sync status

The cover should feel editorial and restrained rather than photorealistic.

---

# 12. Book Detail

Structure:

**Book title**
metadata
reading progress

Then:

### PART I
Section title

01 — Chapter / PDF
02 — Chapter / PDF
03 — Chapter / PDF

Use numbered chapter treatments and subtle dividers inspired by printed books.

Actions:
- Continue reading
- Sync
- Download
- Manage downloads
- Rename locally
- Remove

---

# 13. Drive Browser

The Drive browser should visually belong to Codexa, not look like a Google Drive clone.

Use:
- folders
- breadcrumbs
- clean list rows
- folder icons
- selection controls
- "Add as Book" action

Make the action of converting a folder into a book feel intentional:

**Add to Codexa**

rather than simply "Import".

---

# 14. Sync & Download States

Use elegant status language.

### Synced
`Library preserved`

### Syncing
`Updating your library`

### Downloading
`Preserving 17 of 42 documents`

### Offline
`Available offline`

### Error
`Needs attention`

Show:
- progress
- document count
- storage size
- retry action

Never hide synchronization behind a tiny spinner.

---

# 15. Reader

The reader is intentionally quiet.

Normal state:
- document fills most of the screen
- minimal chrome
- warm reading background when appropriate

Tap to reveal controls.

Top:
- Back
- chapter/document title
- page indicator

Bottom:
- Contents
- Bookmark
- Zoom
- Reader settings

Controls should fade away after inactivity.

The reading experience must prioritize:
1. readability
2. page navigation
3. content
4. distraction-free space

---

# 16. Reader Modes

Support a clean architecture for future modes:

- Continuous
- Single page
- Fit width
- Fit page

Potential future customization:
- brightness
- page background
- text rendering preferences where technically possible

---

# 17. Empty States

Empty states should feel like a quiet library.

Examples:

**Your library is empty**

"Every library begins with a first volume."

CTA:
**Add a book**

Avoid generic illustrations, emojis, or SaaS-style empty-state graphics.

---

# 18. Loading States

Use elegant editorial motion.

Instead of generic skeletons everywhere:
- subtle page-line placeholders
- gentle fade
- restrained shimmer
- book-cover placeholders

Loading should feel calm.

---

# 19. Motion

Motion should be slow enough to feel intentional but never slow the interface.

Principles:
- 150ms — micro interaction
- 200–250ms — normal transition
- 300–400ms — meaningful screen transition
- 500–800ms — ceremonial/brand animation only

Use:
- page-like reveals
- subtle opacity
- small vertical movement
- soft scale
- bookmark movement
- book-cover transitions

Avoid:
- bouncing UI
- excessive spring physics
- flashy particles
- aggressive parallax

---

# 20. Design Tokens

Suggested semantic tokens:

```text
color.background.primary = Parchment 50
color.background.surface = Parchment 100
color.background.elevated = Warm White

color.text.primary = Ink 950
color.text.secondary = Ink 700
color.text.muted = Ink 500

color.border.default = Parchment 300

color.accent.primary = Antique Gold
color.accent.critical = Oxide Red
color.status.success = Forest Ink

radius.sm = 8
radius.md = 12
radius.lg = 16

space.xs = 4
space.sm = 8
space.md = 16
space.lg = 24
space.xl = 32
space.2xl = 48
space.3xl = 64
```

---

# 21. Accessibility

The antique visual language must never compromise usability.

Requirements:
- strong text contrast
- minimum comfortable touch targets
- readable type sizes
- visible focus/selected states
- support dynamic text sizing where practical
- do not communicate state through color alone
- preserve accessibility labels for icons

---

# 22. Responsive Behavior

The app is mobile-first.

On phones:
- prioritize one-handed navigation
- use bottom sheets for secondary actions
- keep primary actions within thumb reach

On tablets:
- use two-column library layouts
- allow persistent book navigation
- use wider reader margins
- use side panels where appropriate

---

# 23. Visual Quality Bar

Every screen should answer:

**Does this feel like a beautiful personal library rather than a file manager?**

If not, simplify and refine.

The final interface should feel like:

> A 19th-century scholarly library redesigned by a world-class modern product designer.

Not a literal historical recreation.

---

# 24. Brand Summary

**Product:** Codexa  
**Tagline:** A library of your own  
**Core metaphor:** Personal digital library  
**Visual metaphor:** Ancient codex / scholarly archive  
**Design principle:** Ancient knowledge. Modern interface.  
**Primary surface:** Parchment  
**Primary text:** Ink  
**Accent:** Antique Gold  
**Emphasis:** Oxide Red  
**Typography:** Editorial serif + modern sans  
**Logo:** Architectural arch + open codex + bookmark + hidden C
