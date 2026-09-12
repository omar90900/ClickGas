import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';

/// Profile photos in the public `avatars` bucket at `<user id>/avatar.jpg`.
/// The URL (with a cache-busting version) is stored in `profiles.avatar_url`.
class AvatarRepository {
  AvatarRepository(this._client);

  final SupabaseClient _client;
  final _picker = ImagePicker();

  static const _bucket = 'avatars';

  String _path(String userId) => '$userId/avatar.jpg';

  /// Opens the camera or gallery; returns a small JPEG or null if cancelled.
  Future<Uint8List?> pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );
    return file?.readAsBytes();
  }

  Future<String> upload(String userId, Uint8List bytes) =>
      guard('avatar.upload', () async {
        final storage = _client.storage.from(_bucket);
        await storage.uploadBinary(
          _path(userId),
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        final url = '${storage.getPublicUrl(_path(userId))}'
            '?v=${DateTime.now().millisecondsSinceEpoch}';
        await _client
            .from('profiles')
            .update({'avatar_url': url})
            .eq('id', userId);
        return url;
      });

  Future<void> remove(String userId) => guard('avatar.remove', () async {
        await _client.storage.from(_bucket).remove([_path(userId)]);
        await _client
            .from('profiles')
            .update({'avatar_url': null})
            .eq('id', userId);
      });
}
