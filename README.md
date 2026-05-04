<<<<<<< HEAD
# 🛡️ RAKSHAK — Personal Safety & Emergency Response App

> **An advanced, high-performance personal safety application that transforms any smartphone into a 24/7 personal guardian.**

RAKSHAK combines **voice-activated emergency triggers**, **real-time location tracking**, **automated SMS dispatch**, and **covert witness mode** to provide comprehensive protection for anyone, anywhere.

---

## 🎯 Core Features

### 1. 🎤 Voice Activation Engine

- **Native Android SpeechRecognizer**: Custom Kotlin-based continuous listener via `MethodChannel` & `EventChannel`
- **Multi-language Keywords**: English (`"Help"`, `"Emergency"`) + Hindi (`"Bachao"`, `"Madad"`)
- **3x Confirmation**: Requires keyword spoken **3 times within 15 seconds** to prevent false triggers
- **Auto-restart**: Recognition loop automatically restarts on silence/error

### 2. 🚨 Emergency SOS Protocol

- **One-Tap Activation**: Big red SOS button on the dashboard
- **Voice Activation**: Say any keyword 3 times → auto-redirects to SOS screen
- **Auto SMS Dispatch**: Instantly sends SMS with Google Maps location link to **all** saved emergency contacts
- **Live Location Streaming**: Real-time GPS coordinates pushed to Firebase Firestore
- **Simple Cancel**: One-tap cancel with no PIN required

### 3. 📹 Witness Mode (Stealth Recording)

- **Live Camera Recording**: Record video evidence of incidents you witness
- **GPS Tagging**: Every recording is stamped with accurate latitude/longitude
- **Geocoding Fallback**: If street address unavailable, raw coordinates are used
- **Permanent Storage**: Videos saved to `Documents/witness_recordings/` on-device
- **Incident History**: All recordings logged and browsable with timestamps

### 4. 📱 Emergency Contacts Manager

- **Custom Contacts**: Add your own emergency numbers (no hardcoded defaults)
- **Direct Call**: One-tap phone dialer launch for any contact
- **Direct SMS**: One-tap texting for any contact
- **Primary Contact Tag**: Mark one contact as primary for priority alerts
- **Swipe to Delete**: Easy contact management with swipe gestures

### 5. 🔐 Authentication

- **Firebase Auth**: Email/Password sign-up and login
- **Google Sign-In**: One-tap Google authentication
- **Persistent Sessions**: Stay logged in across app restarts
- **Functional Logout**: Proper sign-out with confirmation dialog

### 6. 🛰️ Guardian Background Service

- **Foreground Service**: Persistent Android foreground notification
- **Location Heartbeat**: Continuous GPS streaming to Firebase
- **Battery Optimization Bypass**: Requests `ignoreBatteryOptimizations` on startup

---

## 🏗️ Tech Stack

| Technology | Purpose |
| --- | --- |
| **Flutter 3.16+** | Cross-platform mobile framework |
| **Dart 3.2+** | Programming language |
| **Kotlin** | Native Android voice recognition |
| **Provider** | State management |
| **Go Router** | Declarative navigation & deep linking |
| **Firebase Auth** | Authentication (Email + Google) |
| **Cloud Firestore** | Real-time database & location streaming |
| **Firebase Storage** | Media upload & cloud evidence storage |
| **Google Maps Flutter** | Map rendering & location services |
| **Geolocator** | High-accuracy GPS positioning |
| **Telephony** | Native SMS auto-dispatch |
| **Camera** | Video recording (Witness Mode) |
| **SharedPreferences** | Local contacts & settings persistence |

---

## 📁 Project Structure

```text
rakshak/
├── README.md
├── .gitignore
├── .env
├── pubspec.yaml
├── analysis_options.yaml
├── firebase.json
│
├── lib/
│   ├── main.dart                                    # App entry point & permission init
│   ├── firebase_options.dart                        # Firebase configuration
│   │
│   ├── frontend/
│   │   ├── person_a_mobile_ui/                      # Developer A: UI Components & Screens
│   │   │   └── lib/
│   │   │       ├── screens/
│   │   │       │   ├── splash_screen.dart            # Animated launch screen
│   │   │       │   ├── onboarding_screen.dart        # First-time user onboarding
│   │   │       │   ├── login_screen.dart             # Firebase Auth login
│   │   │       │   ├── signup_screen.dart            # New user registration
│   │   │       │   ├── home_dashboard.dart           # Main command center
│   │   │       │   ├── sos_trigger_screen.dart       # Emergency SOS activation
│   │   │       │   ├── witness_mode_screen.dart      # Camera recording interface
│   │   │       │   ├── contacts_manager.dart         # Emergency contacts CRUD
│   │   │       │   ├── incident_history_screen.dart  # Past incident logs
│   │   │       │   ├── video_player_screen.dart      # Evidence video playback
│   │   │       │   ├── safe_zones_screen.dart        # Geofence management
│   │   │       │   └── settings_screen.dart          # App configuration
│   │   │       ├── widgets/
│   │   │       │   ├── emergency_button.dart         # SOS trigger button
│   │   │       │   ├── live_map_widget.dart          # Google Maps embed
│   │   │       │   ├── guardian_status_indicator.dart # Service status badge
│   │   │       │   ├── contact_tile.dart             # Contact list item
│   │   │       │   ├── geofence_card.dart            # Safe zone card
│   │   │       │   └── permission_dialog.dart        # Runtime permission UI
│   │   │       ├── themes/
│   │   │       │   ├── app_theme.dart                # Design system tokens
│   │   │       │   ├── dark_theme.dart               # Dark mode theme
│   │   │       │   └── light_theme.dart              # Light mode theme
│   │   │       └── animations/
│   │   │           ├── pulse_animation.dart          # SOS button pulse
│   │   │           └── screen_transitions.dart       # Page route animations
│   │   │
│   │   └── person_b_navigation_state/               # Developer B: Navigation & State
│   │       └── lib/
│   │           ├── navigation/
│   │           │   ├── app_router.dart               # GoRouter route definitions
│   │           │   ├── route_guards.dart             # Auth route protection
│   │           │   └── deep_link_handler.dart        # Dynamic link handler
│   │           ├── state/
│   │           │   ├── providers/
│   │           │   │   ├── auth_provider.dart        # Firebase Auth state
│   │           │   │   ├── sos_state_provider.dart   # SOS lifecycle management
│   │           │   │   ├── contacts_provider.dart    # Emergency contacts state
│   │           │   │   ├── location_provider.dart    # GPS location state
│   │           │   │   ├── guardian_provider.dart     # Background service state
│   │           │   │   ├── incident_provider.dart    # Incident history state
│   │           │   │   ├── safe_zone_provider.dart   # Geofence state
│   │           │   │   └── settings_provider.dart    # App settings state
│   │           │   ├── blocs/
│   │           │   │   ├── sos_bloc/                 # SOS event bloc
│   │           │   │   ├── witness_bloc/             # Witness recording bloc
│   │           │   │   └── geofence_bloc/            # Geofence monitoring bloc
│   │           │   └── repositories/
│   │           │       ├── user_repository.dart      # User data repository
│   │           │       └── settings_repository.dart  # Settings persistence
│   │           ├── services/
│   │           │   ├── permission_handler.dart       # Runtime permissions
│   │           │   └── battery_optimization_service.dart # Doze mode bypass
│   │           └── utils/
│   │               ├── constants.dart               # App-wide constants
│   │               ├── validators.dart              # Input validation
│   │               └── helpers.dart                 # Utility functions
│   │
│   ├── backend/
│   │   ├── person_c_api_development/                # Developer C: API & Business Logic
│   │   │   ├── api/
│   │   │   │   ├── v1/
│   │   │   │   │   ├── auth/                        # Login, Register, Verify
│   │   │   │   │   ├── sos/                         # Trigger, Upload, Cancel
│   │   │   │   │   ├── contacts/                    # Add, Update, Fetch
│   │   │   │   │   ├── geofence/                    # Save, Get, Update
│   │   │   │   │   └── settings/                    # Update, Get, Configure
│   │   │   │   ├── middleware/
│   │   │   │   │   ├── auth_middleware.dart          # JWT token verification
│   │   │   │   │   ├── rate_limiter.dart             # Request throttling
│   │   │   │   │   └── logging_middleware.dart       # Request/response logs
│   │   │   │   └── websocket/
│   │   │   │       ├── location_stream.dart         # Real-time GPS stream
│   │   │   │       └── audio_stream.dart            # Audio data stream
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart                  # User data model
│   │   │   │   ├── sos_event.dart                   # SOS event model
│   │   │   │   ├── witness_record.dart              # Witness recording model
│   │   │   │   ├── emergency_contact.dart           # Contact model
│   │   │   │   ├── geofence_model.dart              # Geofence model
│   │   │   │   └── location_track.dart              # Location track model
│   │   │   ├── services/
│   │   │   │   ├── sms_service.dart                 # SMS dispatch service
│   │   │   │   ├── call_service.dart                # Phone call service
│   │   │   │   ├── police_dispatch.dart             # Police station lookup
│   │   │   │   ├── email_service.dart               # Email notification
│   │   │   │   └── push_notification.dart           # FCM push alerts
│   │   │   ├── config/
│   │   │   │   ├── database.dart                    # Database configuration
│   │   │   │   ├── redis.dart                       # Redis cache config
│   │   │   │   └── firebase_config.dart             # Firebase project config
│   │   │   └── utils/
│   │   │       ├── encryption.dart                  # AES-256 encryption
│   │   │       ├── geocoding_helper.dart            # Reverse geocoding
│   │   │       └── audio_processor.dart             # Audio processing
│   │   │
│   │   └── person_d_database_infra/                 # Developer D: Database & Infrastructure
│   │       ├── database/
│   │       │   ├── migrations/                      # SQL schema migrations
│   │       │   ├── seeds/                           # Initial seed data
│   │       │   └── queries/                         # Database query helpers
│   │       ├── infrastructure/
│   │       │   ├── cloud/                           # Cloud storage (S3/GCS)
│   │       │   ├── queue/                           # Background job workers
│   │       │   └── caching/                         # Redis cache layer
│   │       └── monitoring/
│   │           ├── logs/                            # Application logs
│   │           ├── metrics/                         # Performance metrics
│   │           └── alerts/                          # System alerts
│   │
│   ├── integrations/                                # All Third-Party Integrations
│   │   ├── background_service.dart                  # Flutter background service
│   │   ├── google_maps/
│   │   │   ├── maps_service.dart                    # Google Maps rendering
│   │   │   ├── places_service.dart                  # Nearby places lookup
│   │   │   └── geocoding_service.dart               # Address ↔ Coordinates
│   │   ├── firebase/
│   │   │   ├── auth_service.dart                    # Firebase Authentication
│   │   │   ├── firestore_service.dart               # Cloud Firestore CRUD
│   │   │   ├── storage_service.dart                 # Firebase Storage uploads
│   │   │   ├── dynamic_links.dart                   # Firebase Dynamic Links
│   │   │   └── cloud_messaging.dart                 # Push notifications (FCM)
│   │   ├── voice_recognition/
│   │   │   ├── native_voice_service.dart            # Native Android bridge (Dart)
│   │   │   ├── voice_recognition_service.dart       # Flutter voice service
│   │   │   ├── picovoice_service.dart               # Picovoice/Porcupine wrapper
│   │   │   ├── wake_word_detector.dart              # Wake word detection
│   │   │   ├── keyword_training.dart                # Custom keyword training
│   │   │   └── audio_stream_handler.dart            # Audio stream processing
│   │   ├── telecom/
│   │   │   ├── sms_sender.dart                      # SMS dispatch via Telephony
│   │   │   ├── call_initiator.dart                  # Phone call launcher
│   │   │   └── carrier_info.dart                    # SIM/Carrier detection
│   │   ├── media/
│   │   │   ├── witness_service.dart                 # Witness recording logic
│   │   │   └── upload_service.dart                  # Media upload pipeline
│   │   ├── location/
│   │   │   └── geofence_service.dart                # Geofence monitoring
│   │   ├── hardware/
│   │   │   ├── accelerometer_listener.dart          # Motion detection
│   │   │   ├── shake_detector.dart                  # Shake-to-SOS trigger
│   │   │   └── proximity_sensor.dart                # Pocket detection
│   │   └── third_party/
│   │       ├── twilio_service.dart                  # Twilio SMS API
│   │       ├── sentry_service.dart                  # Error tracking
│   │       └── mixpanel_service.dart                # Analytics
│   │
│   └── shared/                                      # Shared Between Frontend & Backend
│       ├── constants/
│       │   ├── error_codes.dart                     # Standardized error codes
│       │   ├── api_endpoints.dart                   # API URL constants
│       │   └── distress_keywords.dart               # SOS keyword definitions
│       ├── models/
│       │   ├── emergency_contact.dart               # Contact data model
│       │   ├── incident.dart                        # Incident record model
│       │   ├── sos_payload.dart                     # SOS event payload
│       │   ├── location_data.dart                   # Location data model
│       │   └── witness_metadata.dart                # Witness recording metadata
│       ├── utils/
│       │   ├── encryption_helper.dart               # Encryption utilities
│       │   ├── geo_utils.dart                       # Geolocation math
│       │   └── date_utils.dart                      # Date/time formatting
│       └── validators/
│           ├── phone_validator.dart                 # Phone number validation
│           └── email_validator.dart                 # Email format validation
│
├── android/                                         # Android Platform
│   └── app/
│       └── src/main/
│           ├── AndroidManifest.xml                  # Permissions & services
│           ├── google-services.json                 # Firebase config
│           └── kotlin/.../MainActivity.kt           # Native SpeechRecognizer
│
├── ios/                                             # iOS Platform
│   └── Runner/
│       ├── Info.plist                               # iOS permissions
│       └── GoogleService-Info.plist                 # Firebase config (iOS)
│
├── scripts/                                         # Build & Deployment
│   ├── build_android.sh                             # Android APK build
│   ├── build_ios.sh                                 # iOS IPA build
│   ├── deploy_backend.sh                            # Backend deployment
│   └── setup_environment.sh                         # Dev environment setup
│
├── tests/                                           # Testing Suites
│   ├── unit_tests/                                  # Unit tests
│   ├── integration_tests/                           # Integration tests
│   ├── widget_tests/                                # Widget tests
│   └── e2e_tests/                                   # End-to-end tests
│
└── assets/                                          # Static Assets
    ├── images/                                      # App images
    ├── icons/                                       # Custom icons
    └── animations/                                  # Lottie animations
```

---

## 🚀 Setup Instructions

```bash
# 1. Clone the repository
git clone https://github.com/your-username/rakshak.git
cd rakshak

# 2. Install Flutter dependencies
flutter pub get

# 3. iOS specific setup
cd ios && pod install && cd ..

# 4. Set up environment variables
cp .env.example .env
# Edit .env with your API keys (Firebase, Google Maps, etc.)

# 5. Run on device
flutter run -d <device_id>
```

### Prerequisites

- Flutter SDK `3.16+`
- Dart SDK `3.2+`
- Android Studio / Xcode
- Firebase project with Auth, Firestore, and Storage enabled
- Google Maps API key

---

## 🔧 Development Workflow

| Branch | Developer | Focus |
| --- | --- | --- |
| `feature/frontend-ui` | Developer A | UI Components & Screens |
| `feature/frontend-state` | Developer B | Navigation & State Management |
| `feature/backend-api` | Developer C | API Endpoints & Business Logic |
| `feature/backend-db` | Developer D | Database & Infrastructure |
| `api integrations`  | Developer E | All Feature Integrations |

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/frontend-ui

# Work on changes, then push
git add .
git commit -m "feat: add witness mode recording"
git push origin feature/frontend-ui

# Create Pull Request → Code Review → Merge to main
```

---

## 🔒 Security

| Layer | Implementation |
| --- | --- |
| **Transport** | TLS 1.3 end-to-end encryption |
| **Storage** | AES-256 local data encryption |
| **Auth** | Firebase Auth with Google Sign-In |
| **Database** | Firebase Security Rules (role-based) |
| **Rate Limiting** | 10 SOS triggers per hour |
| **Permissions** | Runtime permission requests with graceful fallback |

---

## 📈 Performance Targets

| Metric | Target |
| --- | --- |
| App startup | < 2 seconds |
| SOS trigger → SMS dispatch | < 1 second |
| Voice recognition latency | < 500ms |
| Battery impact (passive mode) | < 5% per day |
| Crash-free rate | > 99.5% |
| GPS accuracy | ± 5 meters |

---

## 📱 Supported Platforms

| Platform | Status |
| --- | --- |
| Android 8.0+ (API 26) | ✅ Fully Supported |
| iOS 14+ | ⚠️ Planned |

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test suite
flutter test tests/unit_tests/
flutter test tests/widget_tests/

# Run with coverage
flutter test --coverage
```

---

## 📄 License

This project is developed for educational and personal safety purposes.

---

**Version**: 1.0.0 | **Status**: Production Ready | **Last Updated**: May 2026
=======
# RAKSHAK-
Human Safety Emergency App
>>>>>>> 7dac2c665616ca88e99e1c2c33af403253fc2c1d
