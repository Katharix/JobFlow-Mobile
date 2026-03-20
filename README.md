# JobFlow Mobile

Flutter app for employee workflows: assignments, directions, ETA updates, payments, and org messaging.

## Setup

1. Update API base URL in [lib/constants/app_constants.dart](lib/constants/app_constants.dart).
2. Configure Firebase:
	- Add `google-services.json` to `android/app/`.
	- Add `GoogleService-Info.plist` to `ios/Runner/`.
	- Enable Email/Password in Firebase Auth.
	- Web uses the same Firebase settings as the UI (`jobflow-ui-web`).
3. Set the Google Maps API key:
	- Android: [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) `com.google.android.geo.API_KEY`.
	- iOS: add the API key to `AppDelegate` (Google Maps iOS setup).
4. Sign in using your JobFlow employee credentials.

## Local config (ignored by Git)

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Android signing files (`android/key.properties`, `*.jks`, `*.keystore`)
- `.env` files

## Run

```
flutter pub get
flutter run
```

## Notes

- Assignments load from `GET /api/Assignment?start=...&end=...`.
- Job tracking updates post to `POST /api/JobTracking/update`.
- Google Maps opens externally for turn-by-turn navigation.
