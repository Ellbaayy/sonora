import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/src/app_state.dart';
import 'package:sonora/src/data/repositories.dart';
import 'package:sonora/src/media/media_item.dart';
import 'package:sonora/src/playback/audio_engine.dart';

import 'helpers.dart';

void main() {
  test('preferensi UI dan playback dipulihkan pada state baru', () async {
    final harness = await createHarness(
      seeds: [audioDraft('a.mp3', title: 'Alpha')],
    );
    addTearDown(harness.close);
    final songId = harness.state.songs.single.id;

    await harness.state.setAccent(true);
    await harness.state.setReduceMotion(true);
    await harness.state.toggleShuffle();
    await harness.state.cycleRepeat();
    await harness.state.setVolume(.35);
    await harness.state.toggleFavorite(songId);

    await waitForSetting(harness.backend, SettingsKeys.cyanAccent, 'true');
    await waitForSetting(harness.backend, SettingsKeys.reduceMotion, 'true');
    await waitForSetting(harness.backend, SettingsKeys.shuffle, 'true');
    await waitForSetting(harness.backend, SettingsKeys.repeatMode, 'one');
    await waitForSetting(harness.backend, SettingsKeys.volume, '0.35');
    await waitForSetting(harness.backend, SettingsKeys.favorites, songId);

    final restored = SonoraState(
      FakeAudioEngine(),
      backend: harness.backend,
      library: harness.state.library,
    );
    addTearDown(restored.dispose);
    expect(
      restored.cyanAccent,
      isFalse,
      reason: 'belum dibaca sebelum restore',
    );
    await restored.init();

    expect(restored.cyanAccent, isTrue);
    expect(restored.reduceMotion, isTrue);
    expect(restored.shuffle, isTrue);
    expect(restored.repeat, SonoraRepeat.one);
    expect(restored.volume, closeTo(.35, .001));
    expect(restored.favorites, contains(songId));
  });

  test('tanpa data tersimpan, preferensi memakai nilai bawaan', () async {
    final harness = await createHarness();
    addTearDown(harness.close);

    expect(harness.state.cyanAccent, isFalse);
    expect(harness.state.reduceMotion, isFalse);
    expect(harness.state.shuffle, isFalse);
    expect(harness.state.repeat, SonoraRepeat.off);
    expect(harness.state.volume, closeTo(.72, .001));
    expect(harness.state.favorites, isEmpty);
  });

  test(
    'impor tanpa layanan media memberi pesan, bukan kegagalan diam',
    () async {
      final harness = await createHarness(withLibrary: false);
      addTearDown(harness.close);

      final report = await harness.state.importMedia(MediaKind.audio);

      expect(report, isNull);
      expect(harness.state.notice, contains('tidak tersedia'));
      expect(harness.state.importing, isFalse);
    },
  );
}
