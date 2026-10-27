# SONORA

SONORA adalah frontend Android untuk pemutar musik dan video lokal dengan tema **Premium Dark Aurora**. Proyek ini menggunakan Flutter dan Dart.

## Batas tahap saat ini

Tahap ini menyediakan **pratinjau antarmuka dengan data contoh**, bukan pemutar media lengkap. Data contoh ditandai secara eksplisit di aplikasi.

Yang sudah tersedia:

- Navigasi Home, Library, Playlist, Video, dan Settings.
- Pencarian, pengurutan, dan pengelompokan lagu contoh.
- Layar Now Playing, mini player, serta antrean preview.
- Next/Previous mengikuti urutan antrean; repeat `off` berhenti di ujung antrean,
  repeat `all` kembali ke item pertama, dan repeat `one` mengulang item aktif.
  Shuffle memakai urutan stabil selama aktif, tanpa menghilangkan item antrean.
- Pembuatan, perubahan nama, dan penghapusan playlist selama sesi preview.
- Pengaturan aksen dan Reduce Motion.
- Empty state dan penjelasan untuk fitur perangkat yang belum terhubung.

Yang **belum** tersedia:

- Impor berkas melalui file picker native.
- Pemutaran MP3/MP4, seek audio/video nyata, dan video rendering.
- Database, persistensi antrean/playlist, serta preferensi setelah restart.
- Background playback dan media notification.

Kontrol yang termasuk batas tersebut memberikan penjelasan status dan tidak melaporkan keberhasilan palsu.

## Struktur penting

- `lib/main.dart` — titik masuk aplikasi dan scope status preview.
- `lib/src/preview_state.dart` — status dan operasi data preview.
- `lib/src/screens/` — layar utama dan player.
- `lib/src/widgets/shared.dart` — komponen bersama dan alur impor preview.
- `DESIGN.md` — kontrak desain dan batas tahap frontend.
- `test/` — unit test dan widget test.
- `assets/fonts/` — Manrope beserta lisensi SIL Open Font License.

## Menjalankan pemeriksaan

Lokasi proyek di mesin ini:

```bash
cd ~/Documents/Projects/sonora
```

Siapkan toolchain yang tersedia:

```bash
export JAVA_HOME=/opt/android-studio/jbr
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/.local/opt/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
```

Lalu jalankan:

```bash
flutter pub get
flutter analyze
flutter test
```

## Build dan pemasangan APK debug

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n id.sonora.sonora/.MainActivity
```

APK dibuat di:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Konfigurasi Android saat ini: `minSdk 24`, `targetSdk 36`, dan `applicationId id.sonora.sonora`. Build debug ditandatangani dengan kunci debug dan **bukan paket rilis produksi**.

## Privasi dan aset

Data preview berada di dalam aplikasi. Tahap ini tidak mengimpor, membaca, atau mengunggah media perangkat. Izin `INTERNET` pada manifest debug berasal dari toolchain Flutter untuk kebutuhan pengembangan; manifest utama tidak meminta izin tersebut.

Artwork dan ilustrasi digambar secara lokal oleh kode aplikasi. Tidak ada aset Storyset pada tahap ini. Font Manrope digunakan berdasarkan lisensi di `assets/fonts/OFL.txt`.

Kode proyek menggunakan lisensi MIT yang tersedia di `LICENSE`.
