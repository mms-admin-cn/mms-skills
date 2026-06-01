---
name: uni-app-x-ucss
description: Use when building or reviewing Uni-App X pages, UTS/UVue components, UCSS styles, HBuilderX Android/iOS app layouts, or when converting web CSS into Uni-App X-compatible app UI. Guides use of official Uni-App X CSS constraints, supported selectors/properties, flex layouts, units, scrolling, and production app layout checks.
---

# Uni-App X UCSS

Use this skill for `.uvue`, `.uts`, Uni-App X, HBuilderX app styling, and any request that mentions UCSS or Android/iOS Uni-App X layout compatibility.

## Source Of Truth

Start from official docs when a style choice is uncertain:

- CSS overview: `https://doc.dcloud.net.cn/uni-app-x/css/`
- Selectors: `https://doc.dcloud.net.cn/uni-app-x/css/common/selector.html`
- Length units: `https://doc.dcloud.net.cn/uni-app-x/css/common/length.html`
- Display: `https://doc.dcloud.net.cn/uni-app-x/css/display.html`

Treat Uni-App X CSS as native UCSS, not browser CSS. If a property, unit, selector, function, or value is not in the official compatibility table for the target platform, do not use it.

## Layout Rules

- Prefer `view`, `text`, `button`, `input`, and `scroll-view` primitives with class styles.
- Use flex layouts. In Uni-App X, `display` defaults to `flex`; write `display: flex` when clarity matters, and use `flex-direction` deliberately.
- Avoid CSS Grid, floats, complex positioning, CSS variables, calc-heavy layouts, viewport units on Android, and web-only visual tricks.
- Keep selectors simple. Prefer single class selectors. Relationship selectors work in newer versions but cost runtime performance on App; avoid them for frequently changing UI.
- Avoid pseudo-elements and pseudo-classes for app interaction states. Use component state classes or `hover-class` when a pressed state is needed.
- Styles do not inherit like normal web CSS. Put text color, size, weight, and line height on the actual `text`, `button`, or `input` class that renders it.
- Use `rpx`, `px`, and `%` conservatively. For Android app layouts, avoid relying on `vw`, `vh`, `vmin`, or `vmax` unless official compatibility confirms the exact target.
- Be cautious with properties listed by the CSS overview as not supporting flattening, including `background-image`, `pointer-events`, `transition*`, `visibility`, `z-index`, and text-decoration variants.

## App UI Pattern

For landscape POS/admin tools:

1. Build the first screen as the working tool, not a marketing/intro page.
2. Use a stable shell: sidebar or top navigation, fixed summary/action area, and scrollable content where lists can grow.
3. Make touch targets large and predictable, with fixed dimensions for nav, category chips, keypad buttons, cards, and list rows.
4. Use restrained operational styling: high contrast text, clear status color, limited shadows, and density that supports repeated cashier work.
5. Avoid nested cards and decorative backgrounds; reserve framed surfaces for actual repeated items, panels, modals, and operational tools.

## Verification

Before finishing:

- Scan changed `.uvue` files for unsupported web CSS patterns such as `display: grid`, `grid-template`, `gap`, CSS variables, `calc(`, pseudo selectors, `position: sticky`, `float`, and viewport units.
- Verify JSON config files parse and routes point to existing `.uvue` files.
- Run available project tests. If HBuilderX/Uni-App X compile is unavailable, state that explicitly.
