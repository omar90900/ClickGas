import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/catalog_repository.dart';
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
  late Future<List<City>> _cities = context.read<CatalogRepository>().cities();
  int? _cityId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password, _confirm]) {
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
      );
      if (signedIn) {
        navigator.popUntil((r) => r.isFirst);
      } else if (mounted) {
        // Email confirmation is still enabled on the Supabase project.
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      title: l.signUpTitle,
      subtitle: l.signUpSubtitle,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
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
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: (v) => JordanPhone.normalize(v ?? '') == null
                      ? l.invalidPhone
                      : null,
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
                    if (snap.hasError) {
                      return OutlinedButton.icon(
                        onPressed: () => setState(() => _cities =
                            context.read<CatalogRepository>().cities()),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('${l.chooseCity} · ${l.retry}'),
                      );
                    }
                    final cities = snap.data ?? const <City>[];
                    return DropdownButtonFormField<int>(
                      initialValue: _cityId,
                      isExpanded: true,
                      validator: (v) => v == null ? l.chooseCity : null,
                      decoration: InputDecoration(
                        labelText: l.city,
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        suffixIcon: snap.hasData
                            ? null
                            : const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
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
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) =>
                      Validators.isEmail(v ?? '') ? null : l.invalidEmail,
                  decoration: InputDecoration(
                    labelText: l.email,
                    hintText: 'name@example.com',
                    prefixIcon: const Icon(Icons.email_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  label: l.password,
                  validator: (v) =>
                      (v == null || v.length < 6) ? l.passwordTooShort : null,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _confirm,
                  label: l.confirmPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  validator: (v) =>
                      v != _password.text ? l.passwordsDontMatch : null,
                ),
              ],
            ),
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
