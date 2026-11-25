# 🎉 Welcome to SB Consultants (flutter_sd_consultant)!

This project is a visa consultancy app built with Flutter. Before running for the first time, follow this setup guide to configure environment variables, permissions, and dependencies.

---

## 1. 📱 Platform folders (web download only)

The web wizard ZIP does **not** include native runners (`android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`). Those are created only via the Flutter CLI.

Skip this step if you generated the project with the FlutterInit CLI (`flutter create` already ran).

From the project root:
```bash
flutter create . --project-name flutter_sd_consultant --org com.example
```

This adds the platform folders without overwriting your generated Dart sources.

---

## 2. 📦 Initial Dependencies & Generation

First, fetch all pub packages, then format the generated Dart (templates are not pre-formatted):
```bash
flutter pub get
dart format .
```

### Code Generation
*(No initial code generation required for your main stack)*

### Localization
Since you chose to include `easy_localization`, run these commands whenever you add or modify string translations to generate your keys correctly:
```bash
flutter pub run easy_localization:generate -S assets/translations -O lib/src/core/i18n -o locale_keys.g.dart
```

---

## 3. 🎨 Native Splash Screen Setup

This project uses `flutter_native_splash` with the SB Consultants navy blue branding.

**The splash is already configured** in [`flutter_native_splash.yaml`](flutter_native_splash.yaml):
```yaml
flutter_native_splash:
  color: "#1B3A5C"
  image: assets/images/logo.jpg
  android_12:
    image: assets/images/logo.jpg
    icon_background_color: "#1B3A5C"
```

**To apply the splash screen natively, run:**
```bash
dart run flutter_native_splash:create --path=flutter_native_splash.yaml
```
*Note: Run this command every time you change your splash image or background color.*

---

## 4. 🔐 App Permissions (Android & iOS)

Based on your chosen flags (e.g. Image Picker  , File Picker), you must configure Native permissions before testing these features.

### Android Setup
Open [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml) and add the following required permissions inside the `<manifest>` tag, directly above the `<application>` block:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet is standard and required -->
    <uses-permission android:name="android.permission.INTERNET" />
    
    <!-- Required for image_picker -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" /> <!-- Android 13+ -->
    <!-- Required for file_picker -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS Setup 
First, describe why you need permissions. Open [`ios/Runner/Info.plist`](ios/Runner/Info.plist) and add the following inside the main `<dict>` block:

```xml
<dict>
    ...
    <!-- Required for image_picker -->
    <key>NSCameraUsageDescription</key>
    <string>This app requires access to the camera to take profile photos.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app requires access to the photo library to upload images.</string>
    <!-- Required for file_picker -->
    <key>NSAppleMusicUsageDescription</key>
    <string>This app requires access to media to upload files.</string>
</dict>
```

**IMPORTANT: Podfile Configuration**
Since you've enabled `permission_handler`, you **MUST** configure your requested iOS permissions using Podfile macros to comply with App Store rules. 

Open [`ios/Podfile`](ios/Podfile), find the `post_install` block at the bottom, and replace it completely with this snippet:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',

        ## dart: PermissionGroup.camera
        'PERMISSION_CAMERA=1',

        ## dart: PermissionGroup.photos
        'PERMISSION_PHOTOS=1',

        ## dart: PermissionGroup.location
        'PERMISSION_LOCATION=0',
        'PERMISSION_LOCATION_WHENINUSE=0',

        ## dart: PermissionGroup.mediaLibrary
        'PERMISSION_MEDIA_LIBRARY=1',

        ## dart: PermissionGroup.microphone (Usually 1 if video recording is active with image_picker)
        'PERMISSION_MICROPHONE=1',

        ## Unused permissions forcefully disabled to avoid App Store Rejection
        'PERMISSION_EVENTS=0',
        'PERMISSION_EVENTS_FULL_ACCESS=0',
        'PERMISSION_REMINDERS=0',
        'PERMISSION_CONTACTS=0',
        'PERMISSION_SPEECH_RECOGNIZER=0',
        'PERMISSION_NOTIFICATIONS=0',
        'PERMISSION_SENSORS=0',
        'PERMISSION_BLUETOOTH=0',
        'PERMISSION_APP_TRACKING_TRANSPARENCY=0',
        'PERMISSION_CRITICAL_ALERTS=0',
        'PERMISSION_ASSISTANT=0',
      ]
    end
  end
end
```

---

## 5. 🌍 Environment Variables

Your project relies on `flutter_dotenv` to load secrets.

1. Create a [`.env`](.env) file in the project root folder (already created).
2. Add your Supabase credentials:
   ```env
   SUPABASE_URL=https://YOUR-PROJECT-ID.supabase.co
   SUPABASE_ANON_KEY=YOUR-ANON-KEY-HERE
   API_BASE_URL=https://YOUR-PROJECT-ID.supabase.co
   ```
3. Get your keys from: **Supabase Dashboard → Settings → API**
4. These are loaded in `lib/src/config/app_config.dart` via `dotenv.get()`.

> ⚠️ **Never commit `.env` with real keys.** Add it to `.gitignore`.

---

## 6. 💾 Local Storage (Hive)

*(No local storage (Hive) selected for this project)*

---

## 7. ☁️ Backend — Supabase (Authentication Only)

Supabase is used **only for authentication** (login, signup, OTP, password reset).

### Setup Steps:
1. Create a project at [supabase.com](https://supabase.com/)
2. Copy `Project URL` and `anon key` from **Settings → API**
3. Paste into your `.env` file (see step 5)

### Enable Auth Providers:
1. **Dashboard → Authentication → Providers**
2. Enable **Email** provider
3. (Optional) Enable **Phone** provider for SMS OTP
4. For testing: **Authentication → Settings** → disable "Confirm email"

### Verify Users:
After signup, check users at: **Dashboard → Authentication → Users**

### Auth Flow in the App:
```
SignUp → OTP email sent → Verify 6-digit code → Home
Login  → Direct to Home (if email confirmed)
Forgot → OTP email sent → Verify → Reset password
OAuth  → Chrome Google Sign-In → Deep link back to app (`sbconsultants://login-callback`) → Home
```

### Deep Linking & OAuth URL Configuration (Crucial):
> [!IMPORTANT]
> **RFC 3986 URI Scheme Compliance:**
> Never use underscores (`_`) in custom URL schemes (e.g. `com.example.flutter_sd_consultant`). Go's `url.Parse` inside Supabase GoTrue rejects schemes containing underscores and throws HTTP 500 (`"first path segment in URL cannot contain colon"`). The app uses `sbconsultants://login-callback`.

In **Supabase Dashboard → Authentication → URL Configuration**:
1. **Site URL:**
   Set to: `sbconsultants://login-callback`
2. **Redirect URLs (Whitelist):**
   Add the following entries and click Save:
   - `sbconsultants://login-callback`
   - `sbconsultants://login-callback/`
   - `sbconsultants://**`
   - `http://localhost:3000/**`
*(If these are not added, Supabase falls back to `localhost:3000` or fails callback validation).*

---

## 8. 🚀 Running the App

Once everything above is verified:

1. **For iOS Simulators/Devices**, map your native pods locally:
```bash
cd ios
pod install
cd ..
```

2. Run your app via VS Code, Android Studio, or CLI:
```bash
flutter run
```

Congratulations, and happy coding!
