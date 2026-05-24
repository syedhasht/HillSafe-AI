# HillSafe AI - Android Emulator Setup

## Prerequisites Check

Before running the app, ensure you have:

1. **Flutter SDK** installed and in PATH
2. **Android Studio** installed
3. **Android SDK** configured
4. **Android Emulator** created

---

## Quick Environment Check

Run these commands to verify your setup:

```powershell
# Check Flutter installation
flutter doctor

# List available Android emulators
flutter emulators

# List connected devices (emulators + physical)
flutter devices
```

---

## Step-by-Step Launch Instructions

### Option 1: Using VS Code (Recommended)

1. **Start Android Emulator:**
   - Open Android Studio → AVD Manager
   - Click ▶️ (Play) on any emulator
   - Wait for emulator to fully boot

2. **Launch from VS Code:**
   - Press `F5` (or click Run → Start Debugging)
   - Select "Debug Android" configuration
   - App will build and install automatically

### Option 2: Using Terminal

```powershell
# Navigate to project directory
cd "c:\Users\hashi\Downloads\FYP\Frontend App"

# Start an emulator by name (get name from 'flutter emulators')
flutter emulators --launch <emulator_id>

# OR manually start from Android Studio, then run:
flutter run -d android

# For hot reload during development:
flutter run -d android --hot
```

---

## Common Commands

```powershell
# Check for issues
flutter doctor -v

# Clean build if issues occur
flutter clean
flutter pub get

# Run on specific device
flutter devices  # List all devices
flutter run -d <device_id>

# Run in release mode (faster, no debugging)
flutter run -d android --release
```

---

## Troubleshooting

### "No devices found"
- Start emulator from Android Studio first
- Run `flutter devices` to confirm it's detected

### "Gradle build failed"
- Run `flutter clean`
- Check Android SDK license: `flutter doctor --android-licenses`

### "SDK not found"
- Set ANDROID_HOME environment variable
- Point to Android SDK location (usually `C:\Users\<user>\AppData\Local\Android\Sdk`)

---

## VS Code Extensions Needed

If not installed, add these:
- **Dart** (by Dart Code)
- **Flutter** (by Dart Code)

---

## Expected First Run

First build takes 3-5 minutes as Gradle downloads dependencies.
Subsequent runs take 10-30 seconds.

**Hot Reload:** Press `r` in terminal or save files in VS Code
**Hot Restart:** Press `R` in terminal

---

## Success Indicators

✅ Terminal shows: "Flutter run key commands."
✅ Emulator displays HillSafe AI splash screen
✅ No red error messages

Ready to develop! 🚀
