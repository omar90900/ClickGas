import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/common.dart';

/// Current password, then the new one twice. The current password is
/// checked by signing in again (AuthRepository.changePassword).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _hidden = true;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final auth = context.read<AuthRepository>();
    final email = auth.currentUser?.email;
    if (email == null) return;
    setState(() => _busy = true);
    try {
      await auth.changePassword(
        email: email,
        currentPassword: _current.text,
        newPassword: _new.text,
      );
      if (!mounted) return;
      showSnack(context, l.passwordChanged);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final wrong = AppFailure.from(e).code == FailureCode.invalidCredentials;
      showSnack(context, wrong ? l.wrongCurrentPassword : failureText(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required String? Function(String?) validator,
    required String autofill,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: _hidden,
      textInputAction: action,
      autofillHints: [autofill],
      validator: validator,
      onFieldSubmitted: action == TextInputAction.done ? (_) => _submit() : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.changePassword)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: context.isDark ? 0.16 : 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset_rounded, size: 36, color: context.accent),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.changePasswordBody,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: context.muted),
                ),
                const SizedBox(height: 24),
                _field(
                  _current,
                  l.currentPassword,
                  autofill: AutofillHints.password,
                  validator: (v) => (v == null || v.isEmpty) ? l.passwordTooShort : null,
                ),
                const SizedBox(height: 14),
                _field(
                  _new,
                  l.newPassword,
                  autofill: AutofillHints.newPassword,
                  validator: (v) {
                    if (v == null || v.length < 6) return l.passwordTooShort;
                    if (v == _current.text) return l.samePassword;
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  _confirm,
                  l.confirmPassword,
                  autofill: AutofillHints.newPassword,
                  action: TextInputAction.done,
                  validator: (v) => v != _new.text ? l.passwordsDontMatch : null,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(l.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
