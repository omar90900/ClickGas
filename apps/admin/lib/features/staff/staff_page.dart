import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../state/staff_session.dart';
import '../../widgets/common.dart';

/// Owner only: who is staff and with which role
/// (docs/runbooks/staff-accounts.md).
class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  Future<bool> _add(BuildContext context) async {
    final l = context.l10n;
    final formKey = GlobalKey<FormState>();
    final login = TextEditingController();
    var role = StaffRole.support;

    String? normalized(String input) {
      final v = input.trim();
      if (Validators.isEmail(v)) return v.toLowerCase();
      return JordanPhone.normalize(v);
    }

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.addStaff),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: login,
                    autofocus: true,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.staffLoginLabel, helperText: l.staffLoginHelp, helperMaxLines: 3),
                    validator: (v) => normalized(v ?? '') == null ? l.invalidLogin : null,
                  ),
                  const SizedBox(height: 16),
                  Text(l.role, style: ctx.text.titleSmall),
                  RadioGroup<StaffRole>(
                    groupValue: role,
                    onChanged: (r) => setState(() => role = r ?? role),
                    child: Column(
                      children: [
                        for (final r in StaffRole.values)
                          RadioListTile<StaffRole>(
                            contentPadding: EdgeInsets.zero,
                            value: r,
                            title: Text(staffRoleLabel(l, r)),
                            subtitle: Text(staffRoleDescription(l, r)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
    if (save != true || !context.mounted) return false;
    return runAction(
      context,
      () => context.read<AdminRepository>().saveStaff(normalized(login.text)!, role),
      success: l.staffSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final me = context.watch<StaffSession>().me;

    return AsyncView<List<StaffMember>>(
      load: repo.staff,
      builder: (context, staff, reload) => PageBody(
        maxWidth: 1100,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.staffNote,
                    style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () async {
                  if (await _add(context)) await reload();
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(l.addStaff),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TableCard(
            columns: [
              DataColumn(label: Text(l.colName)),
              DataColumn(label: Text(l.email)),
              DataColumn(label: Text(l.colRole)),
              DataColumn(label: Text(l.colSince)),
              const DataColumn(label: SizedBox.shrink()),
            ],
            rows: [
              for (final s in staff)
                DataRow(cells: [
                  DataCell(TwoLine(
                    s.userId == me?.userId ? '${s.fullName} (${l.you})' : s.fullName,
                    s.phone == null ? null : Fmt.phone(s.phone!),
                    ltrSubtitle: true,
                  )),
                  DataCell(Text(s.email ?? '-')),
                  DataCell(DropdownButton<StaffRole>(
                    value: s.role,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final r in StaffRole.values)
                        DropdownMenuItem(value: r, child: Text(staffRoleLabel(l, r))),
                    ],
                    onChanged: (r) async {
                      if (r == null || r == s.role) return;
                      final login = s.email ?? s.phone;
                      if (login == null) return;
                      if (await runAction(context, () => repo.saveStaff(login, r), success: l.staffSaved)) {
                        await reload();
                      }
                    },
                  )),
                  DataCell(Text(Fmt.date(context, s.createdAt))),
                  DataCell(IconButton(
                    tooltip: l.removeStaff,
                    icon: const Icon(Icons.person_remove_rounded, color: AppColors.danger),
                    onPressed: () async {
                      if (!await confirmDialog(context, l.removeStaffConfirm(s.fullName),
                          confirmLabel: l.removeStaff, destructive: true)) {
                        return;
                      }
                      if (!context.mounted) return;
                      if (await runAction(context, () => repo.removeStaff(s.userId), success: l.staffRemoved)) {
                        await reload();
                      }
                    },
                  )),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}
