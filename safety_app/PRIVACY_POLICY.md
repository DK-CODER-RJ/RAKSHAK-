# Privacy Policy for Safety App

**Effective Date:** 21 February 2026

## Introduction
Safety App is designed to provide immediate assistance and security through voice activation and witness recording features. To function efficiently, the app requires specific permissions. This document outlines how we use and protect your data.

## 1. Background Location Data
Safety App requests access to your device's location (including Background Location).
- **Why we need it:** We use your location to instantly identify the nearest police station (via Google Places API) and send your accurate coordinates to your designated emergency contacts if the Victim Mode is triggered.
- **Background usage:** Location is tracked in the background so that the voice activation ("HELP" command) can instantly fetch your coordinates even if the app is closed or in your pocket.
- **Data Sharing:** We do not sell or share your location data. It is only shared securely with your authorized emergency contacts during an active SOS.

## 2. SMS and Call Permissions
- **Why we need it:** If an emergency is triggered, Safety App requires SMS permissions to autonomously send an alert message (containing your location) to your saved emergency contacts. It also requires Call permissions to automatically dial emergency services (e.g., 100/911).

## 3. Microphone & Camera
- **Why we need it:** 
  - The **Microphone** is used constantly in the background by our local AI model to detect the "HELP" keyword. The raw audio is processed strictly on-device using a TensorFlow Lite model and is **never** sent to the cloud.
  - The **Camera** is used exclusively in "Witness Mode" to securely record video evidence of an incident. 
  - **Data Retention:** Video evidence is saved locally. If you choose to submit a report, the video is securely transmitted to our Cloud Storage for authorities.

## 4. Account Data
If you sign in via Google Authentication, your basic profile information (Name, Email) is securely stored in Firebase Auth solely for identifying your account and saving your emergency contact list.

## Contact Us
If you have any questions regarding this Privacy Policy, please contact the developer via the app store listing.
