# Deployment & Setup Guide

## 1. Firebase Setup
1. Go to [Firebase Console](https://console.firebase.google.com/).
2. Create a new project `safety-app`.
3. Add Android App (package: `com.safety.app`).
4. Download `google-services.json` and place it in `android/app/`.
5. Enable Authentication (Phone/Google) and Firestore Database.

## 2. Google Maps API
1. Get an API Key from Google Cloud Console.
2. Enable "Maps SDK for Android" and "Places API".
3. Add key to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY_HERE"/>
```

## 3. TFLite Model
1. Train a keyword spotting model (e.g. using Teachable Machine or TensorFlow).
2. Export as `.tflite`.
3. Place in `assets/models/keyword_spotting.tflite`.
4. Update `ai_keyword_service.dart` to uncomment the interpreter code.

## 4. Building
```bash
flutter build apk --release
```
