# Mopidevi AI Voice System — Master Architecture & Production Roadmap

The **Mopidevi AI Voice System** is structured into **Three Independent Subsystems**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      1. VOICE MANAGEMENT & TRAINING                         │
│ (Admin / Voice Team)                                                        │
│ Mobile Training Session → Dataset Alignment → Deep Learning XTTS v2 / RVC   │
│ Speaker Embedding → Model Versioning (v1.0, v1.1, v2.0) → Approval         │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      2. USER MANAGEMENT & ASSIGNMENTS                       │
│ (Admin Role & Permissions Engine)                                           │
│ Roles: Super Admin | Voice Manager | Operator | Viewer                      │
│ Database Assignment: User ──> Assigned Voice (e.g. Mopidevi Male v2.1)      │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      3. VOICE GENERATION PIPELINE                           │
│ (Operator / Temple Staff Operation)                                         │
│ Enter Telugu Script ──> Text Normalizer ──> Mopidevi Pronunciation ──>     │
│ Speech Director ──> Deep Neural Voice Synthesis ──> Validation ──> Masterer │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📌 Master Step-by-Step Execution Plan & Status

| Step | Feature / Component | Description | Status |
|---|---|---|---|
| **1** | **Mopidevi Pronunciation Engine** | 6 JSON dictionaries (`temple_words`, `deity_names`, `place_names`, `difficult_words`, `numbers`, `dates`) & phrase substitution engine in `mopidevi_voice/pronunciation/`. | **✅ COMPLETED** |
| **2** | **Telugu Normalization & Breathing Pauses** | Expands numbers/time (`10:30 AM` → `పదిన్నర గంటలకు`) & converts punctuation into explicit millisecond breathing pauses (`[700ms]`, `[400ms]`, `[600ms]`). | **✅ COMPLETED** |
| **3** | **Speech Director & Deity Emphasis** | 6 Delivery Styles (`Devotional`, `Announcement`, `Warm`, `Important`, `Festival`, `Spiritual`) & deity term volume emphasis (`+1.5dB`). | **✅ COMPLETED** |
| **4** | **Natural Voice Clone Engine** | Acoustic feature extraction (pitch F0, RMS energy, estimated vocal gender) & Natural Voice synthesis in `mopidevi_voice/voice_clone/`. | **✅ COMPLETED** |
| **5** | **Mobile Pre-Upload Voice Verification** | Mobile API endpoint (`POST /api/voices/analyze`) checking RMS energy, background noise, pitch estimate, and quality badge (`🟢 Good`, `🟡 Acceptable`, `🔴 Poor`). | **✅ COMPLETED** |
| **6** | **Sentence-by-Sentence TTS & Auto-Validation** | Generates speech sentence-by-sentence. Runs `AudioValidator` (RMS, duration, speech check, clipping). Triggers single-sentence auto-retry if valid speech is missing. | **✅ COMPLETED** |
| **7** | **Pure Audio Normalization & Mastering** | Normalizes loudness (-14 dBFS target), peak limiting, and exports clean WAV/MP3 files without sound effects. | **✅ COMPLETED** |
| **8** | **Adaptive Voice Training & Difficult Word Loop** | Scans Telugu text for difficult terms, prompts user for targeted snippets, extracts acoustic embeddings, and fine-tunes voice profile in `mopidevi_voice/voice_clone/trainer.py`. | **✅ COMPLETED** |
| **9** | **Database Training Scripts Repository** | Folder `mopidevi_voice/training_scripts/` containing dataset scripts (`01_welcome.txt`, `02_darshan.txt`, etc.). Seeded into SQLite database `training_script_database`. | **✅ COMPLETED** |
| **10**| **Database Schema for 3-System Architecture** | Extended SQLite schema for `USERS`, `ROLES`, `VOICE_VERSIONS`, `USER_VOICE_ASSIGNMENTS`, `TRAINING_DATASETS`, `TRAINING_EVALUATIONS` in `backend/database.py`. | **✅ COMPLETED** |
| **11**| **Voice Training & Versioning Subsystem** | Mobile Training Session UI (Session 1/20 sentence reader & auto quality check) + Model Versioning (`v1.0`, `v1.1`, `v2.0`) & Admin Approval Engine. | **✅ COMPLETED** |
| **12**| **User Roles & Voice Assignment Subsystem** | Role permissions (`Super Admin`, `Voice Manager`, `Operator`, `Viewer`) + Central voice assignment & version hot-swapping without user reinstall. | **✅ COMPLETED** |
| **13**| **Operator Announcement Generation Subsystem** | Operator workflow: Login → Select assigned voice version → Enter Telugu script → Select style → Sentence-by-sentence TTS → Validation → Mastered Audio. | **✅ COMPLETED** |
| **14**| **Deep Learning Neural Voice Cloning (XTTS v2 / RVC)** | Speaker neural embedding extractor, 512-dim latent speaker vector storage (`deep_clone.py`), zero-shot neural voice cloning synthesis, and model fine-tuning. | **✅ COMPLETED** |
| **15**| **Native Cross-Platform Mobile Application (Flutter)** | Native mobile app codebase in `mobile_app/` with API Service, Voice Recorder, Announcement Generator, Training Session Screen, & User Account Switcher. | **✅ COMPLETED** |
| **16**| **100% Free Online Cloud Deployment Setup (Render.com)** | `Dockerfile`, `requirements.txt`, `render.yaml`, and `FREE_HOSTING_GUIDE.md` for 100% free 24/7 cloud hosting with HTTPS URL. | **✅ COMPLETED** |

---

## 📱 Native Mobile Application Architecture (`mobile_app/`)

```
mobile_app/
├── pubspec.yaml                       # Flutter project dependencies
├── lib/
│   ├── main.dart                      # Mobile App entrypoint & theme
│   ├── models/                        # Voice, Job, & User models
│   ├── services/
│   │   ├── api_service.dart           # Backend REST API Integration
│   │   └── audio_recorder_service.dart # Mobile mic audio recorder
│   ├── screens/
│   │   ├── home_screen.dart           # Announcement Generator Screen
│   │   ├── training_screen.dart       # Voice Training Session Screen
│   │   ├── voice_list_screen.dart     # Voice Management & Pre-upload Verification
│   │   └── settings_screen.dart      # Account & Backend URL Settings
│   └── widgets/                       # Audio player & quality badge widgets
└── README.md                          # Android APK & iOS build guide
```