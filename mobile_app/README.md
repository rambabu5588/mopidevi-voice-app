# 📱 Mopidevi Temple AI Voice Studio — Native Mobile Application (Flutter)

This directory contains the **Native Cross-Platform Mobile Application** built with Flutter for Android and iOS smartphones.

---

## 🛠️ Mobile Project Structure

```
mobile_app/
├── pubspec.yaml                       # Flutter project dependencies
├── lib/
│   ├── main.dart                      # Mobile App entrypoint & theme
│   ├── models/
│   │   ├── voice_model.dart           # Voice profile data model
│   │   ├── job_model.dart             # Announcement job data model
│   │   └── user_model.dart            # System user role model
│   ├── services/
│   │   ├── api_service.dart           # REST API Client to FastAPI Backend
│   │   └── audio_recorder_service.dart # 16kHz WAV Microphone Recorder
│   └── screens/
│       ├── home_screen.dart           # Announcement Generator Screen
│       ├── training_screen.dart       # Voice Training Reader (Session 1/20)
│       ├── voice_list_screen.dart     # Voice Management & Pre-upload Quality
│       └── settings_screen.dart      # Account Selector & Server IP Config
```

---

## 🚀 Build & Compilation Instructions

### 1. Prerequisites
- Install Flutter SDK: `https://docs.flutter.dev/get-started/install`
- Android Studio / Xcode (for iOS)

### 2. Install Dependencies
```bash
cd mobile_app
flutter pub get
```

### 3. Run on Connected Phone or Emulator
```bash
flutter run
```

### 4. Build Android Release APK
To generate an installable Android `.apk` file for temple staff smartphones:
```bash
flutter build apk --release
```
The output file will be generated at:
`mobile_app/build/app/outputs/flutter-apk/app-release.apk`

---

## 🌐 Connecting Mobile App to Backend Server
1. Ensure your computer running the FastAPI server (`.venv\Scripts\python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000`) and the mobile phone are connected to the same Wi-Fi network.
2. Open the **Settings** tab in the mobile app.
3. Enter your computer's local Wi-Fi IP address (e.g. `http://192.168.1.100:8000`) and tap **Save**.
