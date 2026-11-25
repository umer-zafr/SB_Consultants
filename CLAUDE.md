# Claude Code guide — SB Consultants (flutter_sd_consultant)

This file is the project brief for Claude Code. Prefer it alongside **[AGENTS.md](AGENTS.md)** (same stack rules) and **[DESIGN.md](DESIGN.md)** (UI tokens).

## Project

**SB Consultants** (`flutter_sd_consultant`) — A production-ready visa consultancy Flutter application.

- **Brand:** SB Consultants — "Your Trusted Visa Partner"
- **Logo:** `assets/images/logo.jpg` (navy blue passport/globe/plane motif)
- **Package:** `com.example.flutter_sd_consultant`

### Stack

| Area | Choice |
|------|--------|
| Architecture | `mvvm` |
| State management | `riverpod` (manual providers, NOT riverpod_generator) |
| Navigation | `go_router` |
| Backend (Auth) | `supabase` (authentication ONLY) |
| Networking | Dio |
| Local storage | SharedPreferences, Secure storage |
| Theme preset | `material3` |
| Seed color | `#1B3A5C` (navy blue) |
| Font family | Poppins (Regular, Medium, SemiBold, Bold) |
| Dark mode | enabled (follows system) |
| ScreenUtil | yes |
| Localization | `easy_localization` (en) |
| Flutter Hooks | disabled |
| Dotenv | enabled |


---

## Architecture (`mvvm`)




```text
lib/src/
├── ui/             # screens, widgets, state (riverpod)
├── data/           # models, repository impls
├── routing/
├── services/
└── theme/
```

**Rules**

- UI layer binds to view models / providers / controllers under `ui/`.
- Data access goes through repositories in `data/` or `services/`.
- No business logic in widget `build()` methods.


## Dart growth patterns (all architectures)

- **Sealed types** for variants: `Failure`, `SessionState`, `RequestState<T>`, auth events/states. Prefer exhaustive `switch` over `if (x is Y)`.
- **Abstract contracts + `implements`**: repositories and datasources hide services/SDKs.
- **Generics**: `FutureEither<T>`, `RequestState<T>`, `UseCase<Params, Result>`.
- **Mixins**: `StreamSubscriptionsMixin` for cancelling stream listeners in notifiers/blocs.
- **Factories**: `AppUser.fromJson` / `Failure.fromException` / `UserModel.toEntity()`.
- **Records**: use for small param bundles (e.g. `LoginParams = ({String email, String password})`).
- Do **not** add Freezed unless the user opts in — language sealed classes are the default.

---

## State management (riverpod)

### Shared rules (all stacks)

- Model async UI with `RequestState<T>` (`RequestInitial` / `RequestLoading` / `RequestSuccess` / `RequestFailure`) — not raw booleans.
- Model session with sealed `SessionState` (`SessionUnknown` / `SessionAuthenticated` / `SessionUnauthenticated`) and exhaustive `switch`.
- Prefer pattern matching in listeners and screens; keep side effects (navigation, toasts) outside pure rebuild paths.
- Cancel stream subscriptions via `StreamSubscriptionsMixin`.

- Use `ConsumerWidget` / `ConsumerStatefulWidget` where reactive state is needed.
- Providers live next to features (see overlay paths under `presentation/providers/` or equivalent).
- `ref.watch` inside `build()`; `ref.read` inside callbacks and one-off actions — never `ref.read` in `build()`.
- Auth actions use `StateNotifier<RequestState<void>>` — watch `.isLoading`, not a bare `bool`.
- Do not nest a second `ProviderScope` — one at app root is already configured.
- This project does **not** use `@riverpod` / `riverpod_generator` — define providers manually.






---

## Navigation

- All routes are defined in `lib/src/routing/app_router.dart` — do not scatter route tables elsewhere.
- Prefer typed/named routes from the central config — avoid hard-coded path strings in widgets when a named route exists.
- `context.go()` replaces the stack; `context.push()` pushes on top.
- Redirects and guards belong in the router configuration, not inside individual screens.




---

## Backend (supabase)


- All Supabase calls go through services/repositories — not from UI.
- Assume Row Level Security on tables — never bypass RLS in client code.
- Session persistence is handled by the SDK — avoid manual token caching.
- Configure URL and anon key via `.env` / **SETUP.md** when `usesDotenv` is enabled.



For console setup (keys, native files, env), follow **[SETUP.md](SETUP.md)** — do not duplicate platform steps here.

---

## Networking

- Use the shared `Dio` instance from `lib/src/config/app_config.dart` — never `Dio()` inside a widget or screen.
- Extend or use existing services under `lib/src/services/` for HTTP calls.
- Map transport errors to `Failure` / `FutureEither` results via `runTask()` — do not leak raw `DioException` to UI.



---

## Services & shared conventions

- Services are singletons with `ClassName.instance`, returning `FutureEither<T>` via `runTask()`.
- Never pass `BuildContext` into services — use `rootContext` from the global navigator helper when UI is required.
- Logging: `AppLogger`; user feedback: `showGlobalToast()`; dialogs: `showAppDialog()` / `context.showAppDialog()`.
- Primary import barrel: `package:flutter_sd_consultant/src/imports/imports.dart`.
- File names: `snake_case.dart`; classes: `PascalCase`; private members: `_camelCase`.
- Prefer `const` constructors where possible; avoid `dynamic` without justification.
- No empty `catch` blocks — log, map to failure, or rethrow.
- Do not add packages that duplicate existing stack choices (routing, state, backend).

### Dart / Flutter anti-patterns

- No business logic in widget `build()` methods.
- No direct backend or network calls from presentation widgets.
- Do not use `ref.read` inside `build()`.





---

## Key packages

- `go_router` — declarative routing


- `flutter_riverpod` — state management




- `supabase_flutter`

- `dio`


- `shared_preferences`
- `flutter_secure_storage`
- `cached_network_image`

- `image_picker`
- `file_picker`
- `easy_localization`
- `flutter_screenutil`

- `flutter_dotenv`
- `skeletonizer`


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

## How to add a new screen and navigate

Follow these 5 exact steps whenever you create a new screen in this project:

### Step 1: Define the route constant in `lib/src/routing/app_routes.dart`
Add your new route path constant to `AppRoutes`:
```dart
abstract final class AppRoutes {
  ...
  static const String visaCategories = '/visa-categories';
  static const String visaDetail = '/visa-detail';
}
```

### Step 2: Create the Screen Widget under `lib/src/ui/<feature>/`
Create your screen file (e.g. `lib/src/ui/visa/visa_categories_screen.dart`):
```dart
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';
import 'package:flutter_sd_consultant/src/imports/packages_imports.dart';

class VisaCategoriesScreen extends ConsumerWidget {
  const VisaCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      appBar: const AppTopBar(title: 'Visa Categories'),
      body: SafeArea(
        child: Center(
          child: Text('Visa Categories Content', style: tt.bodyLarge),
        ),
      ),
    );
  }
}
```

### Step 3: Register the route in `lib/src/routing/app_router.dart`
Import your screen and add a `GoRoute` inside `routes: <RouteBase>[...]`:
```dart
GoRoute(
  path: AppRoutes.visaCategories,
  name: 'visaCategories',
  builder: (context, state) => const VisaCategoriesScreen(),
),
```
*If your screen takes parameters (e.g., ID or query parameter):*
```dart
GoRoute(
  path: AppRoutes.visaDetail,
  name: 'visaDetail',
  builder: (context, state) {
    final visaId = state.uri.queryParameters['id'] ?? '';
    return VisaDetailScreen(visaId: visaId);
  },
),
```

### Step 4: Export your screen in `lib/src/imports/core_imports.dart`
Add the export so other files can import it cleanly:
```dart
export '../ui/visa/visa_categories_screen.dart';
```

### Step 5: Navigate to your new screen from anywhere
From any button or onTap callback:
- **Push on top of current stack** (allows back button):
  ```dart
  context.push(AppRoutes.visaCategories);
  ```
- **Replace current screen** (no back button, e.g. after login):
  ```dart
  context.go(AppRoutes.home);
  ```
- **Navigate with parameters:**
  ```dart
  context.push('${AppRoutes.visaDetail}?id=$categoryVisaId');
  ```
- **Go back:**
  ```dart
  context.pop();
  ```



---

## Safe to modify

| Path | Guidance |
|------|----------|


| `lib/src/ui/**`, `lib/src/data/**` | UI and data layer for your features |

| `lib/src/shared/widgets/**` | Reusable UI components |
| `lib/src/shared/helpers/**` | App-wide helpers (when not generated-only) |
| `test/**` | Unit and widget tests |
| `README.md` | Project documentation |

## Modify with caution

| Path | Why |
|------|-----|
| `lib/src/routing/app_router.dart` | Central navigation — breaks deep links if wrong |
| `lib/main.dart` | Initialization order (Firebase, dotenv, localization, flavors) |
| `lib/src/config/app_config.dart` | SDK and HTTP client setup |
| `lib/src/theme/**` | Global visual system |
| `lib/src/imports/**` | Barrel exports — keep pattern consistent |
| `pubspec.yaml` | Dependency graph for the whole app |
| `.env` | Secrets — never commit real values |

## Do not touch

| Path | Why |
|------|-----|
| `android/`, `ios/`, `web/`, desktop folders | Native project configuration |
| `.env` with real secrets | Security |


---

## Verification after changes

```bash
flutter pub get
flutter analyze
```

### Code generation

No `build_runner` step is required for the selected stack.

### Localization

After editing `assets/translations/*.json`:

```bash
flutter pub run easy_localization:generate -S assets/translations -O lib/src/core/i18n -o locale_keys.g.dart
```

```bash
flutter test
```

---

## Hard limits

- Do not disable `flutter_lints` rules without an explanatory comment.
- Do not call backend or networking code directly from widgets.
- Do not commit `.env` files containing production secrets.
- Do not introduce a second state-management or routing library.
- For platform setup and API keys, use **[SETUP.md](SETUP.md)**.
- For UI tokens and spacing, use **[DESIGN.md](DESIGN.md)**.
- Keep changes consistent with **[AGENTS.md](AGENTS.md)**.
