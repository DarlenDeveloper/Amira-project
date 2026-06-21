---
inclusion: always
---

# Amira Luxury — Branding Guide

Brand standards for all Amira apps (Flutter `amira_luxury`, React `amira_admin`,
React `amira_explore_web`). Apply these colors and fonts to any UI work unless a
task explicitly says otherwise.

## Colors

| Role | Hex | Notes |
| --- | --- | --- |
| Gold (primary accent) | `#C4A464` | Primary brand color — buttons, highlights, active states, brand marks |
| Champagne (light gold) | `#EFD8AF` | Secondary / soft accent — subtle fills, hover states, dividers |
| Ink (near-black) | `#110C04` | Primary text and dark surfaces |
| Off-white (background) | `#FFFCF8` | Default page background and light surfaces |

### Usage notes
- The palette is warm and minimal. Lead with off-white backgrounds, ink text,
  and gold as the accent. Champagne is a supporting tone, not a primary surface.
- Keep gold for emphasis (CTAs, active nav, key figures) rather than large fills.
- Maintain sufficient contrast: ink on off-white for body text; avoid gold text
  on champagne (insufficient contrast).

## Typography

| Role | Font | Notes |
| --- | --- | --- |
| Titles / headings | **Faddish** | Display serif. Use for page titles, hero text, section headings |
| Body / UI text | **Plus Jakarta Sans** | All paragraph, label, and control text |

### Usage notes
- Titles in Faddish, everything else in Plus Jakarta Sans.
- Plus Jakarta Sans is available on Google Fonts. Faddish is a custom/licensed
  display face — bundle the font files with each app (see `public/fonts` in the
  web apps, `pubspec.yaml` fonts section in Flutter).
- Provide a graceful fallback stack: Faddish → serif; Plus Jakarta Sans → system
  sans-serif.

## Quick reference (design tokens)

```css
--color-gold:      #C4A464;
--color-champagne: #EFD8AF;
--color-ink:       #110C04;
--color-bg:        #FFFCF8;

--font-title: 'Faddish', serif;
--font-body:  'Plus Jakarta Sans', system-ui, sans-serif;
```
