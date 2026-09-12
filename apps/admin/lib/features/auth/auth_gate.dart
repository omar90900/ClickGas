import 'package:clickgas_core/clickgas_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/staff_session.dart';
import '../../widgets/common.dart';
import '../shell/admin_shell.dart';

/// Routes by staff session: sign-in -> (not staff | error) -> dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<StaffSession>();
    final l = context.l10n;
    return switch (session.status) {
      StaffStatus.initializing || StaffStatus.loading => const Scaffold(body: LoadingView()),
      StaffStatus.signedOut => const LoginScreen(),
      StaffStatus.notStaff => _Message(
          icon: Icons.no_accounts_rounded,
          color: AppColors.warning,
          title: l.notStaffTitle,
          body: l.notStaffBody,
          actions: [OutlinedButton(onPressed: session.signOut, child: Text(l.signOut))],
        ),
      StaffStatus.error => _Message(
          icon: Icons.cloud_off_rounded,
          color: AppColors.danger,
          title: l.sessionErrorTitle,
          body: '${l.sessionErrorBody}\n\n${failureText(context, session.error ?? '')}',
          actions: [
            FilledButton(onPressed: session.retry, child: Text(l.retry)),
            TextButton(onPressed: session.signOut, child: Text(l.signOut)),
          ],
        ),
      StaffStatus.ready => const AdminShell(),
    };
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<StaffSession>().signIn(_email.text, _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = failureText(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.watch<AppSettings>();
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandLogo(size: 72)),
                        const SizedBox(height: 16),
                        Text(
                          l.appName,
                          textAlign: TextAlign.center,
                          style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.signInSubtitle,
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          autofillHints: const [AutofillHints.email, AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: l.email,
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                          ),
                          validator: (v) => Validators.isEmail(v ?? '') ? null : l.invalidEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: l.password,
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                            ),
                          ),
                          validator: (v) => (v ?? '').isEmpty ? l.passwordRequired : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.danger)),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : Text(l.signIn),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => settings.setLocale(
                              Locale(context.lang == 'ar' ? 'en' : 'ar'),
                            ),
                            icon: const Icon(Icons.translate_rounded),
                            label: Text(context.lang == 'ar' ? l.english : l.arabic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: icon,
        color: color,
        title: title,
        message: body,
        action: Wrap(spacing: 8, children: actions),
      ),
    );
  }
}
