import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';

import 'src/app_shell.dart';
import 'src/app_state.dart';
import 'src/data/backend.dart';
import 'src/data/database.dart';
import 'src/media/media_library.dart';
import 'src/playback/audio_handler.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pemutaran berjalan di background service agar notifikasi media dan kontrol
  // headset bekerja. Konfigurasi sesi audio memakai profil musik.
  final handler = await AudioService.init(
    builder: SonoraAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'id.sonora.sonora.audio',
      androidNotificationChannelName: 'Pemutaran SONORA',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (error) {
    debugPrint('SONORA: sesi audio tidak dapat dikonfigurasi ($error)');
  }
  final engine = AudioServiceEngine(handler);

  SonoraBackend? backend;
  String? startupWarning;
  try {
    backend = await SonoraBackend.open();
  } catch (error) {
    // Database rusak atau migrasi gagal tidak boleh membuat aplikasi gagal
    // dibuka. Mode sementara memakai database di memori agar UI tetap dapat
    // dipakai, dengan pemberitahuan bahwa perubahan tidak tersimpan.
    debugPrint('SONORA: database gagal dibuka ($error)');
    startupWarning =
        'Penyimpanan lokal tidak dapat dibuka. Perubahan pada sesi ini tidak '
        'akan tersimpan setelah aplikasi ditutup.';
    backend = SonoraBackend(SonoraDatabase(NativeDatabase.memory()));
  }

  MediaLibraryService? library;
  try {
    final storage = await MediaStorage.open();
    library = MediaLibraryService(
      backend: backend,
      picker: FilePickerMediaPicker(),
      storage: storage,
    );
  } catch (error) {
    debugPrint('SONORA: penyimpanan media tidak siap ($error)');
    startupWarning ??=
        'Folder media aplikasi tidak dapat disiapkan. Impor dinonaktifkan '
        'pada sesi ini.';
  }

  final state = SonoraState(
    engine,
    backend: backend,
    library: library,
    disposeEngine: false,
  );
  // Tombol next/previous pada notifikasi memakai aturan urutan yang sama
  // dengan UI (antrean lebih dulu, lalu library).
  handler.onSkipNext = state.next;
  handler.onSkipPrevious = state.previous;
  await state.init();

  runApp(SonoraApp(state: state, startupWarning: startupWarning));
}

class SonoraApp extends StatelessWidget {
  const SonoraApp({super.key, required this.state, this.startupWarning});

  final SonoraState state;

  /// Pesan yang ditampilkan sekali ketika lapisan data gagal disiapkan.
  final String? startupWarning;

  @override
  Widget build(BuildContext context) {
    return SonoraScope(
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
          home: AppShell(startupWarning: startupWarning),
        ),
      ),
    );
  }
}
