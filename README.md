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
- **Lapisan data lokal (backend aplikasi)**: database SQLite dengan skema PRD bagian 7,
  repository media/playlist/antrean/state pemutaran/pengaturan, serta persistensi
  preferensi (aksen, Reduce Motion, repeat, shuffle) yang bertahan setelah restart.

Yang **belum** tersedia:

- Impor berkas melalui file picker native; repository media sudah siap menerima data
  impor, tetapi UI pemilih berkas belum terhubung.
- Pemutaran MP3/MP4, seek audio/video nyata, dan video rendering.
- Persistensi antrean dan playlist ke database (repository tersedia dan teruji;
  layar preview masih memakai data contoh di memori).
- Background playback dan media notification.

Kontrol yang termasuk batas tersebut memberikan penjelasan status dan tidak melaporkan keberhasilan palsu.

## Backend lokal (lapisan data)

Aplikasi ini offline-first, sehingga "backend" berarti lapisan layanan dan penyimpanan
lokal — bukan server. PRD bagian 11 menyatakan server tidak diperlukan untuk MVP dan
melarang backend palsu; kebutuhan akun/sinkronisasi cloud tetap fase terpisah.

- `lib/src/data/database.dart` — skema Drift: `media_items`, `playlists`,
  `playlist_items`, `playback_state`, `queue_items`, `app_settings`,
  dengan foreign key aktif, constraint, dan `schemaVersion` untuk migrasi.
- `lib/src/data/repositories.dart` — `MediaRepository`, `PlaylistRepository`,
  `QueueRepository`, `PlaybackStateRepository`, `SettingsRepository`.
  Operasi multi-tabel memakai transaksi; input pengguna divalidasi dan pesannya
  berbahasa Indonesia.
- `lib/src/data/backend.dart` — pembuka database aplikasi dan pemilik seluruh repository.
  Kegagalan membuka database tidak menggagalkan startup: aplikasi tetap jalan dan
  menampilkan pesan bahwa perubahan tidak akan tersimpan.
- `lib/src/data/models.dart` — kontrak impor (`MediaDraft`, `ImportReport`,
  `ImportStatus`) yang tidak bergantung pada UI.

Keputusan yang sudah ditetapkan:

- Duplikat media dikenali dari URI yang sama, atau nama berkas **dan** ukuran yang sama.
  Pemilihan ulang berkas yang sama tidak menambah baris.
- Satu lagu hanya boleh muncul sekali dalam satu playlist (`UNIQUE (playlist_id, media_id)`).
- Menghapus media dari library ikut menghapus barisnya di playlist dan antrean
  (`ON DELETE CASCADE`); berkas asli di perangkat tidak disentuh.
- Playlist dan antrean selalu disimpan dengan `position` rapat mulai dari 0.
- Baris `playback_state` tunggal (`id = 1`) memaksa satu konteks pemutaran.

Regenerasi kode Drift setelah mengubah skema:

```bash
dart run build_runner build
```

## Struktur penting

- `lib/main.dart` — titik masuk aplikasi dan scope status preview.
- `lib/src/preview_state.dart` — status dan operasi data preview.
- `lib/src/data/` — database Drift, repository, kontrak impor, dan pembuka backend lokal.
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
