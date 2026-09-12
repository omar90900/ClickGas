/// Supabase project settings, per environment.
///
/// Values come from `--dart-define-from-file=env/<name>.json` (see
/// docs/environments.md); the defaults point at the development project so
/// `flutter run` works without flags.
///
/// Only the *publishable* key belongs in the app - Row Level Security
/// protects the data. The secret key must never be put in an app.
class SupabaseConfig {
  /// `dev`, `staging` or `demo`. Written into diagnostics uploads.
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rggjsueryxymukcnqawd.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_vVKaYFQFq2kGiCcxhbRyPQ_0xDQVreL',
  );
}
