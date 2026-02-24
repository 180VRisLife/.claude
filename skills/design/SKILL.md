---
name: design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, or applications. Generates creative, polished code that avoids generic AI aesthetics.
user-invocable: true
disable-model-invocation: false
license: Complete terms in LICENSE.txt
---

## Design Thinking

Before coding, commit to a BOLD, intentional aesthetic direction:

- **Purpose**: What problem does this solve? Who uses it?
- **Tone**: Pick an extreme — brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian. Use for inspiration but design one true to the direction.
- **Constraints**: Framework, performance, accessibility requirements.
- **Differentiation**: What's the ONE thing someone remembers? Apply the 5-second clarity test — could a user understand the idea in 5 seconds? Structure > flashiness.
- **States**: Design ALL states upfront: loading (skeleton + shimmer), empty (message + illustration + next-step), error, success. Use optimistic UI where appropriate.

## Typography

Mathematical scale from **16px base**: golden ratio **1.618** for dramatic, square-root **1.27** for general use, cube-root **1.17** for dashboards/mobile. Responsive sizing via fluid clamp().

- **Weights**: max 2, separated by ≥1 level (e.g., 400+700, never 400+500)
- **Text colors**: max 2 variants — primary at 100% opacity, secondary at 40-70% opacity
- **Line height**: ~150% body, 110-130% headings; large text needs tighter line height
- **Kerning**: text over 70px needs -2% to -4% letter-spacing
- **Pairing**: max 2-3 fonts; display font for giant text ONLY (1-2x per page max), never for body
- **NEVER**: Inter, Roboto, Arial, system fonts, Space Grotesk — choose distinctive, characterful fonts
- Giant display text (290px+) as visual element creates hierarchy through size discrepancy with body text

## Color System

Build in 4 layers:

**1. Neutrals**: Tinted grays, never pure black/white. 4+ background layers, card borders ~85% white, sidebar with 2% brand tint. Button importance = darkness (ghost → bordered → filled → black with white text).

**2. Brand Ramp**: Think in scales, not single colors. 500-600 primary, 700 hover, 400-500 links. Dark mode: 300-400 primary, 400-500 hover. Tailwind shortcut: 50 light bg, 500 accent, 300 dark primary, 950 dark bg.

**3. Semantic**: Red = destructive/notifications, green = success, yellow = warnings. Never break semantic meaning. Charts use full spectrum, not just brand color.

**4. Depth via OKLCH**: Set lightness + chroma, increment hue by 25-30°. For variants: drop lightness -0.03, increase chroma +0.02, shift hue toward blue.

**Dark mode**: NOT inverse of light mode. 2x contrast distance (2% light difference = 4-6% dark). Surfaces lighten as they elevate. Light gray text > white (pure white only for logo/key numbers). Colors may need desaturation.

**Shadows**: X ≤ Y, blur = 1.5-2x Y, 15-20% opacity. Use light gray not black. Often better to remove shadows entirely. **Gradients**: stick to variations of same color; most designs look cleaner without.

## Layout & Spacing

**4px/8px base grid**. Dashboards = strict grid; landing pages can break grid. Default mistake: too tight — increase vertical spacing, use fewer containers. White space separates via proximity principle.

- **Nested corners**: outer radius - gap = inner radius (30px outer, 10px gap = 20px inner). Enable iOS corner smoothing.
- **Dashboard**: sidebar spine + 2-col/2-row grid. Most important info top-left. Features much smaller than landing pages. 3-4 essential data points per item.
- **Hero**: big text + big image + lots of space. Differentiate with unique fonts, inline diagrams, interactive elements.
- **Social proof**: logo marquee with gradient blur on edges (41 of 50 top sites use logo grids).
- **Footer**: simple centered for 3-5 links; full footer only when 5+ links needed.
- **Navigation**: consider images in dropdowns (modern trend replacing text-only).
- **60-30-10 rule**: works for landing pages, NOT for product/dashboard UI (products often 90/8/2).

## Motion

One orchestrated page load with staggered reveals > scattered micro-interactions. Keep animations short and subtle.

- **Hover**: text slide-up + background color shift. **Click**: scale down slightly. **Tooltips**: 1000ms delay.
- **Custom spring**: stiffness 636, dampening 24, ~500ms — creates satisfying bounce.
- **Scroll**: parallax (background/foreground speed difference), gradient highlight with text mask animated on scroll.
- **Loading**: skeleton shimmer, word-by-word streaming for AI content, short looping fluid animations.
- **Toasts**: slide-up with loading → success states. Add celebratory particles for positive feedback.
- **Premium effects**: angular gradient + mask + rotate for shimmer stroke; rectangle transparency + gradient + background blur + 1px border + soft inner shadow for glass.
- **Mobile**: no hover → use press effects (slightly darker on press). Slide-up = temporary, slide-from-left = forward navigation. Mouse effects need mobile fallback.

## Component Patterns

- **Cards**: round edges for friendly feel. Many repeating cards → entire card is link (no separate button), hover shows arrow. Gradient overlay from bottom to mid-point for text on image.
- **Inputs**: labels ABOVE (never inside), real example data, off-white background, 40% opacity strokes, 4px grid.
- **Charts**: no rounded bar tops (hard to read), always include axis labels, straight lines not curved, hover shows data + dims irrelevant bars, add grid lines.
- **Chips**: always thinner than buttons, never primary CTA color. Padding: vertical = 1/2 or 1/4 of horizontal.
- **Lists**: space items far apart; subtle alternating row backgrounds instead of dividers.
- **Pricing**: CTA higher in card, check marks not bullets, show what plan DOESN'T include, max 3-4 plans.
- **AI components**: giant input as primary interface with context chips. Show research trail (fade in steps one-by-one). Confidence as visual pill bar.

## AI Anti-Patterns — NEVER Do These

Emojis instead of icon libraries (use Phosphor, Lucide, Feather). Bright unharmonized colors. Repeated KPIs showing same data. Gradient circles with initials. Sparse modals with excessive whitespace. Scattered buttons/chips without visual logic. Missing interactive states (hover, loading, error, empty). Ignoring user flow (how did they get here? what's next?). Purple gradients on white backgrounds. Overly complex layouts for simple tasks.

## Execution

Copy: conversational > corporate ("We sweat the details" not "We take pride in our attention to detail"). No two designs should look the same — vary themes, fonts, and aesthetics across generations.
