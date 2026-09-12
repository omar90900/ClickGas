import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/driver_repository.dart';
import '../../state/driver_session.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.driver,
  });

  final Profile profile;
  final DriverProfile driver;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone =
      TextEditingController(text: JordanPhone.display(widget.profile.phone));
  late final _plate = TextEditingController(text: widget.driver.vehiclePlate);
  late final _agency = TextEditingController(text: widget.driver.agencyName);
  late final Future<List<City>> _cities =
      context.read<CatalogRepository>().cities();
  late int? _cityId = widget.profile.cityId;
  late String? _vehicleType = vehicleTypes.contains(widget.driver.vehicleType)
      ? widget.driver.vehicleType
      : null;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _plate, _agency]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l = context.l10n;
    final session = context.read<DriverSession>();
    final navigator = Navigator.of(context);
    try {
      final profile = await context.read<ProfileRepository>().update(
            widget.profile.id,
            fullName: _name.text,
            phone: JordanPhone.normalize(_phone.text)!,
            cityId: _cityId,
          );
      if (!mounted) return;
      final driver = await context.read<DriverRepository>().update(
        widget.driver.id,
        {
          'vehicle_plate': _plate.text.trim(),
          'vehicle_model': _vehicleType,
          'agency_name': _agency.text.trim(),
        },
      );
      session
        ..setProfile(profile)
        ..setDriver(driver);
      if (!mounted) return;
      showSnack(context, l.profileSaved);
      navigator.pop();
    } on AppFailure catch (f) {
      if (mounted) showSnack(context, failureText(context, f), error: true);
    } catch (_) {
      if (mounted) showSnack(context, l.errorGeneric, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionTitle(l.personalInfo),
            TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? l.invalidName : null,
              decoration: InputDecoration(
                labelText: l.fullName,
                prefixIcon: const Icon(Icons.person_rounded),
              ),
            ),
            gap,
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              validator: (v) =>
                  JordanPhone.normalize(v ?? '') == null ? l.invalidPhone : null,
              decoration: InputDecoration(
                labelText: l.phone,
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
              ),
            ),
            gap,
            FutureBuilder<List<City>>(
              future: _cities,
              builder: (context, snap) {
                final cities = snap.data ?? const <City>[];
                return DropdownButtonFormField<int>(
                  initialValue:
                      cities.any((c) => c.id == _cityId) ? _cityId : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.city,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                  items: [
                    for (final c in cities)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name(context.lang)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _cityId = v),
                );
              },
            ),
            const SizedBox(height: 20),
            SectionTitle(l.vehicleInfo),
            TextFormField(
              controller: _plate,
              textDirection: TextDirection.ltr,
              validator: _required,
              decoration: InputDecoration(
                labelText: l.vehiclePlate,
                prefixIcon: const Icon(Icons.pin_rounded),
              ),
            ),
            gap,
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              isExpanded: true,
              validator: (v) => v == null ? l.chooseVehicleType : null,
              decoration: InputDecoration(
                labelText: l.vehicleType,
                prefixIcon: const Icon(Icons.local_shipping_rounded),
              ),
              items: [
                for (final t in vehicleTypes)
                  DropdownMenuItem(value: t, child: Text(vehicleTypeLabel(l, t))),
              ],
              onChanged: (v) => setState(() => _vehicleType = v),
            ),
            gap,
            TextFormField(
              controller: _agency,
              validator: _required,
              decoration: InputDecoration(
                labelText: l.agencyName,
                prefixIcon: const Icon(Icons.store_rounded),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const ButtonSpinner() : Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
