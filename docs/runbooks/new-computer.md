# Moving to a new or reinstalled computer

The code and its history are on GitHub. The database, Edge Function, Vault
secrets and Firebase project are in the cloud and need nothing. What must be
carried by hand is the small set of **git-ignored files**: keys, the signing
keystore, and local config. Losing the release keystore
(`.secrets/clickgas-release.jks`) means released apps can never be updated
with the same signature, so keep two copies of it.

## Before wiping

1. Everything is pushed: `git status -sb` shows `## main...origin/main` with
   no `[ahead N]`, and `git stash list` is empty.
2. Make the restore pack (keeps the same folder layout):
   ```sh
   B=../ClickGas-backup; mkdir -p "$B"
   cp -r --parents .secrets google-services.json \
     apps/customer/android/{local.properties,key.properties,app/google-services.json} \
     apps/distributor/android/{local.properties,key.properties,app/google-services.json} "$B"/
   mkdir -p "$B/claude-memory" && cp ~/.claude/projects/c--Users-omara-Downloads-ClickGas/memory/* "$B/claude-memory/"
   ```
3. Copy `ClickGas-backup` to the USB drive, then open two or three files on
   the USB to check they read. Keep a second copy somewhere else (another
   drive, a password manager for the keystore and its passwords).
4. The pack holds keys that can control Supabase and Firebase: turn on
   **BitLocker To Go** for the USB (right-click the drive › Turn on BitLocker),
   and delete the pack from the USB once the new machine works. If the USB is
   lost, rotate the keys ([secrets.md](secrets.md)).

| In the pack | What it is | If lost |
|---|---|---|
| `.secrets/clickgas-release.jks`, `.secrets/key.properties` | Android release signing key and its passwords | **Cannot be recreated** |
| `.secrets/supabase.env` (+ old copies `server`, `supabase.txt`) | Supabase URL and secret key for the tools | Create a new secret key in the dashboard |
| `.secrets/firebase-service-account.json`, `push.env`, `push-vault.sql` | Push delivery secrets | New key in Firebase, rerun `tools/push/setup.mjs` |
| `.secrets/demo-accounts.md`, `demo.env` | Demo logins and password | Reseed with `tools/demo` |
| `apps/*/android/local.properties` | `MAPS_API_KEY` (+ SDK paths) | Copy the key from Google Cloud › Credentials |
| `apps/*/android/key.properties` | Points release builds at the keystore | Recreate from `release-builds.md` |
| `google-services.json` (root and `apps/*/android/app/`) | Firebase app config | Download again from Firebase |
| `claude-memory/` | Claude Code's notes about this project | Optional |

Not needed: `build/`, `.dart_tool/`, `.gradle/`, `node_modules/`,
`supabase/.temp/`, `gradlew*` in the apps: all regenerated.

## After reinstalling

1. Install:
   - Git, VS Code with the Flutter and Dart extensions
   - JDK 17 (`C:\Program Files\Java\jdk-17`)
   - Android Studio, then in its SDK Manager: Android SDK Platform 36, SDK
     Platform-Tools, Build-Tools, and NDK 28.2.13676358
   - Flutter **3.47.3**, unzipped to `C:\Dev\flutter`, with
     `C:\Dev\flutter\bin` added to PATH
   - Node.js 24 LTS
2. Point Flutter at the tools:
   ```sh
   flutter config --jdk-dir "C:\Program Files\Java\jdk-17"
   flutter doctor --android-licenses
   flutter doctor
   ```
3. Clone to **the same place** (`C:\Users\omara\Downloads\ClickGas`), so the
   keystore path in `key.properties` still matches:
   ```sh
   cd C:\Users\omara\Downloads
   git clone https://github.com/omar90900/ClickGas.git
   cd ClickGas
   git config user.name "omaralsalm2004"
   git config user.email "<your GitHub email>"
   ```
4. Copy everything from `ClickGas-backup` into `ClickGas`, merging folders
   (same relative paths). Put `claude-memory/*` in
   `C:\Users\omara\.claude\projects\c--Users-omara-Downloads-ClickGas\memory\`.
5. Different folder or user name? Fix `storeFile=` in both
   `apps/*/android/key.properties`, and `sdk.dir=` / `flutter.sdk=` in both
   `local.properties` (keep the `MAPS_API_KEY` line).
6. Get packages and check:
   ```sh
   flutter pub get
   cd apps/customer && flutter analyze && cd ../..
   node tools/e2e/order_cycle.mjs
   ```
   Then run the customer app on the phone (VS Code › Run › "Customer (dev)").
   Settings › Notifications should say notifications reach you even when the
   app is closed.
7. Only when deploying the Edge Function again: `npx supabase login` and
   `npx supabase link --project-ref rggjsueryxymukcnqawd`.
