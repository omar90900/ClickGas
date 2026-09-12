import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/common.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';

/// Kept for the auth screens; every message comes from [failureText].
String authFailureMessage(BuildContext context, AppFailure f) =>
    failureText(context, f);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _byPhone = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
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
    try {
      if (_byPhone) {
        await auth.signInWithPhone(
          JordanPhone.normalize(_identifier.text)!,
          _password.text,
        );
      } else {
        await auth.signInWithEmail(_identifier.text, _password.text);
      }
      // AuthGate now shows the main shell underneath.
      navigator.popUntil((r) => r.isFirst);
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = authFailureMessage(context, f));
    } catch (e) {
      if (mounted) setState(() => _error = failureText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AuthScaffold(
      showLogo: true,
      title: l.loginTitle,
      subtitle: l.loginSubtitle,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(l.loginWithPhone),
            ),
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.email_rounded),
              label: Text(l.loginWithEmail),
            ),
          ],
          selected: {_byPhone},
          onSelectionChanged: (s) => setState(() {
            _byPhone = s.first;
            _identifier.clear();
            _error = null;
          }),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  key: ValueKey(_byPhone),
                  controller: _identifier,
                  keyboardType: _byPhone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textDirection: TextDirection.ltr,
                  autofillHints: [
                    _byPhone
                        ? AutofillHints.telephoneNumber
                        : AutofillHints.email,
                  ],
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return l.fieldRequired;
                    if (_byPhone && JordanPhone.normalize(value) == null) {
                      return l.invalidPhone;
                    }
                    if (!_byPhone && !Validators.isEmail(value)) {
                      return l.invalidEmail;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: _byPhone ? l.phone : l.email,
                    hintText: _byPhone ? l.phoneHint : 'name@example.com',
                    prefixIcon: Icon(
                      _byPhone
                          ? Icons.phone_iphone_rounded
                          : Icons.email_rounded,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  label: l.password,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _submit(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l.fieldRequired : null,
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
          child: _busy ? const ButtonSpinner() : Text(l.loginBtn),
        ),
        const SizedBox(height: 8),
        AuthSwitchLink(
          question: l.noAccount,
          action: l.signUpNow,
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SignUpScreen()),
          ),
        ),
      ],
    );
  }
}
