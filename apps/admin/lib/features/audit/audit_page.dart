import 'dart:convert';

import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';
import '../drivers/driver_detail.dart';
import '../orders/order_inspector.dart';

/// Every staff action, newest first (`admin_actions`), filterable by what
/// it touched. Orders and distributors open their panels.
class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  static const _pageSize = 50;
  static const _targets = ['driver', 'user', 'order', 'service', 'fees', 'config', 'city', 'flag', 'staff'];

  String? _target;
  final List<AdminAction> _items = [];
  bool _loading = false;
  bool _done = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _items.clear();
        _done = false;
      }
    });
    try {
      final page = await context
          .read<AdminRepository>()
          .audit(targetType: _target, limit: _pageSize, offset: _items.length);
      if (!mounted) return;
      setState(() {
        _items.addAll(page);
        _done = page.length < _pageSize;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(AdminAction a) {
    final id = a.targetId;
    if (id == null) return;
    if (a.targetType == 'order') showOrderInspector(context, id);
    if (a.targetType == 'driver') showDriverDetail(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l.all),
                selected: _target == null,
                onSelected: (_) {
                  _target = null;
                  _loadMore(reset: true);
                },
              ),
              for (final t in _targets)
                ChoiceChip(
                  label: Text(targetTypeLabel(l, t)),
                  selected: _target == t,
                  onSelected: (_) {
                    _target = t;
                    _loadMore(reset: true);
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty && _loading
              ? const LoadingView()
              : _items.isEmpty && _error != null
                  ? ErrorView(error: _error!, onRetry: () => _loadMore(reset: true))
                  : _items.isEmpty
                      ? EmptyState(icon: Icons.history_rounded, title: l.noAudit)
                      : PageBody(
                          maxWidth: 1100,
                          children: [
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (final a in _items) _AuditTile(action: a, onOpen: () => _open(a)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_error != null) Text(failureText(context, _error!), textAlign: TextAlign.center),
                            if (!_done)
                              Center(
                                child: OutlinedButton(
                                  onPressed: _loading ? null : _loadMore,
                                  child: Text(l.loadMore),
                                ),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.action, required this.onOpen});

  final AdminAction action;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final a = action;
    final number = a.detail['order_number'];
    final openable = a.targetId != null && (a.targetType == 'order' || a.targetType == 'driver');
    final who = [a.actorName ?? '-', if (a.actorRole != null) staffRoleLabel(l, a.actorRole!)].join(' · ');
    return ExpansionTile(
      leading: const Icon(Icons.admin_panel_settings_rounded),
      title: Text(
        [actionLabel(l, a.action), if (number != null) '#$number'].join(' '),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [who, Fmt.dateTime(context, a.createdAt), if (a.reason != null) '“${a.reason}”'].join(' · '),
      ),
      childrenPadding: const EdgeInsetsDirectional.fromSTEB(72, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${targetTypeLabel(l, a.targetType)}: ', style: context.text.bodySmall),
            Expanded(
              child: SelectableText(a.targetId ?? '-',
                  textDirection: TextDirection.ltr, style: context.text.bodySmall),
            ),
            if (openable) TextButton(onPressed: onOpen, child: Text(l.open)),
          ],
        ),
        if (a.detail.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(a.detail),
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
      ],
    );
  }
}
