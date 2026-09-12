# Release builds (APKs for demo phones)

## Signing key

- The release key is `.secrets/clickgas-release.jks` (alias `clickgas`),
  created 2026-09-13. Its passwords are in `.secrets/key.properties`.
- Each app reads `android/key.properties` (a copy of that file, git-ignored).
  Without it, release builds fall back to the debug key (CI does this).
- **Back up the `.jks` file and its password.** An installed app can only be
  updated by an APK signed with the same key.

Fingerprints (for Google Cloud and Firebase):

```
SHA-1:   FB:C3:36:2C:4F:56:F8:40:61:21:68:58:3F:21:9D:8F:98:67:B7:56
SHA-256: 50:2F:8A:79:2E:36:7B:CE:1D:C0:10:08:CE:B9:42:DB:67:EC:E2:73:05:6C:DC:3E:9D:63:F0:2B:53:9C:1B:E9
```

## Google Maps in release builds

If the Maps API key is restricted to Android apps, add the release SHA-1 for
both packages in Google Cloud Console › APIs & Services › Credentials › the
Maps key › Android restrictions:

| Package | SHA-1 |
|---|---|
| `com.clickgas.app` | `FB:C3:36:2C:4F:56:F8:40:61:21:68:58:3F:21:9D:8F:98:67:B7:56` |
| `com.clickgas.driver` | same |

Symptom when missing: the map area stays grey/blank in the release APK while
debug builds work.

## Build

```sh
cd apps/customer
flutter build apk --release --dart-define-from-file=../../env/dev.json
cd ../distributor
flutter build apk --release --dart-define-from-file=../../env/dev.json
```

APKs: `apps/<app>/build/app/outputs/flutter-apk/app-release.apk`. Copy to
the phones and install (allow "install unknown apps").

## New key on another machine

```sh
keytool -genkeypair -keystore clickgas-release.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias clickgas \
  -dname "CN=ClickGas, O=ClickGas, C=JO"
```

Only for a fresh start: apps signed with the old key must be uninstalled
first.
