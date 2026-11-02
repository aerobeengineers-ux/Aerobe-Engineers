#!/usr/bin/env bash
# Builds the Aerobe Engineers Android APK from this folder.
# Needs: Flutter 3.22+ (on PATH), Java 17, Android SDK (installed by Android Studio).
# Output: ./aerobe-app-release.apk
set -euo pipefail
cd "$(dirname "$0")"

command -v flutter >/dev/null || { echo "Flutter is not installed or not on PATH."; exit 1; }

# 1. Create the Android project shell once (the app code lives in lib/ and pubspec.yaml).
if [ ! -d app/android ]; then
  flutter create --org com.aerobeengineers --project-name aerobe_app app
fi

# 2. Copy our code into the shell.
cp pubspec.yaml app/pubspec.yaml
rm -rf app/lib && cp -r lib app/lib

# 3. Android settings: internet access and the app name shown on the phone.
python3 - << 'PY'
import re, pathlib
manifest = pathlib.Path("app/android/app/src/main/AndroidManifest.xml")
xml = manifest.read_text(encoding="utf-8")
if "android.permission.INTERNET" not in xml:
    xml = xml.replace("<manifest ", '<manifest ', 1)
    xml = re.sub(r"(<manifest[^>]*>)", r'\1\n    <uses-permission android:name="android.permission.INTERNET" />', xml, count=1)
xml = re.sub(r'android:label="[^"]*"', 'android:label="Aerobe Engineers"', xml, count=1)
manifest.write_text(xml, encoding="utf-8")
print("AndroidManifest updated")
PY

# 4. Check, build and copy out the APK.
cd app
flutter pub get
flutter analyze
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk ../aerobe-app-release.apk
echo
echo "Done: $(pwd)/../aerobe-app-release.apk"
