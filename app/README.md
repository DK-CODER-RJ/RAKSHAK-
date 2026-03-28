# Shurakshit

AI-based voice activated personal safety app (offline + online).

## Implemented Scaffold
- Emergency mode (victim): GPS + recording hook + SMS alert flow + offline evidence queue.
- Witness mode (crime reporting): short clip hook + anonymous option + encrypted local queue.
- Offline-first storage with encrypted payload persistence and delayed sync.
- Firebase-ready remote datasource hooks.
- Riverpod state management and clean modular structure.

## Next Steps
1. Run `flutter pub get`.
2. Configure Firebase for Android/iOS.
3. Replace stub services in `lib/core/services/` with production plugins.
4. Add platform permissions (camera, mic, location, SMS, foreground/background service).
