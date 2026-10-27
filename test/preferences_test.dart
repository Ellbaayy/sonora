import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/src/data/database.dart';
import 'package:sonora/src/data/repositories.dart';
import 'package:sonora/src/preview_state.dart';

/// Menunggu penulisan preferensi yang dijalankan tanpa ditunggu oleh state.
Future<void> waitForSetting(
  SettingsRepository settings,
  String key,
  String expected,
) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (await settings.read(key) == expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Pengaturan $key tidak tersimpan sebagai $expected.');
}

void main() {
  late SonoraDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = SonoraDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('preferensi UI dan playback dipulihkan pada state baru', () async {
    final first = PreviewState(settings: settings);
    first.setAccent(true);
    first.setReduceMotion(true);
    first.toggleShuffle();
    first.cycleRepeat();

    await waitForSetting(settings, SettingsKeys.cyanAccent, 'true');
    await waitForSetting(settings, SettingsKeys.reduceMotion, 'true');
    await waitForSetting(settings, SettingsKeys.shuffle, 'true');
    await waitForSetting(settings, SettingsKeys.repeatMode, 'one');
    first.dispose();

    final restored = PreviewState(settings: settings);
    expect(
      restored.cyanAccent,
      isFalse,
      reason: 'belum dibaca sebelum restore',
    );
    await restored.restorePreferences();

    expect(restored.cyanAccent, isTrue);
    expect(restored.reduceMotion, isTrue);
    expect(restored.shuffle, isTrue);
    expect(restored.repeat, PreviewRepeat.one);
    restored.dispose();
  });

  test('tanpa data tersimpan, preferensi memakai nilai bawaan', () async {
    final state = PreviewState(settings: settings);
    await state.restorePreferences();

    expect(state.cyanAccent, isFalse);
    expect(state.reduceMotion, isFalse);
    expect(state.shuffle, isFalse);
    expect(state.repeat, PreviewRepeat.off);
    state.dispose();
  });

  test('state tanpa repository tetap berjalan tanpa penulisan', () async {
    final state = PreviewState();
    state.setAccent(true);
    state.setReduceMotion(true);
    state.toggleShuffle();
    state.cycleRepeat();

    expect(state.cyanAccent, isTrue);
    expect(state.repeat, PreviewRepeat.one);
    await state.restorePreferences();
    expect(await settings.read(SettingsKeys.cyanAccent), isNull);
    state.dispose();
  });
}
