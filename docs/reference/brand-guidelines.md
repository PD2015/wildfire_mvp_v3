---
title: WildFire Brand Guidelines
status: active
version: 1.0
doc_version: 1.0
created: 2026-02-11
last_updated: 2026-02-11
author: Liz Stevenson
category: reference
subcategory: brand
related:
  - app-overview.md
  - ../guides/development/new-feature-workflow.md
changelog:
  - date: 2026-02-11
    change: Initial brand guidelines extracted from codebase theme files
---

# WildFire Brand Guidelines

| | |
|---|---|
| **Version** | 1.0 |
| **Last Updated** | 2026-02-11 |
| **Source of Truth** | `lib/theme/brand_palette.dart`, `lib/theme/risk_palette.dart`, `lib/theme/wildfire_a11y_theme.dart` |
| **Compliance** | WCAG 2.1 AA |

---

## 1. Brand Overview

WildFire is a Scottish wildfire risk assessment app. The brand communicates **trust, nature, safety, and urgency** — grounded in the Scottish landscape while clearly conveying fire risk when it matters.

### Brand Personality

| Trait | Expression |
|-------|-----------|
| **Trustworthy** | Official data sources (EU, NASA, SEPA), transparent attribution |
| **Grounded** | Deep forest greens rooted in the Scottish Highlands |
| **Accessible** | Plain language, high-contrast colours, inclusive design |
| **Calm yet urgent** | Calming forest tones for everyday use; bold, warm risk colours when danger rises |

### Voice & Tone

- **Clear and direct** — "Very High fire risk today" not "Elevated FWI levels detected"
- **Reassuring** — "Your chosen location" not "Manually entered coordinates"
- **Action-oriented** — "Check risk before you go" not "Risk information available"
- **Non-alarmist** — Use risk levels factually; avoid sensationalism

---

## 2. Logo & App Icon

### App Icon

- **Primary colour**: Forest 600 (`#1B6B61`) background
- **Icon**: Stylised flame/landscape mark in white
- **Shape**: Adaptive icon with 20dp padding for Android circular mask
- **Splash**: Centred icon on `#1B6B61` background

### Icon Assets

| Asset | Size | Use |
|-------|------|-----|
| `app_icon.png` | 1024×1024 | Primary app icon |
| `app_icon_ios.png` | 1024×1024 | iOS-specific (no transparency) |
| `app_icon_adaptive.png` | 512×512 | Android adaptive foreground |
| `splash_icon.png` | 512×512 | Splash screen centred icon |

### Clear Space

Maintain a minimum clear space around the logo equal to the height of the flame element. Do not place the logo on busy backgrounds without a solid-colour container.

---

## 3. Colour Palette

### 3.1 Brand Colours (App Chrome)

Used for navigation, surfaces, backgrounds, buttons, and all general UI. **Never use these for fire risk indicators.**

#### Forest (Primary)

| Swatch | Hex | RGB | Use |
|--------|-----|-----|-----|
| Forest 900 | `#0D4F48` | 13, 79, 72 | Darkest backgrounds, SnackBars |
| Forest 800 | `#0F5A52` | 15, 90, 82 | Dark mode surfaces |
| Forest 700 | `#17645B` | 23, 100, 91 | Bottom navigation, dark surfaces |
| **Forest 600** | **`#1B6B61`** | **27, 107, 97** | **Primary — AppBar, buttons, splash** |
| Forest 500 | `#246F65` | 36, 111, 101 | Hover/pressed states |
| Forest 400 | `#2E786E` | 46, 120, 110 | Dark mode primary |
| Outline | `#3E8277` | 62, 130, 119 | UI borders and outlines |

#### Mint (Secondary)

| Swatch | Hex | RGB | Use |
|--------|-----|-----|-----|
| **Mint 400** | **`#64C8BB`** | **100, 200, 187** | **Secondary accent, selected nav indicator** |
| Mint 300 | `#7ED5CA` | 126, 213, 202 | Lighter accent, inverse primary |

#### Amber (Tertiary)

| Swatch | Hex | RGB | Use |
|--------|-----|-----|-----|
| **Amber 500** | **`#F5A623`** | **245, 166, 35** | **Tertiary accent, FABs, warnings** |
| Amber 600 | `#E59414` | 229, 148, 20 | Darker amber for containers |

#### Neutrals

| Swatch | Hex | RGB | Use |
|--------|-----|-----|-----|
| Off White | `#F4F4F4` | 244, 244, 244 | Light mode surface |
| Grey 100 | `#E0E0E0` | 224, 224, 224 | Outline variant, dividers |
| Grey 200 | `#757575` | 117, 117, 117 | Disabled/low emphasis |

#### On-Colours (Text & Icons)

| Token | Hex | Use |
|-------|-----|-----|
| On Dark High | `#FFFFFF` | White — primary text on dark |
| On Dark Medium | `#DCEFEB` | Teal-tinted — secondary text on dark |
| On Dark Low | `#B8D8D2` | Low emphasis on dark |
| On Light High | `#111111` | Near-black — primary text on light |
| On Light Medium | `#333333` | Dark grey — secondary text on light |

### 3.2 Risk Colours (Fire Risk Only)

Used **exclusively** for fire risk level indicators — banners, chips, scales. **Never use these for general UI chrome.**

| Risk Level | Hex | RGB | FWI Range | Suggested Label |
|-----------|-----|-----|-----------|----------------|
| Very Low | `#4CAF50` | 76, 175, 80 | 0–4.99 | Very Low |
| Low | `#8BC34A` | 139, 195, 74 | 5–11.99 | Low |
| Moderate | `#FFEB3B` | 255, 235, 59 | 12–20.99 | Moderate |
| High | `#FF9800` | 255, 152, 0 | 21–37.99 | High |
| Very High | `#F44336` | 244, 67, 54 | 38–49.99 | Very High |
| Extreme | `#B71C1C` | 183, 28, 28 | ≥50 | Extreme |

> **⚠️ Important**: Brand colours and risk colours must **never be mixed**. Risk colours have specific safety meaning and must only represent fire risk levels.

### 3.3 Colour Usage Rules

| ✅ Do | ❌ Don't |
|-------|---------|
| Use Forest 600 for app headers and CTAs | Use Forest 600 to mean "safe" or "low risk" |
| Use Risk palette for risk indicators only | Use Risk green for success states |
| Use Amber 500 for non-risk warnings | Use Risk red for error messages |
| Maintain palette separation in all assets | Mix brand and risk colours in the same element |

---

## 4. Typography

### Font Stack

The app uses the **system default font** per platform for optimal readability and performance:

| Platform | Font |
|----------|------|
| Android | Roboto |
| iOS | SF Pro |
| Web | System UI stack |
| macOS | SF Pro |

### Type Scale

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| Headline | 24px | SemiBold (600) | Screen titles |
| Title | 20px | SemiBold (600) | AppBar titles, section headers |
| Body Large | 16px | Medium (500) | Button labels, primary content |
| Body | 14px | Regular (400) | Card content, descriptions |
| Label | 12px | Medium (500) | Chips, timestamps, captions |

### Typography Rules

- **Minimum text size**: 14px for body content (WCAG AA)
- **Minimum contrast**: 4.5:1 for normal text, 3:1 for large text (≥18px or ≥14px bold)
- **Line height**: 1.4–1.6× font size for readability
- **Never use all-caps** for body text; acceptable for short labels only

---

## 5. Spacing & Layout

### Spacing Scale

| Token | Value | Use |
|-------|-------|-----|
| xs | 4dp | Icon-to-text gaps |
| sm | 8dp | Intra-component padding |
| md | 12dp | Component gaps |
| lg | 16dp | Section padding, card insets |
| xl | 24dp | Screen margins |
| xxl | 32dp | Major section breaks |

### Corner Radius

| Token | Value | Use |
|-------|-------|-----|
| Card | 16dp | Cards, panels, containers |
| Control | 12dp | Buttons, chips, inputs |
| Badge | 20dp | Circular badges, pills |

### Touch Targets

All interactive elements must meet minimum touch target sizes:
- **iOS**: ≥44dp × 44dp
- **Android**: ≥48dp × 48dp
- **Buttons**: minimum 64dp width × 44dp height
- **Chip padding**: 12dp horizontal × 8dp vertical

---

## 6. Accessibility Requirements

All marketing assets should maintain WCAG 2.1 AA compliance:

### Contrast Ratios

| Combination | Ratio | Status |
|------------|-------|--------|
| Forest 600 on Off White | 5.2:1 | ✅ AA |
| Forest 600 on White | 5.2:1 | ✅ AA |
| White on Forest 900 | 11.3:1 | ✅ AAA |
| Mint 400 on Forest 900 | 4.6:1 | ✅ AA |
| Amber 500 on Forest 900 | 7.1:1 | ✅ AA |
| On Light High on Off White | 17.4:1 | ✅ AAA |

### Verified Pairings for Marketing

| Background | Text Colour | Minimum Use |
|-----------|------------|-------------|
| Forest 600 (`#1B6B61`) | White (`#FFFFFF`) | Headlines, CTAs |
| Forest 900 (`#0D4F48`) | White (`#FFFFFF`) | Hero sections |
| Forest 900 (`#0D4F48`) | Mint 400 (`#64C8BB`) | Accent text, links |
| Off White (`#F4F4F4`) | On Light High (`#111111`) | Body text |
| White (`#FFFFFF`) | Forest 600 (`#1B6B61`) | Inverted CTAs |

### Don't

- Never place risk colours on forest backgrounds without checking contrast
- Never use Moderate yellow (`#FFEB3B`) as a text colour — it fails contrast on all backgrounds
- Never use thin (< 400 weight) fonts below 16px

---

## 7. Imagery & Photography

### Style

- **Landscape photography**: Scottish Highlands, heather moorland, mountain panoramas
- **Colour treatment**: Slightly desaturated, warm tones — let the brand greens and risk colours stand out
- **Avoid**: Stock photos of raging wildfires (alarmist); use controlled burn or landscape shots instead
- **People**: Hillwalkers, farmers, rural communities — authentic, not staged

### Overlays

When placing text on photography:
- Use a **Forest 900 overlay at 70–80% opacity** for text legibility
- Or place text in a **solid Forest 600/900 panel** adjacent to the image
- Never place text directly on an unmodified photo

---

## 8. Light & Dark Mode

The app supports automatic light/dark mode switching. Marketing assets should consider both:

### Light Mode

| Element | Colour |
|---------|--------|
| Background | Off White `#F4F4F4` or White `#FFFFFF` |
| Primary text | `#111111` |
| Secondary text | `#333333` |
| AppBar / Header | Forest 600 `#1B6B61` |
| Navigation | Forest 700 `#17645B` |
| Cards | `#F8F8F8` with `#E0E0E0` border |

### Dark Mode

| Element | Colour |
|---------|--------|
| Background | Forest 900 `#0D4F48` |
| Primary text | `#FFFFFF` |
| Secondary text | `#DCEFEB` |
| Primary accent | Mint 400 `#64C8BB` |
| Navigation | Forest 700 `#17645B` |
| Cards | Forest 800 `#0F5A52` |

---

## 9. Component Patterns

### Buttons

| Type | Background | Text | Border | Use |
|------|-----------|------|--------|-----|
| Primary (Filled) | Forest 600 | White | None | Main CTAs |
| Secondary (Outlined) | Transparent | Forest 700 | Forest outline | Secondary actions |
| Text | Transparent | Forest 600 | None | Tertiary actions |
| Danger | Red 700 | White | None | Destructive actions |

All buttons: 12dp corner radius, ≥44dp height, 16px semibold text.

### Chips

- Background: Surface colour
- Border: Outline colour, 1px
- Text: 14px, On Surface colour
- Padding: 12dp horizontal × 8dp vertical

### Cards

- Background: Surface Container Low (`#F8F8F8` light / Forest 800 dark)
- Border: Outline Variant (`#E0E0E0` light / Forest 700 dark), 1px
- Corner radius: 16dp
- Elevation: 2dp
- Padding: 16dp inset

### Risk Banner

- Full-width, colour-coded by risk level
- Risk colour background with appropriate on-colour text
- Must include data source attribution and UTC timestamp

---

## 10. Do's and Don'ts

### ✅ Do

- Use Forest 600 as the hero brand colour
- Maintain strict separation between brand and risk palettes
- Always include data source attribution when showing fire data
- Design for accessibility first — contrast, touch targets, readable fonts
- Use the Scottish landscape aesthetic — understated, grounded, natural
- Test all colour combinations with a contrast checker

### ❌ Don't

- Don't use risk colours (red, amber, green) for general UI decoration
- Don't place the app icon on backgrounds that clash with Forest 600
- Don't use more than 2 brand colours in a single marketing asset
- Don't use thin fonts or light grey text on white backgrounds
- Don't use imagery of wildfires for shock value
- Don't claim official government endorsement (the app uses public data)

---

## 11. Quick Reference

### Hero Colours (Copy-Paste)

```
Primary:    #1B6B61  (Forest 600)
Secondary:  #64C8BB  (Mint 400)
Tertiary:   #F5A623  (Amber 500)
Dark:       #0D4F48  (Forest 900)
Light:      #F4F4F4  (Off White)
Text Dark:  #111111  (On Light High)
Text Light: #FFFFFF  (On Dark High)
```

### Risk Scale (Copy-Paste)

```
Very Low:   #4CAF50
Low:        #8BC34A
Moderate:   #FFEB3B
High:       #FF9800
Very High:  #F44336
Extreme:    #B71C1C
```

### Figma / Design Tool Setup

When setting up a design file, create these colour styles:

1. **Brand/Forest-900** → `#0D4F48`
2. **Brand/Forest-600** → `#1B6B61`
3. **Brand/Mint-400** → `#64C8BB`
4. **Brand/Amber-500** → `#F5A623`
5. **Brand/Off-White** → `#F4F4F4`
6. **Brand/On-Dark** → `#FFFFFF`
7. **Brand/On-Light** → `#111111`
8. **Risk/Very-Low** → `#4CAF50`
9. **Risk/Low** → `#8BC34A`
10. **Risk/Moderate** → `#FFEB3B`
11. **Risk/High** → `#FF9800`
12. **Risk/Very-High** → `#F44336`
13. **Risk/Extreme** → `#B71C1C`
