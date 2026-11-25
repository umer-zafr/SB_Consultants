# Design system — SB Consultants (flutter_sd_consultant)

This file documents the design conventions for the SB Consultants visa consultancy app. Consult it before changing UI code.

---

## Theme overview

- **Brand:** SB Consultants — "Your Trusted Visa Partner"
- **Preset:** `material3`
- **Material 3:** Primary app chrome uses Material 3 theming in `lib/src/theme/theme.dart`.
- **Dark mode:** Light and dark themes are supported; app can follow system brightness. Use semantic colors — do not branch on brightness in widgets for basic surfaces.
- **Customization:** Global `ThemeData` lives in `lib/src/theme/theme.dart` — avoid one-off `ThemeData` overrides in feature widgets.

- **Seed color:** `#1B3A5C` (navy blue — derived from company logo).

### Brand color palette

| Role | Hex | Usage |
|------|-----|-------|
| Primary (navy) | `#1B3A5C` | Seed color, buttons, primary text, app bar accents |
| Secondary (steel blue) | `#5B7FA5` | Secondary actions, icons, card borders |
| Tertiary (light blue-gray) | `#A8C4D9` | Backgrounds, containers, subtle accents |
| Surface | theme-derived | Scaffold/card backgrounds |
| Error | `#BA1A1A` | Error states, validation |

> **Note:** All colors are derived via `ColorScheme.fromSeed(seedColor: #1B3A5C)`. Do not hardcode hex values in widgets — use `context.colors.primary`, etc.

---

## Typography

- **Font family:** `Poppins` (loaded from `assets/fonts/`)
- Weights: Regular (400), Medium (500), SemiBold (600), Bold (700)
- Use `context.textTheme` (alias `context.typography`) for all text styles.
- Roles follow Material 3: `display*`, `headline*`, `title*`, `body*`, `label*`.
- All text styles in `lib/src/theme/text_theme.dart` use `fontFamily: 'Poppins'`.

### Key font sizes (real-app reference)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `headlineMedium` | 28sp | Bold (w700) | Screen titles ("Welcome Back", "Create Account") |
| `headlineSmall` | 24sp | Bold | Brand name under logo |
| `titleMedium` | 16sp | Medium (w500) | AppBar titles, section headings |
| `bodyLarge` | 16sp | Regular | Highlighted email, important text |
| `bodyMedium` | 14sp | Regular | Subtitles, descriptions, form labels |
| `bodySmall` | 12sp | Regular | "Remember me", secondary actions |
| `labelLarge` | 14sp | Medium | Button text, "Resend", links |


---

## Spacing, borders, motion

Import tokens via `package:flutter_sd_consultant/src/theme/theme_constants.dart`.

| Token class | Purpose |
|-------------|---------|
| `AppSpacing` | Padding, gaps (`xxs` … `xxxl`, plus `pagePadding`, `itemGap`, `cardPadding`) |
| `AppBorders` | Border radii (`xs` … `xl`, `button`, `card`, `input`, `dialog`, …) |
| `AppShadows` | Elevation shadows (`none`, `subtle`, `card`, `elevated`, `modal`) |
| `AppDurations` | Animation durations (`fast`, `normal`, `medium`, `slow`, …) |
| `AppCurves` | Standard curves (`standard`, `emphasized`, `pageEnter`, …) |

**Rules**

- Do not use magic numbers for padding — use `AppSpacing`.
- Do not use inline `BorderRadius.circular(n)` — use `AppBorders`.
- Prefer Material 3 tonal elevation on `Card` / `Surface` — custom shadows only via `AppShadows`.

---

## Responsive scaling (ScreenUtil)

- `ScreenUtilInit` is already applied in the app wrapper — do not add another.
- Design size baseline: **390×844** (iPhone 14 class).
- In templates and new code, use the `res` convention: widths `.w`, heights `.h`, radius `.r`, font sizes `.sp` when ScreenUtil is enabled.
- ScreenUtil values are runtime — avoid `const` widgets that depend on `.w` / `.sp`.

---

## Context extensions

Defined in `lib/src/extensions/context_extension.dart`:

| Member | Use |
|--------|-----|
| `context.colors` | `ColorScheme` |
| `context.textTheme` / `context.typography` | Text styles |
| `context.appColors` | Semantic success/warning/info |
| `context.designTokens` | Theme extension tokens |
| `context.isDarkMode` | Brightness check |
| `context.width` / `context.height` | Screen size |
| `context.showAppDialog` | Dialog helper |
| `context.showTypedSnackBar` | Status snackbars |

Prefer these shortcuts over repeating `Theme.of(context)` in widgets.

---

## Component conventions

- Reusable widgets belong in `lib/src/shared/widgets/`.
- Default style parameters to theme values, not hardcoded colors.
- Widget file names match the widget class (`primary_button.dart` → `PrimaryButton`).
- Do not read theme inside `const` constructors.

### Dark mode checklist

- No raw `Colors.white` / `Colors.black` for surfaces — use `colorScheme` roles.
- Verify new screens in both light and dark theme.

---

## Localization

- User-visible strings use `easy_localization` — files in `assets/translations/`.
- Do not hardcode display strings in widgets.
- Add keys to JSON translation files, then run the generate command in **SETUP.md**.
- Use interpolation in JSON — do not concatenate translated strings in Dart.

---

## Do / Don't

**Do**

- `context.colors` / `context.appColors` for color
- `context.textTheme` for typography
- `AppSpacing`, `AppBorders`, `AppShadows`, `AppDurations`, `AppCurves` for layout and motion
- `showAppDialog` and shared widgets for consistent UX

---

## UI component library

Product widgets live under `lib/src/shared/widgets/ui/`.

### Platform style

- Config: `adaptive` (adaptive | material | cupertino)
- Runtime: wrap with `AppPlatformScope`; override per widget via `platform:`
- Helper: `context.isCupertinoUi` / `context.resolveCupertinoUi(platform)`
- Prefer **App\*** widgets over raw `ElevatedButton` / `TextField` / `CupertinoButton`

### App kit (`ui/app/`) — always generated

| Category | Widgets |
|---|---|
| actions | `AppButton`, `AppIconButton`, `AppTextButton`, `AppFab`, `AppSegmentedControl`, `AppToggleGroup`, `AppChip` |
| inputs | `AppTextField`, `AppSearchField`, `AppPasswordField`, `AppTextArea`, `AppOtpField`, `AppCheckbox`, `AppRadio`, `AppSwitch`, `AppSlider`, `AppNumberStepper`, `AppDropdown`, `AppDatePicker`, `AppTimePicker`, `AppRating`, `AppForm` |
| display | `AppCard`, `AppAvatar`, `AppBadge`, `AppListTile`, `AppDivider`, `AppIcon`, `CommonImage`, `AppProgressBar`, `AppCircularProgress`, `AppSkeleton`, `AppTooltip`, `AppExpansionPanel`, `AppTimeline`, `AppDataTable` |
| feedback | `AppLoading`, `AppErrorWidget`, `AppEmptyState`, dialogs/sheets/banner/snack + toast |
| navigation | `AppScaffold`, `AppTopBar`, `AppBottomNavBar`, `AppTabBar`, `AppNavigationDrawer`, `AppPageIndicator` |
| layout | `AppGap`, `AppResponsiveBuilder`, `AppSection` |

Debug gallery: `AppRoutes.uiShowcase` (`/debug/ui-showcase`) in debug builds.

### Design tokens (required)

```dart
AppSpacing.md
AppBorders.card
AppShadows.elevated
AppDurations.normal
AppCurves.standard
context.colors.primary
context.appColors.success
context.textTheme.titleMedium
context.designTokens.paddingMedium
```

**Never** hardcode hex colors or magic spacing numbers in feature UI.

### shadcn kit

Not enabled for this project. Re-generate with shadcn opted in from the UI & Theme step to add `ShadApp` wrappers.

---

**Don't**

- Hardcode hex colors or arbitrary font families in widgets
- Magic padding/radius numbers
- Duplicate theme definitions per screen
- Bypass design tokens for one-off “quick” UI

For agent workflows and architecture boundaries, see **[AGENTS.md](AGENTS.md)**.
