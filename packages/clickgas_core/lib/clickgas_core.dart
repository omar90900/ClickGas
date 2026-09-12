/// Shared code for the ClickGas customer and distributor apps.
///
/// Layering (docs/architecture.md): screens -> controllers -> repositories.
/// Only repositories talk to Supabase, and they only throw [AppFailure].
library;

export 'package:image_picker/image_picker.dart' show ImageSource;

export 'src/app_settings.dart';
export 'src/app_theme.dart';
export 'src/errors.dart';
export 'src/location_service.dart';
export 'src/logger.dart';
export 'src/map_icons.dart';
export 'src/models.dart';
export 'src/notification_service.dart';
export 'src/phone.dart';
export 'src/repositories/auth_repository.dart';
export 'src/repositories/avatar_repository.dart';
export 'src/repositories/catalog_repository.dart';
export 'src/repositories/diagnostics_repository.dart';
export 'src/repositories/profile_repository.dart';
export 'src/supabase_config.dart';
export 'src/user_avatar.dart';
