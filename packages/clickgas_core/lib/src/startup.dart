import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'logger.dart';
import 'ui/connecting_splash.dart';

/// Starts an app safely. The launch animation is drawn at once, so Android's
/// launch image goes away immediately; meanwhile [start] loads plugins,
/// settings and Supabase and returns the root widget, which fades in. If it
/// throws or takes longer than [timeout], the app shows [StartupErrorApp]
/// instead of waiting forever (docs/runbooks/app-stuck-on-launch.md).
Future<void> runGuardedApp({
  required String app,
  required Future<Widget> Function() start,
  Duration timeout = const Duration(seconds: 30),
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.install(app: app);
  runApp(_Boot(start: start, timeout: timeout));
}

class _Boot extends StatefulWidget {
  const _Boot({required this.start, required this.timeout});

  final Future<Widget> Function() start;
  final Duration timeout;

  @override
  State<_Boot> createState() => _BootState();
}

class _BootState extends State<_Boot> {
  Widget? _root;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    Widget root;
    try {
      root = await widget.start().timeout(widget.timeout);
    } catch (error, stack) {
      Log.e('startup_failed', {'error': error.toString()}, error, stack);
      root = StartupErrorApp(error: error);
    }
    if (mounted) setState(() => _root = root);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _root == null
            ? MaterialApp(
                key: const ValueKey('boot'),
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                home: const ConnectingSplash(),
              )
            : KeyedSubtree(key: const ValueKey('app'), child: _root!),
      ),
    );
  }
}

/// Shown when the app could not start (a native plugin failed to load, the
/// server did not answer, ...). Bilingual because settings may not have loaded.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final detail = error is TimeoutException
        ? 'Startup took too long. Check the internet connection.'
        : error.toString();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.danger),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذّر تشغيل كليك غاز',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'ClickGas could not start',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'أغلق التطبيق وافتحه مجدداً. إذا تكرر ذلك أرسل صورة لهذه الشاشة للدعم.\n'
                    'Close and reopen the app. If it keeps happening, send a screenshot of this screen to support.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      detail,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => SystemNavigator.pop(),
                    child: const Text('إغلاق · Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
