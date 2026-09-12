import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../state/session_controller.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';
import 'welcome_screen.dart';

/// Routes by session state: welcome -> (login/sign-up) -> main shell.
/// Driver/admin accounts are recognised now so the driver app can plug in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final l = context.l10n;
    switch (session.status) {
      case SessionStatus.initializing:
      case SessionStatus.loadingProfile:
        return const SplashScreen();
      case SessionStatus.signedOut:
        return const WelcomeScreen();
      case SessionStatus.profileError:
        return MessageScreen(
          icon: Icons.cloud_off_rounded,
          color: AppColors.warning,
          title: l.profileMissing,
          body: l.errorGeneric,
          actions: [
            FilledButton(onPressed: session.retry, child: Text(l.retry)),
            TextButton(onPressed: session.signOut, child: Text(l.logout)),
          ],
        );
      case SessionStatus.ready:
        final profile = session.profile!;
        if (!profile.isActive) {
          return MessageScreen(
            icon: Icons.block_rounded,
            color: AppColors.danger,
            title: l.accountDisabledTitle,
            body: l.accountDisabledBody,
            actions: [
              OutlinedButton(onPressed: session.signOut, child: Text(l.logout)),
            ],
          );
        }
        if (profile.role != UserRole.customer) {
          return MessageScreen(
            icon: Icons.local_shipping_rounded,
            color: AppColors.info,
            title: l.driverAccountTitle,
            body: l.driverAccountBody,
            actions: [
              OutlinedButton(onPressed: session.signOut, child: Text(l.logout)),
            ],
          );
        }
        return const MainShell();
    }
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLogo(size: 110),
            const SizedBox(height: 20),
            Text(
              context.l10n.appName,
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.tagline,
              style: context.text.bodyLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: color),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final a in actions) ...[a, const SizedBox(height: 8)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
