# SB Consultants — Visa Consultancy App

> **Your Trusted Visa Partner**

A professional visa consultancy application built with Flutter, featuring Supabase authentication, OTP verification, and a modern Material 3 design.

---

## 📱 Screenshots & Features

### Authentication
- **Login** — Email/password with "Remember me" and social login buttons (Google, Facebook, Apple)
- **Sign Up** — Full Name, Email, Phone Number, Password with confirm
- **OTP Verification** — 6-digit code sent to email, 60s countdown timer, resend support
- **Forgot Password** — Email-based password reset with OTP verification

### Home & Visa Services (🚧 Coming Soon)
- Banner carousel with promotions
- 6 visa category tabs: Study, Immigration, Visit, Work, Tourist, Business
- Top consultants listing
- Application form & payment flow
- Appointment tracking with status (Paid → Under Review → Approved)

### Planned Features
- Live chat with consultants (Supabase Realtime)
- Settings & profile management
- Admin dashboard (Flutter Web)
- Payment integration

---

## 🏗️ Architecture

**MVVM** with Riverpod state management:

```
lib/src/
├── config/          # AppConfig (Supabase + Dio init)
├── data/
│   ├── models/      # AppUser, etc.
│   └── repositories/# Abstract contracts + Supabase implementations
├── imports/         # Barrel exports (core_imports, packages_imports)
├── middleware/      # Dio interceptors, route observer
├── routing/         # GoRouter config, route constants
├── services/        # AuthService, SupabaseDatabaseService, etc.
├── shared/
│   ├── app_assets.dart
│   ├── extensions/
│   ├── helpers/
│   ├── widgets/     # 40+ App* reusable widgets
│   └── wrappers/    # Session, localization, skeleton wrappers
├── theme/           # color_schemes, text_theme, theme.dart
├── ui/
│   ├── auth/        # Login, Signup, ForgotPassword, OTP screens + providers
│   ├── home/        # HomePage
│   ├── onboarding/  # OnboardingPage
│   └── splash/      # SplashScreen
└── utils/           # Logger, error_handler, failure, typedefs
```

---

## 🛠️ Tech Stack

| Area | Technology |
|------|-----------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| Architecture | MVVM |
| State Management | Riverpod (manual providers) |
| Navigation | GoRouter |
| Auth Backend | Supabase (authentication only) |
| HTTP Client | Dio |
| Font | Poppins (Regular, Medium, SemiBold, Bold) |
| Theme | Material 3, seed color `#1B3A5C` (navy blue) |
| Localization | easy_localization (English) |
| Responsive | flutter_screenutil (390×844 base) |
| Storage | SharedPreferences + flutter_secure_storage |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.22
- Dart SDK ≥ 3.4
- A Supabase project ([supabase.com](https://supabase.com))

### Setup

1. **Clone & install dependencies**
   ```bash
   git clone <repo-url>
   cd flutter_sd_consultant
   flutter pub get
   ```

2. **Create `.env` file** in project root:
   ```env
   SUPABASE_URL=https://YOUR-PROJECT-ID.supabase.co
   SUPABASE_ANON_KEY=YOUR-ANON-KEY-HERE
   API_BASE_URL=https://YOUR-PROJECT-ID.supabase.co
   ```
   Get your keys from: Supabase Dashboard → Settings → API

3. **Enable Email Auth in Supabase:**
   - Dashboard → Authentication → Providers → Email → Enable
   - (Optional) Disable "Confirm email" for faster testing

4. **Generate native splash:**
   ```bash
   dart run flutter_native_splash:create
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

### Checking Supabase Users
After signup, verify users at: **Supabase Dashboard → Authentication → Users**

---

## 📁 Key Files

### Auth Flow
| File | Purpose |
|------|---------|
| `lib/src/services/auth_service.dart` | Supabase auth calls (login, signup, OTP, forgot password) |
| `lib/src/data/repositories/auth_repository.dart` | Abstract auth contract |
| `lib/src/data/repositories/auth_repository_impl.dart` | Supabase auth implementation |
| `lib/src/ui/auth/providers/auth_provider.dart` | AuthController (StateNotifier) |
| `lib/src/ui/auth/providers/session_provider.dart` | SessionNotifier (sealed SessionState) |

### Screens
| File | Purpose |
|------|---------|
| `lib/src/ui/splash/splash_screen.dart` | Animated splash with logo |
| `lib/src/ui/auth/login_screen.dart` | Email + password login |
| `lib/src/ui/auth/signup_screen.dart` | Registration with phone number |
| `lib/src/ui/auth/otp_verification_screen.dart` | 6-digit OTP verification |
| `lib/src/ui/auth/forgot_password_screen.dart` | Password reset flow |

### Config
| File | Purpose |
|------|---------|
| `.env` | Supabase URL + anon key (NOT committed) |
| `lib/src/config/app_config.dart` | Supabase + Dio initialization |
| `lib/src/routing/app_router.dart` | All GoRouter routes |
| `lib/src/routing/app_routes.dart` | Route path constants |
| `flutter_native_splash.yaml` | Native splash config (navy blue + logo) |

---

## 🔐 Auth Flow

```
User opens app
  → Native splash (navy blue + logo)
  → SessionListenerWrapper checks auth state
  → If unauthenticated → Onboarding → Login/Signup
  → On Signup: enter name, email, phone, password → OTP sent to email
  → OTP Verification (6-digit code, 60s timer, resend)
  → On success → Home screen
  → On Login: email + password → Home screen
  → On Forgot Password: email → OTP sent → verify → reset
```

---

## 🎨 Brand Guidelines

- **Logo:** `assets/images/logo.jpg` — Navy blue passport/globe/airplane motif
- **Primary color:** `#1B3A5C` (dark navy)
- **Font:** Poppins (all weights)
- **App title:** "SB Consultants"
- **Tagline:** "Your Trusted Visa Partner"
- Always show logo on auth screens (Login: 100h, others: 80h)
- Use `cs.primary` for brand-colored text, never hardcode hex

---

## 📋 Remaining Work

See [CLAUDE.md](CLAUDE.md) for coding conventions and [DESIGN.md](DESIGN.md) for UI tokens.

### Phase 1: Home & Visa Flow
- [ ] Bottom navigation shell (Home, Favorites, Appointments, Chat, Settings)
- [ ] Home screen (banner carousel, visa categories, top consultants)
- [ ] Visa category screen
- [ ] Visa application form
- [ ] Consultant profile screen

### Phase 2: Payment & Tracking
- [ ] Payment integration (Paymob/bank transfer)
- [ ] Appointment tracking with status timeline
- [ ] Payment confirmation screen

### Phase 3: Communication
- [ ] Live chat (Supabase Realtime)
- [ ] Push notifications

### Phase 4: Admin
- [ ] Admin dashboard (Flutter Web)
- [ ] Application approval workflow
- [ ] User management

---

## 🧪 Verification

```bash
flutter pub get
flutter analyze       # Should show 0 errors
flutter test          # Run tests
```

No `build_runner` step required for the current stack.

---

## 📄 License

Private — SB Consultants. All rights reserved.