# PHASE_12.MD — Premium UX & Polish Overhaul

> **Document Version:** 12.0
> **Parent Document:** `CLAUDE.MD` v2.2-MVP (this document extends, never overrides)
> **Target Executor:** Claude 3.5 Sonnet (Junior Coder)
> **Authored By:** Staff Architect / Lead UI Engineer
> **Status:** MANDATORY before Phase 10 build
> **Last Updated:** 2026-04-24

---

## 12.0 Preamble — Why This Phase Exists

The MVP compiles. The MVP routes. The MVP persists. The MVP still **looks wrong.**

A functional chat app that looks like a default Material 3 mobile port ported to desktop does not sell a $99 lifetime license. Our entire competitive moat — the reason a user pays us instead of juggling five provider dashboards themselves — is the polish of the shell wrapped around their API keys. If the shell feels cheap, the product *is* cheap, regardless of how elegant the delegation engine is underneath.

This phase closes the gap between the current UI and the bar defined in **Absolute Law #6 (PREMIUM UX LAW)**: Claude Desktop / Linear / Raycast. It is not a visual pass. It is a structural correction of five specific architectural defects that are compounding into a cheap overall impression:

1. **A 369-pixel layout overflow** caused by unbounded flex children.
2. **Default Material widget "slop"** — flat buttons, mobile-sized pill switches, inconsistent corner radii.
3. **A harsh, neon status palette** and a primary purple that fights the dark surface instead of sitting inside it.
4. **Tiny generic Material icons in dark boxes** on the use-case screen where the spec explicitly called for illustrated SVGs.
5. **Raw Google API JSON dumped onto the screen** — a direct violation of Section 8.4 ("Never show raw exception messages, stack traces, or HTTP status codes to users").

Each defect is diagnosed below with an architectural root cause and a concrete UI/UX strategy. No defect is treated as cosmetic. Every one of them is a structural bug that happens to render visually.

**Scope discipline:** This phase does not add features. It does not expand MVP. Every item below either fixes a thing that already exists or establishes a design primitive that the already-scoped screens will consume. If you catch yourself inventing a feature, stop.

---

## 12.1 Reaffirmation of Absolute Laws

All six Absolute Laws from `CLAUDE.MD` Section 1.2 apply to this phase without modification. The three most relevant to a UI overhaul are restated here because they will be tested by the temptations this work creates:

1. **ZERO-PROMPT-BACKEND LAW** — No telemetry on interactions, no remote theming service, no server-rendered components. Every pixel renders from the user's local binary.
2. **LOCAL-FIRST LAW** — All illustration assets (SVGs) ship bundled in `assets/`. No remote asset CDN. No `NetworkImage`. No lazy-fetched icons.
3. **MVP-SCOPE LAW** — A polish phase is the single most seductive place to scope-creep. Custom particle effects, animated gradients on login, Lottie splash screens, dark/light mode theme *transitions* — **none** of this is in scope. Every deliverable below maps to one of the five diagnosed defects or to the design-token foundation those fixes require.
4. **SINGLE-FILE OUTPUT LAW** — When Sonnet produces any file listed in Section 12.8, it must be the **complete file**, first import to last closing brace. No diffs. No "add this block near the top." No partial patches against assumed existing state.
5. **PREMIUM UX LAW** — The ceiling. Every widget below must feel like it belongs in Linear's command palette or Claude Desktop's sidebar. If a choice trades polish for convenience, polish wins.

---

## 12.2 Syntax Enforcement — Non-Negotiable for This Phase

Section 2.2 and 2.3 of `CLAUDE.MD` are **fully in force** during Phase 12. The UI work below tempts regressions because widget files often grow faster than provider files. Explicitly restated:

- **All state is Riverpod `@riverpod` codegen.** Any new theme-mode provider, dialog-state provider, or error-state provider uses annotation-based syntax with `part '*.g.dart';`. Legacy `StateNotifierProvider`, `ChangeNotifierProvider`, and manual `Provider<T>((ref) => ...)` are **banned**. Mixing old and new Riverpod syntax is a critical failure.
- **All state classes are `@immutable`.** Theme tokens, error models, dialog descriptors — every value object uses `const` constructors, final fields, and `copyWith`. No setters, no mutable fields, no `late var`.
- **Named parameters with `required`** on every widget, model, and service constructor. Positional parameters are banned in public widget APIs.
- **Pure Dart Material 3 widget composition.** Every fix below is built from Flutter's Material 3 primitives (`FilledButton`, `Switch`, `Card`, `Dialog`, `Expanded`, `ConstrainedBox`, `SingleChildScrollView`). No `showCupertinoDialog`. No `window_manager`-driven dialogs. No `file_picker` popups. No platform-channel-bridged native OS dialogs. We compose our own. That is the entire point of this phase.
- **No new dependencies.** `flutter_svg` is the one permitted addition because the original onboarding spec already requires SVG illustrations and Flutter ships no SVG renderer. Any other package request must be approved in writing before a `pubspec.yaml` change. If Sonnet is about to add `glassmorphism`, `shimmer`, `animated_text_kit`, `lottie`, `flutter_neumorphic`, any "material_extended" variant, or any third-party toggle/switch package — **stop**.
- **`const` everywhere it compiles.** Every widget, every color, every text style, every `EdgeInsets`, every `BorderRadius`. Flutter's rebuild optimization depends on this.
- **Generated files:** After modifying any provider or model with a `part` directive, remind the user to run `dart run build_runner build --delete-conflicting-outputs`.

---

## 12.3 Defect #1 — The 369-Pixel Overflow

### 12.3.1 Architectural Diagnosis

"BOTTOM OVERFLOWED BY 369 PIXELS" on the Technical Details screen is a **flex-bounds violation**, not a styling problem. A widget subtree is attempting to lay out content taller than its parent constraint and no scroll ancestor is catching the overflow. In Flutter, this almost always means one of three root causes:

1. A `Column` with long children placed directly inside a `Dialog`, `AlertDialog`, or `Card` with no `SingleChildScrollView` wrapping it.
2. A `Column` inside an `Expanded` or `Flex` that itself has an unconstrained vertical parent (common when a dialog content area forgets to pass a `ConstrainedBox` with `maxHeight`).
3. An error/info display component that dumps arbitrarily long text (see Defect #5) into a fixed-height layout with no scrolling strategy.

Given that the overflow appears on a "Technical Details" block, cause #3 compounds cause #1: the JSON dump is expanding a non-scrolling `Column` inside a dialog that assumes bounded content.

### 12.3.2 Strategy

Every dialog, bottom sheet, and modal in Briluxforge must adopt a **single universal layout contract**:

```
Dialog (or Card)
  └─ ConstrainedBox( maxHeight: 0.8 × screenHeight, maxWidth: 560 )
      └─ Column( mainAxisSize: MainAxisSize.min )
          ├─ Header (fixed)
          ├─ Expanded
          │   └─ SingleChildScrollView
          │       └─ Content (arbitrarily tall)
          └─ Footer / Actions (fixed)
```

This is not a suggestion. It is the only permitted dialog structure in the codebase after Phase 12. Every current modal must be refactored to this shape.

**Additional constraints:**

- No dialog exceeds `560px` wide on desktop. Dialogs that consume the full window feel like mobile modals and break the desktop feel.
- No dialog exceeds `80%` of the current window height. Content inside is always scrollable when it would otherwise clip.
- The input modals (error details, about, license) must use `AppDialog` — a new shared widget defined in Section 12.8 — and **never** call `showDialog` with raw `AlertDialog` again.

### 12.3.3 Specification

Create `lib/core/widgets/app_dialog.dart` containing a single `AppDialog` widget with named parameters: `title`, `body`, `primaryAction`, `secondaryAction`, `maxWidth` (default 560), `maxHeightFactor` (default 0.8). Internally composes the layout above. Every existing `showDialog` call site is migrated to `showAppDialog()` — a thin helper also defined in this file. No `AlertDialog` is permitted to remain in the codebase.

---

## 12.4 Defect #2 — Default Material "Slop"

### 12.4.1 Architectural Diagnosis

The current UI does not have a **design token system.** It has `ThemeData.useMaterial3: true` and the `colorSchemeSeed` of our primary purple, and everything else falls to Material 3 defaults. Those defaults are calibrated for Android mobile. When rendered at desktop density on a 1440p screen, they look flat, oversized, and generic.

Specifically:

- **Buttons** inherit the default Material 3 `FilledButton` style: a solid fill with no border, no inner highlight, no shadow calibration for a dark surface. On dark backgrounds with saturated primary colors this reads as a printed decal, not a tactile control.
- **Switches** inherit the mobile-first Material 3 `Switch` — a large pill track with a draggable thumb. On desktop these read as clumsy and toylike. Linear, Raycast, and Claude Desktop all use compact switches (~36×20px) or checkbox-style toggles.
- **Corner radii** are assigned ad-hoc per widget: some cards are 12px, some are 16px, some buttons are 8px, some are 20px (the Material default), and some inputs are pills. There is no ladder, no rhythm, no system.

The root architectural issue is the **absence of a shared tokens layer** between `AppColors` and the widget tree. Colors alone are not a design system.

### 12.4.2 Strategy — Introduce `AppTokens`

Create a single source of truth for all non-color visual values: `lib/core/theme/app_tokens.dart`. This file defines three immutable token groups:

- **`AppRadii`** — the complete set of allowed corner radii. Four values only: `xs = 4`, `sm = 8`, `md = 12`, `lg = 16`. No other radius value is permitted anywhere in the codebase. Pills and fully-rounded widgets are banned outside of avatars and loading indicators.
- **`AppSpacing`** — the spacing ladder. Six values: `2, 4, 8, 12, 16, 24, 32`. All `EdgeInsets`, `SizedBox`, and `Gap` values must come from this ladder. Ad-hoc `EdgeInsets.all(13)` is banned.
- **`AppElevation`** — the depth ladder. Three levels only: `none`, `subtle` (`BoxShadow(blurRadius: 8, color: black @ 4% opacity, offset: 0,1)`), `raised` (`blurRadius: 16, color: black @ 8% opacity, offset: 0,2`). Elevation is tinted for dark theme using a warm-neutral overlay rather than pure black so shadows don't look like holes.

Every widget in the codebase consumes these tokens. No hardcoded `12.0`, `BorderRadius.circular(8)`, or `BoxShadow(...)` outside of this file.

### 12.4.3 Button System — `AppButton`

Create `lib/core/widgets/app_button.dart` exposing three variants via a single `AppButton` widget with an `AppButtonVariant` enum: `primary`, `secondary`, `ghost`. All three compose over Material 3 `FilledButton` / `OutlinedButton` / `TextButton` respectively, with the following non-negotiable overrides:

- **Radius:** `AppRadii.sm` (8px) for all buttons. No pills. No squared corners.
- **Height:** `36px` default, `32px` compact, `44px` large. Desktop-calibrated.
- **Primary variant** gets a **subtle inner highlight**: a 1px top-inner border at 12% white opacity to simulate a lit edge, plus `AppElevation.subtle`. This is the "tactile" effect the MVP lacks. Implement via a `Stack` with the button on top and a 1px `Container` at the top edge, inside the `ClipRRect`. Not CustomPaint.
- **Secondary variant** gets a 1px outline at 10% foreground opacity and no shadow.
- **Ghost variant** has no fill until hover, then fills to 6% foreground opacity.
- **Hover states** are mandatory on all three variants. Desktop users expect them. Use `MouseRegion` or the built-in Material 3 hover states — verify they trigger on desktop.
- **Loading state** is built in: a named parameter `isLoading: bool` that swaps the label for a 14px `CircularProgressIndicator` without changing button size. Eliminates the current pattern of wrapping buttons in custom loading logic.

No `ElevatedButton.styleFrom(...)` scattered across screens after this refactor. Every button in every screen uses `AppButton`.

### 12.4.4 Toggle System — `AppToggle`

Replace every `Switch` in the codebase (Skills screen is the most visible offender) with `AppToggle`, defined in `lib/core/widgets/app_toggle.dart`. Specification:

- **Compact desktop size:** `36×20px` track, `16px` circular thumb with `AppElevation.subtle` shadow. Roughly half the size of Material's default.
- **Track colors:** off-state is surface at +4% luminance with a 1px outline at 10% foreground opacity. On-state is primary color at 85% saturation (not full primary — see Defect #3).
- **Animation:** 150ms ease-out thumb slide. No spring physics.
- **Label slot:** optional `label` and `description` parameters that render a two-line label to the left of the toggle. This is the standard Skills-screen row shape.
- **Implementation:** compose from `GestureDetector` + `AnimatedContainer` + `AnimatedAlign`. Do **not** subclass `Switch`. Do **not** use a third-party package.

After this refactor, grep for `Switch(` in `lib/features/` must return zero matches outside of `AppToggle`'s own file.

### 12.4.5 Card System — `AppCard`

Create `lib/core/widgets/app_card.dart`. One widget, one radius (`AppRadii.md` / 12px), one elevation level (`AppElevation.none` by default, `AppElevation.subtle` on hover when interactive). Background is surface color with a 1px border at 6% foreground opacity. All current raw `Card()` widgets in the feature layer are migrated to `AppCard`.

---

## 12.5 Defect #3 — Harsh Color Palette & Contrast

### 12.5.1 Architectural Diagnosis

The current palette has two problems that compound:

1. **Status colors are saturated primaries at 100%.** Full `#00C853` green and `#FF1744` red on a dark grey surface read as neon warning lights. Premium apps don't communicate status by shouting. They communicate status by **tinting backgrounds** with a low-opacity hue and letting the text carry meaning at a dimmer, readable intensity.
2. **The brand purple is being used as both an accent and a large-surface background.** Painted across entire button faces at full saturation, it vibrates against the dark grey scaffold. The purple is fine as a 20×20px logo dot, as button text, as a focus ring. It is not fine as a 300×48px solid button face on every primary action.

This isn't a color-values problem. It's a **color-role problem**. The palette needs roles, and each role needs a distinct token.

### 12.5.2 Strategy — Semantic Color Roles

Refactor `lib/core/theme/app_colors.dart` to define **role-based semantic tokens**, not raw color constants. The widget layer never references a raw hex value directly. It references a role.

**Required roles (minimum):**

| Role | Purpose | Dark Theme Spec (reference values) |
|---|---|---|
| `surfaceBase` | App scaffold background | `#0E0E10` — near-black with a hint of warmth |
| `surfaceRaised` | Cards, panels | `#17171A` |
| `surfaceOverlay` | Dialogs, popovers | `#1E1E22` |
| `borderSubtle` | 1px dividers, card outlines | white @ 6% opacity |
| `borderStrong` | Focus rings, emphasized borders | white @ 14% opacity |
| `textPrimary` | Body, headings | white @ 92% opacity |
| `textSecondary` | Labels, metadata | white @ 64% opacity |
| `textTertiary` | Disabled, placeholder | white @ 38% opacity |
| `brandPrimary` | Primary CTAs, focus, active states | the current purple, **desaturated by 15%** |
| `brandPrimaryMuted` | Button backgrounds (see below) | `brandPrimary` at 88% lightness, 70% saturation |
| `statusSuccessBg` | Success toast/banner background | success hue at 12% opacity |
| `statusSuccessFg` | Success text/icon | success hue at 85% saturation, 70% lightness |
| `statusSuccessBorder` | Success card border | success hue at 24% opacity |
| `statusErrorBg`/`Fg`/`Border` | Same pattern, error hue | Mirror the success triad |
| `statusWarnBg`/`Fg`/`Border` | Same pattern, warn hue | Mirror |
| `statusInfoBg`/`Fg`/`Border` | Same pattern, info hue | Mirror |

Light theme mirrors the same role names with inverted luminance. Widgets switch themes without touching their color logic because they reference roles.

### 12.5.3 Primary Button Color Correction

The primary button is the single most visible surface where the purple problem manifests. Fix rule:

- Primary button **fill** is `brandPrimaryMuted`, **not** raw `brandPrimary`.
- Primary button **inner top highlight** (from Section 12.4.3) is `brandPrimary` at 20% opacity — the brighter variant used as an accent on the muted base, which creates the "lit from above" tactile effect at zero shadow cost.
- Primary button **focus ring** is `brandPrimary` at 40% opacity, 2px offset, `AppRadii.sm + 2px`.

This single correction removes the jarring purple-on-dark vibration without losing brand recognition.

### 12.5.4 Status Components — `AppStatusCard`

Create `lib/core/widgets/app_status_card.dart`. One widget, four variants via `AppStatusVariant` enum: `success`, `error`, `warning`, `info`. Each variant composes:

- Background: `statusXxxBg` (12% opacity tint of the hue).
- Border: 1px `statusXxxBorder`.
- Icon: 16px Material icon in `statusXxxFg`.
- Title + body text in `textPrimary` and `textSecondary` respectively — **not** in the status foreground color. The status hue is the wash; the text is the message.
- Radius: `AppRadii.md`. Padding: `AppSpacing[16]`.

Every place in the current codebase that uses a raw `Container` with a neon green border for a success state, or a red `SnackBar` for an error, is migrated to `AppStatusCard`. API-key verification success indicators, delegation-failure banners, license-activation confirmations, save-state indicators — all of them.

---

## 12.6 Defect #4 — Generic Iconography & Visual Hierarchy

### 12.6.1 Architectural Diagnosis

The Use Case onboarding screen currently renders Material `Icons.code`, `Icons.search`, `Icons.edit`, etc. at `Icons.size` ~24px inside a square dark container with 8px padding. This is objectively cheap and it is **explicitly contrary to the spec.** `CLAUDE.MD` Section 2.4 shows the `assets/images/onboarding/` directory was designed from day one to hold illustrated SVGs:

```
assets/images/onboarding/
    ├── coding.svg
    ├── research.svg
    ├── writing.svg
    ├── building.svg
    └── general.svg
```

The current implementation ignores this directory entirely. The root cause is that the junior implementation treated Section 9 Phase 2's emoji preview (🖥️, 🔬, ✍️, 🏗️, 🌐) as the final design instead of as placeholder shorthand for the real illustrated SVGs. This is a spec-reading failure, not a design failure.

The "All Set" success screen has a parallel problem: a full-width, Material-default `Icons.check_circle` in saturated green, rendered at ~120px. It reads as a template graphic pulled from a Bootstrap tutorial.

### 12.6.2 Strategy — Illustrated Asset Pipeline

1. **Add `flutter_svg` to `pubspec.yaml`.** This is the single permitted dependency addition in Phase 12. It is required because Flutter has no native SVG renderer and the spec requires SVG assets.
2. **Supply the five SVG files** to `assets/images/onboarding/` (filenames exactly as listed in `CLAUDE.MD` Section 2.4). The designer/user provides these; Sonnet does not generate SVG content. Sonnet wires them in.
3. **Update `pubspec.yaml` assets section** to include `assets/images/onboarding/`.
4. **Rewrite `UseCaseCard`** (`lib/features/onboarding/presentation/widgets/use_case_card.dart`) to render via `SvgPicture.asset` at `96×96px`, **no dark container box around the illustration**. The illustration sits directly on the card surface with appropriate padding.
5. **Card structure:** 96px illustration on top, 16px gap, 16px semibold title, 4px gap, 13px secondary-color description. Centered. Card uses `AppCard` with `AppRadii.md`.
6. **Selection state:** 2px `brandPrimary`-at-40%-opacity border when selected. No scale transform. No color fill change on the card. The illustration itself does not change color on select — this keeps the illustration feeling like art, not a state indicator.

### 12.6.3 Success State — `AppSuccessGraphic`

Replace the generic `Icons.check_circle` on the "All Set" screen with a composed widget, `lib/core/widgets/app_success_graphic.dart`:

- **Composition:** a 96px circle using `AppCard`-style surface with a subtle 1px `brandPrimary @ 20%` ring. Inside, a 40px Material checkmark icon in `brandPrimary` (not `statusSuccessFg` — success state in onboarding is celebratory, not informational).
- **Entrance animation:** the ring scales from `0.9 → 1.0` over 300ms ease-out with opacity `0 → 1`. The check draws in after the ring settles via a 200ms `AnimatedOpacity`. Use `AnimatedContainer` + `AnimatedOpacity` only — per Section 4.4, no `AnimationController` is permitted without explicit approval.
- **No confetti. No particles. No sparkles.** The composition is quiet and confident. This is Claude Desktop, not Duolingo.

### 12.6.4 Icon Sizing & Container Policy — Global

- **No Material icon is ever rendered inside a dark square container on a card.** That was the anti-pattern on the use-case screen. It's banned app-wide.
- **Icon sizing ladder:** `14, 16, 20, 24, 32`. No other icon sizes anywhere in the codebase.
- **Action icons in buttons:** 16px. **Status icons in status cards:** 16px. **Menu icons in sidebars:** 20px. **Hero icons in empty states:** 32px maximum as a Material icon; anything larger than 32px must be an illustrated SVG, not a Material icon scaled up.

---

## 12.7 Defect #5 — Error Presentation Violation

### 12.7.1 Architectural Diagnosis

The error screenshot dumping 40 lines of raw Google API JSON directly into the UI is a **direct, documented violation of `CLAUDE.MD` Section 8.4**:

> *"Never show raw exception messages, stack traces, or HTTP status codes to users."*

The root cause is that the current `try/catch` blocks in `ApiClientService` and the chat screen are catching exceptions and rendering `e.toString()` into a `Text` widget. This is the single laziest error-handling pattern in Flutter and it has to be eliminated systematically, not patched case-by-case.

There are three sub-problems bundled inside this one defect:

1. **No translation layer** between raw HTTP/JSON errors and human-readable messages.
2. **No component architecture** for displaying errors — each screen invents its own error UI inline.
3. **No mechanism to preserve technical details** for power users without leaking them into the default view. A power user investigating a 403 wants to see the raw JSON; a normal user wants the one-line explanation and the one-line action.

Section 8.4 already defines the three-part schema every user-facing error must have:
- **What happened** (plain English)
- **Why it likely happened** (the most common cause)
- **What to do** (a concrete action)

Phase 12 operationalizes this schema into a widget and a translator.

### 12.7.2 Strategy — Error Translation Layer

Create `lib/core/errors/user_facing_error.dart` defining an immutable `UserFacingError` model:

```
UserFacingError {
  String headline              // "What happened" — max 60 chars
  String explanation           // "Why it likely happened" — max 160 chars
  String actionLabel           // Button label, e.g. "Open API Key Settings"
  VoidCallback? onAction       // What the button does
  AppStatusVariant severity    // error | warning | info
  String? technicalDetails     // Sanitized raw JSON/message, nullable
}
```

Create `lib/core/errors/error_translator.dart` exposing a pure function:

```
UserFacingError translate(AppException exception)
```

This function is the **single place** in the codebase where an `AppException` subtype (defined in `CLAUDE.MD` Section 8.2) becomes a human message. Every exception class is mapped explicitly. Unknown exceptions get a generic-but-not-useless fallback (*"Something went wrong. If this keeps happening, restart Briluxforge."*). Status codes are **never** rendered — they are mapped to meaning. 401/403 → "Your API key was rejected." 429 → "You've hit your provider's rate limit." 5xx → "Your provider is having trouble on their end."

**Sanitization rule:** when populating `technicalDetails`, the translator runs the raw message through the same key-scrubbing function defined in Section 7.3 (`_sanitizeError`). API keys never make it into technical details, even behind a "Show more" fold.

### 12.7.3 Presentation — `AppErrorDisplay` Widget

Create `lib/core/widgets/app_error_display.dart`. One widget, one consistent shape, consumed everywhere an error renders. Composition:

- **Headline** (16px semibold, `textPrimary`).
- **Explanation** (13px, `textSecondary`).
- **Action button** (`AppButton.secondary`, 32px compact).
- **"View technical details" disclosure** at the bottom — only rendered when `technicalDetails != null`. A small ghost-styled toggle that expands an `AnimatedSize`-wrapped monospace code block with max-height `240px` and internal scroll. **This is the only place raw technical content is ever allowed to appear, and it is always collapsed by default.**

The code block inside the disclosure uses `JetBrains Mono` (already in the font stack per Section 4.6), renders `technicalDetails` as selectable text, and has a copy button in its top-right corner (same pattern as chat code blocks per Section 4.5). Users who want to paste a traceback into a support email can do so in one click.

The widget sits inside an `AppStatusCard` of the appropriate severity. The overflow from Defect #1 is no longer possible because the content is bounded and the internal code block has its own scroll.

### 12.7.4 Wiring — Chat & API Key Screens

- **`ChatScreen`**: when a message send fails, the failed message bubble is replaced (or followed) by an `AppErrorDisplay` inline — **not** a red-text JSON dump. User can tap the action button (*"Retry"* or *"Check API Key"*) and it routes to the relevant fix.
- **`ApiKeyScreen`**: verification failures render as an `AppErrorDisplay` directly under the provider's card, never as a toast or `SnackBar` dump.
- **License activation failures**, **onboarding failures**, **database errors**: same widget, same schema, same technical-details disclosure. One error presentation across the entire app.

After Phase 12, a grep for `e.toString()` inside widget files must return **zero matches** outside of `ErrorTranslator`.

---

## 12.8 Execution Order — Files in Exact Sequence

Sonnet executes in this order. Each step produces a complete file per the **SINGLE-FILE OUTPUT LAW**. Do not start step N+1 until step N compiles.

**Foundation (tokens and theme — build these first, they are the substrate):**

1. `lib/core/theme/app_tokens.dart` — `AppRadii`, `AppSpacing`, `AppElevation` immutable classes with `const` constructors.
2. `lib/core/theme/app_colors.dart` — **refactored** to expose semantic role tokens per Section 12.5.2. Old raw-color constants that leaked into feature code are removed.
3. `lib/core/theme/app_theme.dart` — **refactored** to consume `AppColors` roles, `AppTokens`, and to wire `FilledButtonThemeData`, `OutlinedButtonThemeData`, `CardTheme`, `DialogTheme`, `InputDecorationTheme`, `DividerTheme` so that raw Material widgets inherit our defaults. This is the safety net — even if a future screen slips in a bare `Card`, the theme catches it.

**Shared widget primitives (consumed by feature refactors):**

4. `lib/core/widgets/app_button.dart` — `AppButton` widget + `AppButtonVariant` enum per Section 12.4.3.
5. `lib/core/widgets/app_toggle.dart` — `AppToggle` widget per Section 12.4.4.
6. `lib/core/widgets/app_card.dart` — `AppCard` widget per Section 12.4.5.
7. `lib/core/widgets/app_status_card.dart` — `AppStatusCard` widget + `AppStatusVariant` enum per Section 12.5.4.
8. `lib/core/widgets/app_dialog.dart` — `AppDialog` widget + `showAppDialog()` helper per Section 12.3.3.
9. `lib/core/widgets/app_success_graphic.dart` — onboarding success composition per Section 12.6.3.

**Error layer:**

10. `lib/core/errors/user_facing_error.dart` — `UserFacingError` immutable model per Section 12.7.2.
11. `lib/core/errors/error_translator.dart` — pure translation function mapping every `AppException` subtype to a `UserFacingError`, with sanitization per Section 12.7.2.
12. `lib/core/widgets/app_error_display.dart` — `AppErrorDisplay` widget per Section 12.7.3.

**Asset pipeline:**

13. `pubspec.yaml` — add `flutter_svg` dependency and the `assets/images/onboarding/` assets declaration.
14. Place provided SVG files into `assets/images/onboarding/` (user supplies files; Sonnet verifies filenames match `CLAUDE.MD` Section 2.4 exactly).

**Feature-layer migrations (in dependency order):**

15. `lib/features/onboarding/presentation/widgets/use_case_card.dart` — **rewrite** to consume `SvgPicture.asset` and `AppCard` per Section 12.6.2.
16. `lib/features/onboarding/presentation/use_case_screen.dart` — **rewrite** to layout the refactored cards with proper desktop constraints (max content width 720px, centered, `AppSpacing` gaps).
17. The "All Set" onboarding success screen — **rewrite** to use `AppSuccessGraphic`.
18. `lib/features/skills/presentation/widgets/skill_toggle.dart` — **rewrite** to consume `AppToggle`. Remove every `Switch(...)` instance.
19. `lib/features/skills/presentation/widgets/skill_card.dart` — **rewrite** to consume `AppCard`.
20. `lib/features/skills/presentation/skills_screen.dart` — **audit** for default `Switch`, `Card`, `Container`-with-raw-color patterns and migrate.
21. `lib/features/api_keys/presentation/widgets/api_key_card.dart` and `key_status_indicator.dart` — **rewrite** to consume `AppCard`, `AppStatusCard`, `AppButton`. Verification success becomes an `AppStatusCard(success)`, failure becomes an `AppErrorDisplay`.
22. `lib/features/api_keys/presentation/api_key_screen.dart` — **audit** and migrate to shared primitives.
23. `lib/features/auth/presentation/login_screen.dart`, `signup_screen.dart` — **audit** and migrate buttons, inputs, and error displays.
24. `lib/features/chat/presentation/chat_screen.dart` — replace inline error rendering with `AppErrorDisplay`. Ensure the scroll view inside the main chat area is properly constrained so no message bubble causes overflow.
25. `lib/features/chat/presentation/widgets/message_bubble.dart` — when a bubble represents a failed message, render `AppErrorDisplay` in place of the assistant content block.
26. Every other screen (`settings_screen.dart`, `license_key_input_screen.dart`, `delegation_failure_dialog.dart`, `savings_tracker_widget.dart`) — audit pass. Every `ElevatedButton`, `FilledButton`, `Switch`, `Card`, `AlertDialog`, and raw error text is migrated. The audit is complete when `grep -rn "ElevatedButton\|AlertDialog\|Switch(" lib/features/` returns zero matches.

**Final sweep:**

27. `lib/core/widgets/` — add a `README.md` documenting every shared widget and its allowed usage, so future Sonnet executions don't reinvent them. This is the only markdown file in the `lib/` tree; its purpose is discoverability, not architecture (architecture stays in `CLAUDE.MD`).

---

## 12.9 Acceptance Criteria — Definition of Done

Phase 12 is complete when **every** item below is verifiable:

1. **Zero Flutter overflow errors** rendered at runtime across every screen at window sizes from 900×600 (minimum) to 1920×1080 (standard). Manually resize the window through this range on every screen. No yellow-and-black hatching ever appears.
2. **Grep for banned patterns returns zero matches** inside `lib/features/`:
   - `ElevatedButton` (use `AppButton.primary`)
   - `OutlinedButton(` (use `AppButton.secondary`)
   - `Switch(` (use `AppToggle`)
   - `AlertDialog` (use `AppDialog`)
   - `showDialog(` without `showAppDialog` helper
   - `e.toString()` inside widget files (use `ErrorTranslator`)
   - Hardcoded `Color(0xFF...)` constants (use `AppColors` roles)
   - `BorderRadius.circular(` with any value not from `AppRadii`
3. **All five use-case cards render illustrated SVGs at 96px**, not Material icons. The dark box container around each icon is gone.
4. **The "All Set" screen renders `AppSuccessGraphic`**, not `Icons.check_circle`.
5. **Every error path** — API key verification failure, chat send failure, license activation failure, database failure, auth failure — renders an `AppErrorDisplay` with the three-part schema (headline / explanation / action) and an optional collapsed technical-details disclosure. No raw JSON, no stack trace, no HTTP status code is visible in the default view on any screen.
6. **Primary buttons have the tactile highlight effect** (top inner 1px highlight at 12% white opacity + `AppElevation.subtle` shadow) and consume `brandPrimaryMuted`, not raw `brandPrimary`.
7. **Status colors use tinted-background / muted-text pattern.** A green success indicator has a 12%-opacity green background, a 24%-opacity border, and `textPrimary`/`textSecondary` text — not full-saturation green text on a black card.
8. **All corner radii come from `AppRadii`.** All spacing from `AppSpacing`. All elevation from `AppElevation`.
9. **`dart analyze` passes with zero warnings.** `dart format .` produces no diffs.
10. **No new dependencies** in `pubspec.yaml` beyond `flutter_svg`.
11. **All providers touched during Phase 12** use `@riverpod` codegen syntax. Zero legacy `StateNotifierProvider` / `ChangeNotifierProvider` / manual `Provider<T>((ref) => ...)` declarations introduced or left behind.
12. **Every shared widget is exercised at least once by the feature layer.** Unused primitives are a sign the refactor is incomplete, not a sign they aren't needed yet.

---

## 12.10 Prohibited Patterns — Do Not Ship Any of These

Explicit ban list for Phase 12. Each of these will fail review on sight:

- ❌ Any usage of `flutter_neumorphic`, `glassmorphism`, `animated_text_kit`, `flutter_animate`, `lottie`, `shimmer`, `confetti`, or any third-party UI effect package. We are building a workspace, not a landing page.
- ❌ Any custom `AnimationController`. All animation in this phase is implicit (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSize`, `AnimatedAlign`, `AnimatedSwitcher`), per `CLAUDE.MD` Section 4.4.
- ❌ Any use of `CustomPaint` outside the `AppSuccessGraphic` ring, if even there — prefer `Container` with `BoxDecoration.border` + `BorderRadius`.
- ❌ Any new `StatefulWidget` where a `ConsumerWidget` + `@riverpod` provider would suffice. Local ephemeral UI state (hover, expanded/collapsed disclosure) is the only legitimate use of `StatefulWidget` in this phase.
- ❌ Any `SnackBar` for error display. `SnackBar` is permitted only for transient non-error confirmations (*"Conversation deleted"*) and even then must be styled to match `AppStatusCard.info` visually.
- ❌ Any inline `TextStyle(fontSize: 14, ...)` construction. All text styles come from `Theme.of(context).textTheme` with the semantic aliases from Section 4.6.
- ❌ Any `EdgeInsets.only(top: 13, bottom: 17, ...)` with non-ladder values. The ladder is the whole point.
- ❌ Any native OS dialog package (`file_selector` excluded because it's an OS file picker, not a dialog styling package — but nothing else). `window_manager` custom dialogs, platform-channel-bridged native alerts, Cupertino dialogs on macOS — banned. We render our own dialogs in Flutter, consistently on all platforms. This is a defining feature of desktop apps that feel crafted rather than assembled.
- ❌ Any partial file output. Single-File Output Law is in force. If Sonnet is writing `app_button.dart`, the response contains the entire file from `import 'package:flutter/material.dart';` through the closing `}`. No "(... rest unchanged ...)". No "(add this method to the class)".
- ❌ Any feature addition. This phase is a structural correction. If a thought starts with "while I'm in here, I could also...", stop the thought.

---

## 12.11 Communication Protocol for This Phase

Per `CLAUDE.MD` Section 1.3, every response Sonnet produces during Phase 12 is prefixed with a one-line summary:

- `// FILE: lib/core/theme/app_tokens.dart`
- `// FILE: lib/core/widgets/app_button.dart`
- `// ACTION: pubspec.yaml dependency addition — flutter_svg`
- `// ACTION: run `dart run build_runner build --delete-conflicting-outputs``

When a file contains a `part '*.g.dart';` directive, Sonnet ends the response by reminding the user to run the codegen command. When a file is purely a widget or a pure-Dart utility with no `part`, no reminder is needed.

If Sonnet encounters something in an existing file that conflicts with Phase 12 — e.g., a provider currently written in legacy syntax that needs to be touched — **flag the conflict, then fix it in the same response using the current syntax rules.** Do not leave legacy syntax in place "because that wasn't the scope of the task." The scope of the task is compliance with `CLAUDE.MD`, and legacy syntax violates it.

---

## Appendix A: Phase 12 File Inventory

**New files (17):**

```
lib/core/theme/app_tokens.dart
lib/core/widgets/app_button.dart
lib/core/widgets/app_toggle.dart
lib/core/widgets/app_card.dart
lib/core/widgets/app_status_card.dart
lib/core/widgets/app_dialog.dart
lib/core/widgets/app_success_graphic.dart
lib/core/widgets/app_error_display.dart
lib/core/widgets/README.md
lib/core/errors/user_facing_error.dart
lib/core/errors/error_translator.dart
assets/images/onboarding/coding.svg
assets/images/onboarding/research.svg
assets/images/onboarding/writing.svg
assets/images/onboarding/building.svg
assets/images/onboarding/general.svg
(… plus pubspec.yaml modification for flutter_svg + asset declaration)
```

**Files refactored (minimum — audit will surface more):**

```
lib/core/theme/app_colors.dart
lib/core/theme/app_theme.dart
lib/features/onboarding/presentation/use_case_screen.dart
lib/features/onboarding/presentation/widgets/use_case_card.dart
lib/features/onboarding/presentation/… (the "All Set" success screen)
lib/features/skills/presentation/skills_screen.dart
lib/features/skills/presentation/widgets/skill_card.dart
lib/features/skills/presentation/widgets/skill_toggle.dart
lib/features/api_keys/presentation/api_key_screen.dart
lib/features/api_keys/presentation/widgets/api_key_card.dart
lib/features/api_keys/presentation/widgets/key_status_indicator.dart
lib/features/auth/presentation/login_screen.dart
lib/features/auth/presentation/signup_screen.dart
lib/features/chat/presentation/chat_screen.dart
lib/features/chat/presentation/widgets/message_bubble.dart
lib/features/settings/presentation/settings_screen.dart
lib/features/licensing/presentation/widgets/license_status_banner.dart
lib/features/delegation/presentation/widgets/delegation_failure_dialog.dart
lib/features/savings/presentation/widgets/savings_tracker_widget.dart
pubspec.yaml
```

---

## Appendix B: Grep Self-Check Commands

Before declaring Phase 12 complete, run each of these from the project root. Each must print nothing from inside `lib/features/`:

```bash
grep -rn "ElevatedButton" lib/features/
grep -rn "OutlinedButton(" lib/features/
grep -rn "Switch(" lib/features/
grep -rn "AlertDialog" lib/features/
grep -rn "e\.toString()" lib/features/
grep -rn "Color(0xFF" lib/features/
grep -rn "BorderRadius\.circular(" lib/features/ | grep -v "AppRadii"
grep -rn "StateNotifierProvider\|ChangeNotifierProvider" lib/
grep -rn "showCupertinoDialog\|CupertinoAlertDialog" lib/
```

Any hit is a Phase 12 regression and must be fixed before Phase 10 (Build, Obfuscate, Package) begins.

---

*End of PHASE_12.MD. Sonnet: the work described in this document is the difference between a product that demos well and a product that a user pays for. Build the tokens first. Build the primitives second. Migrate the features last. Do not skip ahead. Do not invent. Every file complete, first import to closing brace.*
