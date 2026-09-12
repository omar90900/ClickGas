import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/driver_session.dart';
import '../../widgets/common.dart';

String documentKindLabel(BuildContext context, DocumentKind kind) {
  final l = context.l10n;
  return switch (kind) {
    DocumentKind.nationalId => l.docNationalId,
    DocumentKind.drivingLicence => l.docDrivingLicence,
    DocumentKind.vehicleRegistration => l.docVehicleRegistration,
    DocumentKind.agencyLetter => l.docAgencyLetter,
  };
}

/// Papers for approval: one photo per kind, stored in the private
/// `driver-docs` bucket and reviewed from the admin dashboard.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<DriverDocument>> _docs = _load();
  DocumentKind? _busy;

  Future<List<DriverDocument>> _load() => context
      .read<DriverDocumentsRepository>()
      .list(context.read<DriverSession>().driver!.id);

  Future<void> _upload(DocumentKind kind) async {
    final l = context.l10n;
    final repo = context.read<DriverDocumentsRepository>();
    final session = context.read<DriverSession>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(documentKindLabel(ctx, kind), style: ctx.text.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(l.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final bytes = await repo.pick(source);
    if (bytes == null || !mounted) return;
    setState(() => _busy = kind);
    try {
      await repo.upload(driverId: session.driver!.id, kind: kind, bytes: bytes);
      // A rejected distributor goes back to "under review" after uploading.
      await session.refreshDriver();
      if (mounted) {
        showSnack(context, l.documentUploaded);
        setState(() => _docs = _load());
      }
    } catch (e) {
      if (mounted) showSnack(context, failureText(context, e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.documentsTitle)),
      body: FutureBuilder<List<DriverDocument>>(
        future: _docs,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingView();
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: failureText(context, snap.error!),
              action: OutlinedButton(
                onPressed: () => setState(() => _docs = _load()),
                child: Text(l.retry),
              ),
            );
          }
          final docs = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(l.documentsNote, style: context.text.bodyMedium),
              const SizedBox(height: 16),
              for (final kind in DocumentKind.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DocumentCard(
                    kind: kind,
                    doc: docs.where((d) => d.kind == kind).firstOrNull,
                    busy: _busy == kind,
                    onUpload: _busy == null ? () => _upload(kind) : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.kind, required this.doc, required this.busy, this.onUpload});

  final DocumentKind kind;
  final DriverDocument? doc;
  final bool busy;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = doc;
    final (label, color) = switch (d?.status) {
      null => (l.docMissing, Colors.grey),
      DocumentStatus.pending => (l.docPending, AppColors.warning),
      DocumentStatus.approved => (l.docApproved, context.accent),
      DocumentStatus.rejected => (l.docRejected, AppColors.danger),
    };
    return Card(
      child: ListTile(
        leading: Icon(
          d == null ? Icons.upload_file_rounded : Icons.description_rounded,
          color: color,
        ),
        title: Text(documentKindLabel(context, kind), style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Tag(label, color),
            if (d?.reviewNote != null) ...[
              const SizedBox(height: 4),
              Text(l.reviewNote(d!.reviewNote!)),
            ],
          ],
        ),
        trailing: busy
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
            : d?.status == DocumentStatus.approved
                ? null
                : TextButton(onPressed: onUpload, child: Text(d == null ? l.upload : l.replace)),
      ),
    );
  }
}
