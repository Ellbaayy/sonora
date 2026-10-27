import 'package:flutter/material.dart';

import 'src/app_shell.dart';
import 'src/preview_state.dart';
import 'src/theme.dart';

void main() => runApp(const SonoraApp());

class SonoraApp extends StatefulWidget {
  const SonoraApp({super.key});
  @override
  State<SonoraApp> createState() => _SonoraAppState();
}

class _SonoraAppState extends State<SonoraApp> {
  late final PreviewState state;

  @override
  void initState() {
    super.initState();
    state = PreviewState();
  }

  @override
  void dispose() {
    state.dispose();
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
          home: const AppShell(),
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
