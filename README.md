# Aerobe Engineers app — review build 0.1.1

One Android (and iOS-ready) app for **clients** and **employees**. It uses the same accounts, jobs,
chats, profiles and ratings as the website, through the website API at `/api/v1`.

## What is in this build

**Clients**
- Log in (clients use the same account as on the website).
- Post a job: title, details, budget (USD or INR), time frame, reference link.
- Add screenshots to a job (JPEG, PNG, WEBP or GIF, up to 5, 4 MB each).
- See your jobs and the specialists assigned to them.
- Chat with each specialist. Messages refresh every few seconds.
- View a specialist's profile (experience, education, certificates, projects) and rate them (1 to 5 stars).

**Employees**
- Log in with the employee account created with the HR code on the website.
- Dashboard: your rating, profile checklist, and clients you work with (with unread chats).
- Profile: photo (square, 10 KB or smaller, prepared in the app), headline, summary, portfolio link,
  and entries for experience, education, certificates and projects.
- Chat with each client.

**Both**
- Account screen and log out. Logging out ends the token on the server.
- Personal-details note: text containing an email address or phone number is refused.

**Not in this build (planned for the final version)**
- Push notifications for new messages and assignments (the reference app uses engagement messaging;
  we have not added it yet).
- Creating employee and client accounts inside the app (use the website for now).
- Deep links from emails into the app.
- Admin tools in the app (use the website admin area).
- Payments in the app.

## How it connects to the website
- The app calls `https://www.aerobeengineers.com/api/v1/...` (set in `lib/config.dart`).
- Login returns a token that is valid for 30 days and stored in the phone's secure storage.
- The website and the app share one database, so a job posted in the app appears on the website
  admin Jobs screen, and a chat sent from the app appears in admin Chats.
- Admin accounts cannot log in to the app (by design).

## Get the APK (easiest)

**Option A: one command on your computer** (Flutter 3.22+, Java 17, Android Studio):
```
chmod +x build_apk.sh
./build_apk.sh
```
The APK is written to `aerobe-app-release.apk`. Copy it to the phone and install it (allow installs from
this source the first time).

**Option B: cloud build, no installs.** Create a free GitHub repository, upload this folder's contents
to it, then go to *Actions > Build Android APK > Run workflow*. When the run finishes, download the
`aerobe-app-apk` file from the run page.

Both options build a **release** APK signed with the standard debug key. That is fine for testing on
your phones. The Play Store needs your own signing key, which we will set up for the final build.

## Build it (on your computer, step by step)
You need Flutter 3.22 or newer and Android Studio (for the Android SDK).

1. Create the project shell once, then copy this folder's contents over it:
   ```
   flutter create --org com.aerobeengineers --project-name aerobe_app aerobe_app
   ```
   Copy `pubspec.yaml` and the `lib/` folder from this build into `aerobe_app/`, replacing the defaults.
2. Get packages and check the code:
   ```
   cd aerobe_app
   flutter pub get
   flutter analyze
   ```
   Please send us the output of `flutter analyze` if it reports anything.
3. Allow internet access. In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>`:
   ```
   <uses-permission android:name="android.permission.INTERNET" />
   ```
4. Set the app name to "Aerobe Engineers" in the same manifest (`android:label`).
5. Run on a phone or emulator: `flutter run`.
6. Build the test APK: `flutter build apk --debug`. The file is at `build/app/outputs/flutter-apk/app-debug.apk`.

For the **final** build we will also need: the app icon (from the logo), a release signing key,
the version number, and the store listings.

## Test accounts
Use an existing client or employee account from the website. Do not use admin accounts (they are refused).

## Known limits in this review build
- It has not yet been compiled or run on a phone. Step 2 above is the first check. Expect minor fixes.
- Screenshots are uploaded at up to 1600 px wide and shown as thumbnails.
- Chat refreshes every 6 seconds (not instant). Push notifications come with the final build.
