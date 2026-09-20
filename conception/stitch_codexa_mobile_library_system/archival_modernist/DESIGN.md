---
name: Archival Modernist
colors:
  surface: '#fdf9f1'
  surface-dim: '#dddad2'
  surface-bright: '#fdf9f1'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3eb'
  surface-container: '#f1ede6'
  surface-container-high: '#ece8e0'
  surface-container-highest: '#e6e2da'
  on-surface: '#1c1c17'
  on-surface-variant: '#4b463f'
  inverse-surface: '#31302b'
  inverse-on-surface: '#f4f0e8'
  outline: '#7c766e'
  outline-variant: '#cdc5bc'
  surface-tint: '#615e5a'
  primary: '#000000'
  on-primary: '#ffffff'
  primary-container: '#1d1b18'
  on-primary-container: '#87837f'
  inverse-primary: '#cbc5c0'
  secondary: '#665d4e'
  on-secondary: '#ffffff'
  secondary-container: '#eadeca'
  on-secondary-container: '#6a6252'
  tertiary: '#000000'
  on-tertiary: '#ffffff'
  tertiary-container: '#281900'
  on-tertiary-container: '#a27e3f'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e8e1dc'
  primary-fixed-dim: '#cbc5c0'
  on-primary-fixed: '#1d1b18'
  on-primary-fixed-variant: '#494642'
  secondary-fixed: '#ede1cd'
  secondary-fixed-dim: '#d0c5b2'
  on-secondary-fixed: '#201b0f'
  on-secondary-fixed-variant: '#4d4637'
  tertiary-fixed: '#ffdeac'
  tertiary-fixed-dim: '#ebc07a'
  on-tertiary-fixed: '#281900'
  on-tertiary-fixed-variant: '#5e4105'
  background: '#fdf9f1'
  on-background: '#1c1c17'
  surface-variant: '#e6e2da'
typography:
  display-lg:
    fontFamily: Bodoni Moda
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Bodoni Moda
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
  headline-lg-mobile:
    fontFamily: Bodoni Moda
    fontSize: 28px
    fontWeight: '600'
    lineHeight: '1.2'
  title-md:
    fontFamily: Bodoni Moda
    fontSize: 22px
    fontWeight: '500'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Literata
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Literata
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 11px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.08em
spacing:
  margin-page: 2rem
  margin-mobile: 1.25rem
  gutter: 1.5rem
  unit: 4px
  stack-sm: 8px
  stack-md: 24px
  stack-lg: 48px
---

## Brand & Style

This design system establishes a visual language where 19th-century scholarly elegance meets 21st-century functional minimalism. The personality is quiet and authoritative, designed to provide a "digital sanctuary" for deep reading and focused thought.

The design style is **Editorial Minimalism** with **Tactile / Skeuomorphic** influences. It avoids the clinical coldness of modern SaaS interfaces in favor of high-contrast typography, generous margins, and subtle textures that evoke the physical sensation of handling a rare manuscript. Surfaces feel like weighted paper, and interactions mimic the deliberate, calm pace of a physical archive.

Key characteristics:
- **Atmospheric Depth:** Use of organic off-whites and deep charcoal "inks" instead of pure black/white.
- **Structural Elegance:** Reliance on hairline borders (engravings) and precise grid alignment rather than shadows.
- **Quiet Authority:** Premium aesthetic achieved through "The White Space of Luxury"—letting content breathe within expansive parchment containers.

## Colors

The palette is rooted in historical printing materials. **Ink (#191714)** serves as the primary vehicle for all long-form text and structural outlines. **Parchment** and **Warm White** form the base of the UI, creating a soft, low-strain reading environment.

- **Primary (Ink):** Used for body text, headings, and primary iconography.
- **Secondary (Aged Paper):** Used for surface-level differentiation, such as sidebars or inactive states.
- **Antique Gold:** Reserved strictly for "Ex Libris" moments—special collections, premium badges, or subtle active indicators.
- **Oxide Red & Forest Ink:** Used for secondary metadata categories (e.g., "History" vs. "Science") or quiet semantic alerts.

## Typography

The typography strategy employs a strict "Editorial Contrast" model.

- **Headlines & Titles:** Use **Bodoni Moda**. Its high stroke contrast evokes the look of hot-metal typesetting and premium mastheads. 
- **Reading Text:** Use **Literata**. This is the workhorse for the library experience, optimized for long-form comfort on digital screens while maintaining a bookish soul.
- **UI & Metadata:** Use **Hanken Grotesk**. This clean, contemporary sans-serif handles technical tasks (navigation, settings, timestamps) without competing with the serif narrative. Labels should often use uppercase with increased tracking to mimic 19th-century cataloging.

## Layout & Spacing

The layout follows a **Fixed-Column Editorial Grid**. On desktop, content is centered within a 12-column structure with wide "gutters of silence" on either side. On mobile, the grid shifts to 4 columns.

The spacing rhythm is based on a 4px baseline, but emphasizes large vertical jumps to separate sections. Use wide margins (32px+) for reading views to simulate the "white space" found in luxury hardback books. Elements should be aligned to a clear vertical axis to maintain a structured, archival appearance.

## Elevation & Depth

This design system rejects drop shadows in favor of **Tonal Layering** and **Engraved Outlines**.

- **Level 0 (Foundation):** The base layer is **Warm White (#FFFDF8)**.
- **Level 1 (Containers):** Elements like cards or menus use **Parchment (#FBF7EF)** with a 0.5px solid border in **Aged Paper (#E9DDC9)**.
- **Level 2 (Active/Floating):** Use a 1px border in **Ink (#191714)** to bring an element to the foreground.
- **Engraving:** To simulate depth, use a "double border" technique: a 1px dark line followed by a 1px lighter highlight line immediately below it. This creates a subtle "carved into paper" effect rather than an "elevated above paper" effect.

## Shapes

The shape language is **Strictly Geometric and Sharp**. 

To honor the heritage of traditional bookbinding and newsprint, all corners are set to **0px radius**. This reinforces the "archival" and "serious" nature of the library. 

- **Book Covers:** Must remain perfectly rectangular to mimic physical book blocks.
- **Buttons:** Sharp corners. Use 1px borders rather than solid fills where possible.
- **Ornamentation:** Use small 45-degree diamond shapes or "asterism" marks (⁂) for section breaks instead of rounded dots.

## Components

### Book Cards
Designed as miniature editorial covers. They feature no rounded corners and use a 1px internal border. Metadata is placed in **Label-SM (Hanken Grotesk)** at the bottom of the card, often separated by a thin horizontal rule.

### Buttons
Primary buttons use an **Ink (#191714)** fill with **Warm White** text. Secondary buttons use a 1px **Ink** outline with no fill. All buttons are sharp-cornered. Interaction is indicated by a subtle shift to **Aged Paper** background or the appearance of an Antique Gold accent line.

### Lists & Navigation
List items are separated by a 0.5px "Hairline" rule. The font is **Body-MD**, while metadata (page count, date added) is set in **Label-SM**.

### Input Fields
Inputs are underlined rather than boxed, mimicking a ledger or a signature line. The active state is indicated by the line thickness increasing from 1px to 2px and changing to **Antique Gold**.

### Ornamental Marks
The "Ex Libris" mark—a small, engraved icon inside a thin square frame—should be used to signify the user's personal collection or favorites. Icons should be thin-line (1px) and avoid any rounded terminals.

### Motion
Transitions are "fades and glides." Avoid bouncy or elastic easing. Use **Cubic-Bezier(0.4, 0, 0.2, 1)** for a sophisticated, cinematic feel that suggests the slow turning of a high-quality paper page.