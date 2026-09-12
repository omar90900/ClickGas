import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../../widgets/common.dart';

/// Owner settings: prices, service fees, ordering and dispatch, cities and
/// feature flags. Every save goes through an audited admin_* function.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageBody(
      maxWidth: 1100,
      children: [
        _ServicesSection(),
        SizedBox(height: 16),
        _FeesSection(),
        SizedBox(height: 16),
        _ConfigSection(),
        SizedBox(height: 16),
        _CitiesSection(),
        SizedBox(height: 16),
        _FlagsSection(),
      ],
    );
  }
}

// ---------------------------------------------------------------- services

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AsyncView<(List<AdminService>, List<PriceChange>)>(
      load: () async {
        final r = await Future.wait<Object>([repo.services(), repo.priceHistory()]);
        return (r[0] as List<AdminService>, r[1] as List<PriceChange>);
      },
      builder: (context, data, reload) {
        final (services, history) = data;
        final names = {for (final s in services) s.id: s.name(context.lang)};
        return SectionCard(
          title: l.servicesTitle,
          subtitle: l.servicesNote,
          actions: [
            TextButton.icon(
              onPressed: () async {
                if (await _editService(context, null)) await reload();
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l.addService),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in services)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Flexible(child: Text(s.name(context.lang), style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (s.badge != null) ...[const SizedBox(width: 8), Tag(s.badge!, AppColors.info)],
                    ],
                  ),
                  subtitle: Text(s.code, textDirection: TextDirection.ltr),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Fmt.money(context, s.price), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 12),
                      Tooltip(
                        message: l.activeLabel,
                        child: Switch(
                          value: s.isActive,
                          onChanged: (on) async {
                            if (await runAction(context, () => repo.updateService(s.id, isActive: on), success: l.serviceSaved)) {
                              await reload();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: l.edit,
                        onPressed: () async {
                          if (await _editService(context, s)) await reload();
                        },
                        icon: const Icon(Icons.edit_rounded),
                      ),
                    ],
                  ),
                ),
              if (history.isNotEmpty) ...[
                const Divider(),
                Text(l.priceHistory, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                for (final h in history.take(10))
                  InfoRow(
                    label: '${names[h.serviceId] ?? h.serviceId} · ${Fmt.dateTime(context, h.changedAt)}',
                    value: h.oldPrice == null
                        ? Fmt.amount(h.newPrice)
                        : '${Fmt.amount(h.oldPrice!)} → ${Fmt.amount(h.newPrice)}',
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Add ([service] null) or edit a service; true when saved.
  static Future<bool> _editService(BuildContext context, AdminService? service) async {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final formKey = GlobalKey<FormState>();
    final code = TextEditingController(text: service?.code ?? '');
    final nameAr = TextEditingController(text: service?.nameAr ?? '');
    final nameEn = TextEditingController(text: service?.nameEn ?? '');
    final descAr = TextEditingController(text: service?.descriptionAr ?? '');
    final descEn = TextEditingController(text: service?.descriptionEn ?? '');
    final price = TextEditingController(text: service == null ? '' : Fmt.amount(service.price));
    final badge = TextEditingController(text: service?.badge ?? '');
    String? required2(String? v) => (v ?? '').trim().length < 2 ? l.fieldRequired : null;

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(service == null ? l.addService : l.editService),
        content: SizedBox(
          width: 520,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (service == null) ...[
                    TextFormField(
                      controller: code,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: l.code, helperText: l.codeHelper),
                      validator: (v) => RegExp(r'^[a-z][a-z0-9_]{1,30}$').hasMatch(v ?? '') ? null : l.codeHelper,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: nameAr,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(labelText: l.nameAr),
                    validator: required2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameEn,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.nameEn),
                    validator: required2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descAr,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(labelText: l.descriptionAr),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descEn,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.descriptionEn),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: price,
                    inputFormatters: [amountInputFormatter],
                    decoration: InputDecoration(labelText: l.price, suffixText: l.currency, helperText: l.servicesNote),
                    validator: (v) {
                      final p = parseAmount(v ?? '');
                      return p == null || p <= 0 ? l.invalidAmount : null;
                    },
                  ),
                  if (service != null) ...[
                    const SizedBox(height: 12),
                    TextFormField(controller: badge, decoration: InputDecoration(labelText: l.badge)),
                  ],
                ],
              ),
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
    );
    if (save != true || !context.mounted) return false;
    final p = parseAmount(price.text)!;
    return runAction(
      context,
      () => service == null
          ? repo.createService(
              code: code.text.trim(),
              nameAr: nameAr.text.trim(),
              nameEn: nameEn.text.trim(),
              price: p,
              descriptionAr: descAr.text.trim(),
              descriptionEn: descEn.text.trim(),
            )
          : repo.updateService(
              service.id,
              price: p == service.price ? null : p,
              nameAr: nameAr.text.trim(),
              nameEn: nameEn.text.trim(),
              descriptionAr: descAr.text.trim(),
              descriptionEn: descEn.text.trim(),
              badge: badge.text.trim(),
            ),
      success: l.serviceSaved,
    );
  }
}

// ---------------------------------------------------------------- fees

class _FeesSection extends StatelessWidget {
  const _FeesSection();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AsyncView<List<FeeSetting>>(
      load: repo.fees,
      builder: (context, fees, reload) {
        final now = DateTime.now();
        final current = feesInForce(fees, now);
        return SectionCard(
          title: l.feesTitle,
          subtitle: l.feesNote,
          actions: [
            TextButton.icon(
              onPressed: () async {
                if (await _changeFees(context, current)) await reload();
              },
              icon: const Icon(Icons.edit_rounded),
              label: Text(l.changeFees),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (current != null)
                ResponsiveGrid(
                  minTileWidth: 180,
                  children: [
                    KpiCard(label: l.customerFee, value: Fmt.money(context, current.customerFee), icon: Icons.person_rounded),
                    KpiCard(label: l.driverFee, value: Fmt.money(context, current.driverFee), icon: Icons.local_shipping_rounded),
                    KpiCard(label: l.feeTotal, value: Fmt.money(context, current.total), icon: Icons.summarize_rounded),
                  ],
                ),
              const SizedBox(height: 12),
              Text(l.feesHistory, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              for (final f in fees)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${Fmt.amount(f.customerFee)} + ${Fmt.amount(f.driverFee)} = ${Fmt.amount(f.total)}'),
                  subtitle: Text([l.effectiveFromDate(Fmt.dateTime(context, f.effectiveFrom)), ?f.note].join(' · ')),
                  trailing: f.id == current?.id
                      ? Tag(l.inForce, context.accent)
                      : f.isScheduled(now)
                          ? Tag(l.scheduled, AppColors.info)
                          : null,
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool> _changeFees(BuildContext context, FeeSetting? current) async {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    final formKey = GlobalKey<FormState>();
    final customer = TextEditingController(text: current == null ? '' : Fmt.amount(current.customerFee));
    final driver = TextEditingController(text: current == null ? '' : Fmt.amount(current.driverFee));
    final note = TextEditingController();
    DateTime? from;

    String? feeValidator(String? v) {
      final value = parseAmount(v ?? '');
      return value == null || value < 0 || value > 5 ? l.invalidAmount : null;
    }

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.changeFees),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.feesNote, style: ctx.text.bodySmall),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: customer,
                    inputFormatters: [amountInputFormatter],
                    decoration: InputDecoration(labelText: l.customerFee, suffixText: l.currency),
                    validator: feeValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: driver,
                    inputFormatters: [amountInputFormatter],
                    decoration: InputDecoration(labelText: l.driverFee, suffixText: l.currency),
                    validator: feeValidator,
                  ),
                  const SizedBox(height: 12),
                  Text(l.effectiveFrom, style: ctx.text.titleSmall),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text(l.effectiveNow)),
                      ButtonSegment(value: true, label: Text(from == null ? l.pickDateTime : Fmt.dateTime(ctx, from))),
                    ],
                    selected: {from != null},
                    onSelectionChanged: (s) async {
                      if (!s.first) {
                        setState(() => from = null);
                        return;
                      }
                      final now = DateTime.now();
                      final day = await showDatePicker(
                        context: ctx,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        initialDate: now.add(const Duration(days: 1)),
                      );
                      if (day == null || !ctx.mounted) return;
                      final time = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 0, minute: 0));
                      if (time == null) return;
                      setState(() => from = DateTime(day.year, day.month, day.day, time.hour, time.minute));
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: note,
                    maxLength: 200,
                    decoration: InputDecoration(labelText: l.noteLabel, helperText: l.reasonHelper),
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
      () => repo.setFees(
        customerFee: parseAmount(customer.text)!,
        driverFee: parseAmount(driver.text)!,
        effectiveFrom: from,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
      ),
      success: l.feesSaved,
    );
  }
}

// ---------------------------------------------------------------- dispatch settings

class _ConfigSection extends StatelessWidget {
  const _ConfigSection();

  @override
  Widget build(BuildContext context) {
    return AsyncView<ConfigSettings>(
      load: context.read<AdminRepository>().config,
      builder: (context, config, reload) =>
          _ConfigForm(key: ValueKey(config.updatedAt), initial: config, onSaved: reload),
    );
  }
}

class _ConfigForm extends StatefulWidget {
  const _ConfigForm({super.key, required this.initial, required this.onSaved});

  final ConfigSettings initial;
  final Future<void> Function() onSaved;

  @override
  State<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<_ConfigForm> {
  final _formKey = GlobalKey<FormState>();
  late final ConfigSettings c = widget.initial;
  late final _deliveryFee = TextEditingController(text: Fmt.amount(c.deliveryFee));
  late final _maxQuantity = TextEditingController(text: '${c.maxQuantity}');
  late final _searchRadius = TextEditingController(text: _num(c.searchRadiusKm));
  late final _driverRadius = TextEditingController(text: _num(c.driverRadiusKm));
  late final _maxActive = TextEditingController(text: '${c.maxActiveOrders}');
  late final _confirmTimeout = TextEditingController(text: '${c.confirmTimeoutMinutes}');
  late final _supportPhone = TextEditingController(
    text: c.supportPhone == null ? '' : JordanPhone.display(c.supportPhone!),
  );
  late final _minCustomer = TextEditingController(text: c.minCustomerVersion);
  late final _minDistributor = TextEditingController(text: c.minDistributorVersion);
  late bool _autoVerify = c.autoVerifyDrivers;
  bool _saving = false;

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : '$v';

  Future<void> _save() async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final phone = _supportPhone.text.trim();
    final next = <String, Object?>{
      'delivery_fee': parseAmount(_deliveryFee.text),
      'max_quantity': int.parse(_maxQuantity.text.trim()),
      'search_radius_km': double.parse(_searchRadius.text.trim()),
      'driver_radius_km': double.parse(_driverRadius.text.trim()),
      'max_active_orders': int.parse(_maxActive.text.trim()),
      'confirm_timeout_minutes': int.parse(_confirmTimeout.text.trim()),
      'auto_verify_drivers': _autoVerify,
      'support_phone': phone.isEmpty ? null : JordanPhone.normalize(phone),
      'min_customer_version': _minCustomer.text.trim(),
      'min_distributor_version': _minDistributor.text.trim(),
    };
    final before = c.toMap();
    final changes = {
      for (final e in next.entries)
        if (e.value != before[e.key]) e.key: e.value ?? '',
    };
    if (changes.isEmpty) {
      showSnack(context, l.noChanges);
      return;
    }
    setState(() => _saving = true);
    final ok = await runAction(
      context,
      () => context.read<AdminRepository>().updateConfig(changes),
      success: l.settingsSaved,
    );
    if (mounted) setState(() => _saving = false);
    if (ok) await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? intIn(String? v, int min, int max) {
      final n = int.tryParse((v ?? '').trim());
      return n == null || n < min || n > max ? l.rangeError(min, max) : null;
    }

    String? numIn(String? v, double min, double max) {
      final n = double.tryParse((v ?? '').trim());
      return n == null || n < min || n > max ? l.rangeError(_num(min), _num(max)) : null;
    }

    String? version(String? v) => RegExp(r'^\d+\.\d+\.\d+$').hasMatch((v ?? '').trim()) ? null : l.versionError;

    Widget field(TextEditingController controller, String label, String? Function(String?) validator,
            {String? suffix, bool decimal = false}) =>
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: controller,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.]' : r'[0-9]'))],
            decoration: InputDecoration(labelText: label, suffixText: suffix),
            validator: validator,
          ),
        );

    return SectionCard(
      title: l.dispatchTitle,
      subtitle: c.updatedAt == null ? null : l.lastChanged(Fmt.dateTime(context, c.updatedAt)),
      actions: [
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l.save),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            field(_driverRadius, l.driverRadius, (v) => numIn(v, 0.5, 50), suffix: l.km, decimal: true),
            field(_maxActive, l.maxActiveOrdersSetting, (v) => intIn(v, 1, 10)),
            field(_maxQuantity, l.maxQuantity, (v) => intIn(v, 1, 10)),
            field(_searchRadius, l.searchRadius, (v) => numIn(v, 0.5, 100), suffix: l.km, decimal: true),
            field(_confirmTimeout, l.confirmTimeout, (v) => intIn(v, 5, 1440), suffix: l.minutesUnit),
            field(_deliveryFee, l.deliveryFee, (v) {
              final n = parseAmount(v ?? '');
              return n == null || n < 0 || n > 20 ? l.rangeError(0, 20) : null;
            }, suffix: l.currency, decimal: true),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _supportPhone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l.supportPhone),
                validator: (v) =>
                    (v ?? '').trim().isEmpty || JordanPhone.normalize(v!) != null ? null : l.invalidPhone,
              ),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _minCustomer,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l.minCustomerVersion),
                validator: version,
              ),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _minDistributor,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l.minDistributorVersion),
                validator: version,
              ),
            ),
            SizedBox(
              width: 616,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _autoVerify,
                onChanged: (v) => setState(() => _autoVerify = v),
                title: Text(l.autoVerify),
                subtitle: Text(l.autoVerifyHelp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- cities & flags

class _CitiesSection extends StatelessWidget {
  const _CitiesSection();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AsyncView<List<AdminCity>>(
      load: repo.cities,
      builder: (context, cities, reload) => SectionCard(
        title: l.citiesTitle,
        subtitle: l.citiesNote,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in cities)
              FilterChip(
                label: Text(c.name(context.lang)),
                selected: c.isActive,
                onSelected: (on) async {
                  if (await runAction(context, () => repo.setCityActive(c.id, on), success: l.saved)) {
                    await reload();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FlagsSection extends StatelessWidget {
  const _FlagsSection();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final repo = context.read<AdminRepository>();
    return AsyncView<List<FeatureFlag>>(
      load: repo.flags,
      builder: (context, flags, reload) => SectionCard(
        title: l.flagsTitle,
        subtitle: l.flagsNote,
        child: Column(
          children: [
            for (final f in flags)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: f.enabled,
                title: Text(f.key, textDirection: TextDirection.ltr),
                subtitle: Text(f.description),
                onChanged: (on) async {
                  if (await runAction(context, () => repo.setFlag(f.key, on), success: l.saved)) {
                    await reload();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
