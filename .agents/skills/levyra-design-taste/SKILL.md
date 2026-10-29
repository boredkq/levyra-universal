---
name: levyra-design-taste
description: Quality gate and visual taste guidelines for Levyra UI development. Enforces anti-AI-slop rules, strict token discipline, typography scales, tactile geometry, purposeful motion, responsive layout hierarchy, and product-state completeness across Desktop and Mobile surfaces.
---

# Levyra Design Taste & Visual Guidelines

## 1. Product Character & Philosophy
Levyra is a dark-first, premium, content-centric music experience:
- **Artwork is the Hero**: Color emanates from album art, motion canvas, and artist imagery. Backgrounds remain deep, calm, and near-black (`#07090D`, `#0B0E14`), never competing with the album art.
- **Desktop Native & Mobile Ergonomics**:
  - Desktop: Persistent 220px left sidebar, 18px container rounding, bottom playback dock (88px), floating Picture-in-Picture mini-player.
  - Mobile: Bottom bar navigation, 64px floating mini-player, full-screen player sheet with dynamic mesh gradient wash.

## 2. Color Tokens & Surface Ladder
| Token | Hex | Role |
| :--- | :--- | :--- |
| `Canvas` | `#07090D` | Deepest background layer |
| `Base Surface` | `#0B0E14` | Sidebar and page base |
| `Container` | `#0F131B` | Card surfaces, inputs, list items |
| `Elevated Container` | `#151A23` | Floating docks, modals, sheets |
| `Highest Container` | `#1B2230` | Active highlights, tooltips |
| `Primary Text` | `#F4F7FB` | High-contrast headings and track titles |
| `Secondary Text` | `#A7B0BE` | Artists, metadata, timestamps |
| `Hairline Border` | `#202734` | Subtle 1px structural separators |
| `Levyra Cyan` | `#27D9F5` | Play state, primary focus, active nav |
| `Levyra Violet` | `#8B7CFF` | Personal flow, «Твоя орбита», mixes |
| `Discovery Mint` | `#50E3B3` | «Открытие», fresh releases, new badges |

## 3. Anti-AI-Slop Rules (Visual Discipline)
- **NO gratuitous glassmorphism**: Don't put frosted glass or excessive blur on every surface. Use it sparingly on floating navigation/player bars.
- **NO generic purple/blue gradients**: Gradients must be derived dynamically from track artwork (`PaletteGenerator`) or use semantic tokens.
- **NO interchangeable identical cards**: Maintain clear visual hierarchy: Hero items > Featured releases > Compact rows.
- **NO excessive pill badges**: Don't clutter cards with 5 different colored chips.
- **NO decorative whitespace waste**: Music apps need scannable density for large catalogs (13–15px body, 11–12px metadata).
- **Tactile geometry**: Cards use 12–18px radii; buttons use pills or circles; avatar clusters use perfect circles.

## 4. Motion Guidelines
- Every animation must have a purpose: explaining state change, spatial continuity (mini-player expanding into full player), or confirming user action.
- Synced lyrics highlight: smooth progressive line/word fill, not jerky jumps.
- Video mode switch: seamless crossfade without playback hiccups.
