import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors.dart';
import '../logger.dart';
import '../models.dart';

/// Distributor papers (national ID, licence, registration, agency letter).
///
/// Files go to the private `driver-docs` bucket at
/// `<driver id>/<kind>-<timestamp>.jpg`; `submit_driver_document` records the
/// current file per kind and puts it back to pending review. Distributors
/// read their own; staff read all (docs/api.md#staff).
class DriverDocumentsRepository {
  DriverDocumentsRepository(this._client);

  final SupabaseClient _client;
  final _picker = ImagePicker();

  static const bucket = 'driver-docs';

  Future<List<DriverDocument>> list(String driverId) =>
      guard('documents.list', () async {
        final rows = await _client
            .from('driver_documents')
            .select()
            .eq('driver_id', driverId)
            .order('kind', ascending: true);
        return rows.map(DriverDocument.fromMap).toList();
      });

  /// Camera or gallery; a readable JPEG (papers need more pixels than a
  /// profile photo) or null if cancelled.
  Future<Uint8List?> pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 80,
    );
    return file?.readAsBytes();
  }

  Future<DriverDocument> upload({
    required String driverId,
    required DocumentKind kind,
    required Uint8List bytes,
    DateTime? expiresOn,
  }) =>
      guard('documents.upload', () async {
        final path =
            '$driverId/${kind.value}-${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _client.storage.from(bucket).uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        final row = await _client.rpc('submit_driver_document', params: {
          'p_kind': kind.value,
          'p_file_path': path,
          'p_expires_on': expiresOn == null
              ? null
              : '${expiresOn.year.toString().padLeft(4, '0')}-'
                  '${expiresOn.month.toString().padLeft(2, '0')}-'
                  '${expiresOn.day.toString().padLeft(2, '0')}',
        });
        Log.i('document_uploaded', {'kind': kind.value});
        return DriverDocument.fromMap(Map<String, dynamic>.from(row as Map));
      }, context: {'kind': kind.value});

  /// A link to view a private file, valid for [seconds].
  Future<String> viewUrl(String path, {int seconds = 600}) =>
      guard('documents.view_url', () {
        return _client.storage.from(bucket).createSignedUrl(path, seconds);
      });
}
