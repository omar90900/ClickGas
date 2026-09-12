import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/common.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _plate = TextEditingController();
  final _agency = TextEditingController();
  late Future<List<City>> _cities = context.read<CatalogRepository>().cities();
  int? _cityId;
  String? _vehicleType;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password, _confirm, _plate, _agency]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthRepository>();
    final navigator = Navigator.of(context);
    final l = context.l10n;
    try {
      final signedIn = await auth.signUp(
        fullName: _name.text,
        phone: JordanPhone.normalize(_phone.text)!,
        email: _email.text,
        password: _password.text,
        cityId: _cityId!,
        extra: {
          'account_type': 'driver',
          'vehicle_plate': _plate.text.trim(),
          'vehicle_type': _vehicleType,
          'agency_name': _agency.text.trim(),
        },
      );
      if (signedIn) {
        navigator.popUntil((r) => r.isFirst);
      } else if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l.emailConfirmationRequired),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.close),
              ),
            ],
          ),
        );
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = authFailureMessage(context, f));
    } catch (_) {
      if (mounted) setState(() => _error = l.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.l10n.fieldRequired : null;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const gap = SizedBox(height: 14);
    return AuthScaffold(
      title: l.signUpTitle,
      subtitle: l.signUpSubtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(l.personalInfo),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    JordanPhone.normalize(v ?? '') == null ? l.invalidPhone : null,
                decoration: InputDecoration(
                  labelText: l.phone,
                  hintText: l.phoneHint,
                  prefixIcon: const Icon(Icons.phone_iphone_rounded),
                ),
              ),
              gap,
              FutureBuilder<List<City>>(
                future: _cities,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return OutlinedButton.icon(
                      onPressed: () => setState(() =>
                          _cities = context.read<CatalogRepository>().cities()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('${l.chooseCity} · ${l.retry}'),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _cityId,
                    isExpanded: true,
                    validator: (v) => v == null ? l.chooseCity : null,
                    decoration: InputDecoration(
                      labelText: l.city,
                      prefixIcon: const Icon(Icons.location_city_rounded),
                    ),
                    hint: Text(l.chooseCity),
                    items: [
                      for (final c in snap.data ?? const <City>[])
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name(context.lang)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _cityId = v),
                  );
                },
              ),
              gap,
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                validator: (v) =>
                    Validators.isEmail(v ?? '') ? null : l.invalidEmail,
                decoration: InputDecoration(
                  labelText: l.email,
                  hintText: 'name@example.com',
                  prefixIcon: const Icon(Icons.email_rounded),
                ),
              ),
              gap,
              PasswordField(
                controller: _password,
                label: l.password,
                validator: (v) =>
                    (v == null || v.length < 6) ? l.passwordTooShort : null,
              ),
              gap,
              PasswordField(
                controller: _confirm,
                label: l.confirmPassword,
                validator: (v) =>
                    v != _password.text ? l.passwordsDontMatch : null,
              ),
              const SizedBox(height: 20),
              SectionTitle(l.vehicleInfo),
              TextFormField(
                controller: _plate,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                validator: _required,
                decoration: InputDecoration(
                  labelText: l.vehiclePlate,
                  hintText: l.vehiclePlateHint,
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
                hint: Text(l.chooseVehicleType),
                items: [
                  for (final t in vehicleTypes)
                    DropdownMenuItem(
                      value: t,
                      child: Text(vehicleTypeLabel(l, t)),
                    ),
                ],
                onChanged: (v) => setState(() => _vehicleType = v),
              ),
              gap,
              TextFormField(
                controller: _agency,
                textInputAction: TextInputAction.done,
                validator: _required,
                onFieldSubmitted: (_) => _busy ? null : _submit(),
                decoration: InputDecoration(
                  labelText: l.agencyName,
                  hintText: l.agencyNameHint,
                  prefixIcon: const Icon(Icons.store_rounded),
                ),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy ? const ButtonSpinner() : Text(l.createAccount),
        ),
        const SizedBox(height: 8),
        AuthSwitchLink(
          question: l.haveAccount,
          action: l.loginNow,
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      ],
    );
  }
}
