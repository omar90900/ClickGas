import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/models.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../state/session_controller.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final Profile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone =
      TextEditingController(text: JordanPhone.display(widget.profile.phone));
  late final Future<List<City>> _cities =
      context.read<CatalogRepository>().cities();
  late int? _cityId = widget.profile.cityId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l = context.l10n;
    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);
    try {
      final updated = await context.read<ProfileRepository>().update(
            widget.profile.id,
            fullName: _name.text,
            phone: JordanPhone.normalize(_phone.text)!,
            cityId: _cityId,
          );
      session.updateProfile(updated);
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? l.invalidName : null,
              decoration: InputDecoration(
                labelText: l.fullName,
                prefixIcon: const Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              validator: (v) =>
                  JordanPhone.normalize(v ?? '') == null ? l.invalidPhone : null,
              decoration: InputDecoration(
                labelText: l.phone,
                hintText: l.phoneHint,
                prefixIcon: const Icon(Icons.phone_iphone_rounded),
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<City>>(
              future: _cities,
              builder: (context, snap) {
                final cities = snap.data ?? const <City>[];
                final known = cities.any((c) => c.id == _cityId);
                return DropdownButtonFormField<int>(
                  initialValue: known ? _cityId : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.city,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                  hint: Text(l.chooseCity),
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
            const SizedBox(height: 14),
            TextFormField(
              initialValue: widget.profile.email ?? '',
              enabled: false,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l.email,
                prefixIcon: const Icon(Icons.email_rounded),
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
