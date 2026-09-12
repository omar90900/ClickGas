# App stuck on the launch image (or "ClickGas could not start")

## Symptom

The app opens to the white screen with the cylinder logo and never moves
on. Since 2026-09-13 the apps show a red "ClickGas could not start" screen
with the error instead (`runGuardedApp` in `clickgas_core/lib/src/startup.dart`,
30-second limit).

## Seen on 2026-09-13: a native plugin library missing from the APK

The phone log (`adb logcat`) showed:

```
E/GeneratedPluginsRegister: ... could not find or invoke the GeneratedPluginRegistrant
Caused by: java.lang.UnsatisfiedLinkError: dlopen failed: library "libdartjni.so" not found
    at com.github.dart_lang.jni.JniPlugin.<clinit>
```

`jni` comes from `path_provider_android` 2.3+. When its native library is
missing, plugin registration stops at that plugin, so the plugins after it
(shared_preferences, url_launcher, ...) are never connected. Supabase needs
shared_preferences, so start-up failed before the first frame:

```
PlatformException(channel-error, Unable to establish connection on channel:
"dev.flutter.pigeon.shared_preferences_android.SharedPreferencesApi.getAll")
```

The customer APK had been built while a second build of the same app was
running (VS Code and a terminal at the same time); the build folder was left
half-written and the APK shipped without `libdartjni.so`.

## Fix

1. Stop every running build of that app (close `flutter run` sessions in
   terminals and VS Code).
2. `cd apps/<app> && flutter clean && flutter pub get` (from the repo root:
   `flutter pub get`).
3. Build and run once.
4. Check the APK: `unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep dartjni`
   must list `lib/arm64-v8a/libdartjni.so`.

## Other causes

| Log shows | Cause | Fix |
|---|---|---|
| `Unable to establish connection on channel` for any plugin | Plugins not registered (see above) | Clean build; read the first `GeneratedPluginsRegister` error |
| `TimeoutException` on the error screen | No internet or Supabase unreachable at start | Check the connection; `SUPABASE_URL` in `env/dev.json` |
| `Gradle task assembleDebug failed ... Unable to delete directory` | Two builds of the same app at once | Stop one, then `flutter clean` |

Only build one copy of an app at a time.
