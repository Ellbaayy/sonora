import 'package:flutter/material.dart';

import 'src/app_shell.dart';
import 'src/data/backend.dart';
import 'src/preview_state.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SonoraBackend? backend;
  String? startupWarning;
  try {
    backend = await SonoraBackend.open();
  } catch (error) {
    // Database rusak atau migrasi gagal tidak boleh membuat aplikasi gagal
    // dibuka; pengguna diberi tahu bahwa perubahan tidak akan tersimpan.
    startupWarning =
        'Data lokal tidak dapat dibuka. Perubahan pengaturan tidak akan '
        'tersimpan pada sesi ini.';
    debugPrint('SONORA: database gagal dibuka ($error)');
  }

  final state = PreviewState(settings: backend?.settings);
  if (backend != null) {
    await state.restorePreferences();
  }

  runApp(SonoraApp(state: state, startupWarning: startupWarning));
}

class SonoraApp extends StatefulWidget {
  const SonoraApp({super.key, this.state, this.startupWarning});

  /// Status yang disuntikkan dari `main`; bila `null` aplikasi membuat sendiri.
  final PreviewState? state;

  /// Pesan yang ditampilkan sekali ketika lapisan data gagal disiapkan.
  final String? startupWarning;

  @override
  State<SonoraApp> createState() => _SonoraAppState();
}

class _SonoraAppState extends State<SonoraApp> {
  late final PreviewState state;
  late final bool _ownsState;

  @override
  void initState() {
    super.initState();
    _ownsState = widget.state == null;
    state = widget.state ?? PreviewState();
  }

  @override
  void dispose() {
    if (_ownsState) state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PreviewScope(
      state: state,
      child: AnimatedBuilder(
        animation: state,
        builder: (context, _) => MaterialApp(
          title: 'SONORA',
          debugShowCheckedModeBanner: false,
          theme: sonoraTheme(
            cyanAccent: state.cyanAccent,
            reduceMotion: state.reduceMotion,
          ),
          home: AppShell(startupWarning: widget.startupWarning),
        ),
      ),
    );
  }
}

class PreviewScope extends InheritedNotifier<PreviewState> {
  const PreviewScope({
    super.key,
    required PreviewState state,
    required super.child,
  }) : super(notifier: state);

  static PreviewState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PreviewScope>();
    assert(scope != null, 'PreviewScope tidak ditemukan.');
    return scope!.notifier!;
  }
}
