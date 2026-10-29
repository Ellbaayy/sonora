import 'package:flutter_test/flutter_test.dart';
import 'package:sonora/src/screens/videos_screen.dart';

void main() {
  group('videoResumePosition', () {
    const duration = Duration(seconds: 8);

    test('melanjutkan dari posisi terakhir bila video belum selesai', () {
      expect(
        videoResumePosition(
          position: const Duration(seconds: 3),
          duration: duration,
        ),
        const Duration(seconds: 3),
      );
    });

    test('memulai dari awal bila video sudah berada di ujung', () {
      expect(
        videoResumePosition(position: duration, duration: duration),
        Duration.zero,
      );
    });

    test(
      'memulai dari awal bila posisi hanya beberapa milidetik dari ujung',
      () {
        expect(
          videoResumePosition(
            position: duration - const Duration(milliseconds: 120),
            duration: duration,
          ),
          Duration.zero,
        );
      },
    );

    test('memakai awal bila durasi belum diketahui', () {
      expect(
        videoResumePosition(
          position: const Duration(seconds: 2),
          duration: Duration.zero,
        ),
        Duration.zero,
      );
    });
  });
}
