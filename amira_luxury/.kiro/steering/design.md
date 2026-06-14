# Amira Luxury — Design System & UI Rules

These rules apply to every screen, widget, and change in this app. The luxury
feel is non-negotiable. When in doubt, choose restraint, warmth, and intention.

## Design Ethics (the spirit)

- **Luxury is an experience, not decoration.** Every component, spacing value,
  and animation matters. Polish over speed.
- **Brand feel:** refined, warm, timeless, intentional.
- **No clutter.** Breathing room beats density. Remove before you add.
- **Premium and immersive.** The UI should feel calm, confident, and tactile.
- **East African luxury market.** Warm, grounded, never cold or corporate.
- **UI-first with dummy data.** Backend and real AI are handled by a separate
  team. Build mock-driven UI; do not wire real services unless asked.
- **Designer leads, Kiro builds to spec.** Screens are reviewed via screenshots
  before building. Don't rush ahead or invent scope.

## Color Palette

Use these constants. Do not introduce new colors without a reason.

| Role                  | Hex          |
|-----------------------|--------------|
| Background (off-white)| `0xFFF2F2EE` |
| Background (warm alt) | `0xFFEFEFE9` |
| Dark charcoal         | `0xFF2A2A2A` |
| Signature gold        | `0xFFB5945A` |
| Secondary text grey   | `0xFF8B8B8B` |
| Light grey / dividers | `0xFFD8D8D8` / `0xFFE8E8E8` |

- Gold is an accent, not a fill. Use it for emphasis, active states, and price.
- Charcoal carries text and dark surfaces (nav, send buttons).

## Typography

- **Satoshi only.** Weights: 300 (Light), 400 (Regular), 500 (Medium),
  700 (Bold). Always set `fontFamily: 'Satoshi'`.
- Labels / captions: w400, grey.
- Titles / values / prices: w600–w700, charcoal (or gold for prices).
- Keep line-height generous on body copy (~1.4–1.5).

## Shape & Depth

- **Rounded corners everywhere:** cards 20–26, pills & search bars 28–32,
  avatars & icon buttons full circle.
- **Soft shadows only.** Black at 4–14% opacity, large blur, small offset.
  Never harsh or high-contrast drop shadows.

## Motion

- Purposeful and smooth. Standard transitions ~200ms with ease curves.
- Signature touches: the animated gold sweep-gradient border on search bars,
  the typewriter intro on the AI screen. Reuse these patterns for cohesion.
- Animations should feel like silk — never bouncy, jarring, or attention-seeking.

## Layout

- **20px horizontal padding** on screen content.
- Maintain consistent vertical rhythm between sections.
- Bottom-pad scrollable content ~100–120px so it clears the floating bottom nav.
- The app shell is a `PageView` driven by `CustomBottomNav` (Home, Explore,
  Visual Studio, AI Agent). New primary screens slot into this navigator.

## Code Conventions

- Match the existing file structure: screens in `lib/screens/`, reusable
  widgets in `lib/widgets/`.
- Shared color constants are currently duplicated per-file. Prefer extracting to
  a shared theme when touching multiple screens, but don't refactor unprompted.
- Keep dummy data in clearly-named local lists/maps at the top of the screen file.
- Use `const` constructors wherever possible for performance.
