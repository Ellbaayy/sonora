# SONORA

SONORA adalah pemutar musik dan video **lokal** untuk Android dengan tema **Premium Dark Aurora**. Proyek ini menggunakan Flutter dan Dart, berjalan sepenuhnya offline, dan tidak memiliki akun, server, maupun telemetri.

## Status: 1.0.0 — MVP lengkap

Seluruh butir MVP pada PRD (`~/Unduhan/prd.md`) sudah diimplementasikan: impor media dari perangkat, pemutaran MP3 dan MP4, antrean dan playlist yang tersimpan, notifikasi media, serta pemulihan posisi terakhir.

Yang tersedia:

- **Impor media** melalui pemilih berkas sistem (Storage Access Framework) untuk audio
  (MP3, M4A, AAC, WAV, FLAC, OGG, OPUS) dan video (MP4, M4V, MKV, WEBM, 3GP), dengan
  ringkasan hasil: berhasil, duplikat, dan tidak didukung.
- **Metadata lokal**: judul, artis, album, durasi, dan cover di dalam berkas dibaca
  langsung di perangkat. Bila tag tidak ada, nama berkas dipakai sebagai judul.
- **Pemutaran audio** dengan play/pause, seek, volume, previous/next, shuffle, dan repeat
  (`off` berhenti di ujung antrean, `all` kembali ke awal, `one` mengulang trek aktif).
- **Pemutaran background** dengan notifikasi media, kontrol headset, dan kontrol layar kunci
  (`audio_service` + `just_audio`).
- **Pemutar video** dengan play/pause, seek, volume, dan mode layar penuh. Musik dijeda
  otomatis ketika video diputar agar hanya ada satu sumber audio.
- **Library** dengan pencarian, pengurutan, dan pengelompokan per artis/album.
- **Playlist** dengan buat, ubah nama, hapus, tambah/hapus lagu, dan ubah urutan (drag).
- **Antrean** persisten dengan tambah, hapus, ubah urutan, dan kosongkan.
- **Persistensi**: media, playlist, antrean, riwayat putar, favorit, dan preferensi
  (aksen, Reduce Motion, repeat, shuffle, volume, posisi terakhir) bertahan setelah
  aplikasi ditutup.
- **Navigasi dynamic island**: kapsul mengambang dengan item aktif yang mengembang,
  mini player menempel di atasnya, dan label otomatis ringkas pada layar sempit atau
  skala teks besar.
- Empty state, status impor, dan pesan kesalahan yang spesifik berbahasa Indonesia.

Batas yang masih berlaku (jujur, bukan bug):

- Video belum menampilkan thumbnail dari frame video; kartu video memakai artwork
  prosedural. Posisi video tidak dilanjutkan setelah keluar dari pemutar.
- Tidak ada Picture-in-Picture, equalizer, atau lirik. Tidak ada streaming, akun, atau
  sinkronisasi cloud (di luar cakupan MVP menurut PRD bagian 4).
- Build yang dihasilkan masih **debug** (ditandatangani kunci debug), bukan paket rilis
  siap distribusi.

## Keputusan penting

- **Salinan berkas saat impor.** Pemilih berkas Android memberi akses sementara, sehingga
  SONORA menyalin berkas terpilih ke penyimpanan aplikasi (`<app support>/media`). Tanpa
  salinan, media tidak dapat diputar lagi setelah pemilih ditutup atau perangkat dimulai
  ulang. Berkas **asli tidak pernah dipindahkan, diubah, atau dihapus**.
- **Hapus dari library** menghapus baris database, salinan aplikasi, dan cover hasil
  ekstraksi. Berkas asli di perangkat tetap utuh.
- **Duplikat** dikenali dari URI yang sama, atau kombinasi nama berkas dan ukuran yang sama.
- **Shuffle** memakai urutan deterministik yang stabil: item yang sudah ada mempertahankan
  posisinya, item baru masuk di belakang, dan tidak ada item yang hilang.
- **Pemulihan posisi** tidak memutar otomatis. Aplikasi membuka trek terakhir dalam keadaan
  dijeda agar tidak mengejutkan pengguna.
- **Tombol putar video** memeriksa posisi lebih dulu: bila video sudah berada di ujung,
  pemutaran dimulai lagi dari awal; bila belum, pemutaran berlanjut dari posisi terakhir.
- **Izin**: aplikasi hanya meminta izin notifikasi (Android 13+) saat pemutaran pertama.
  Akses berkas memakai pemilih sistem sehingga tidak meminta izin seluruh penyimpanan.

## Arsitektur

```text
lib/
├── main.dart                      # startup: audio service, backend, state, MaterialApp
└── src/
    ├── app_state.dart             # SonoraState: library, playlist, antrean, pemutaran
    ├── app_shell.dart             # lima layar + dynamic island + mini player
    ├── theme.dart                 # token warna, tipografi, transisi (Reduce Motion)
    ├── artwork.dart               # monogram, artwork prosedural, ilustrasi, equalizer
    ├── data/
    │   ├── database.dart          # skema Drift (PRD bagian 7)
    │   ├── repositories.dart      # media, playlist, antrean, playback state, settings
    │   ├── backend.dart           # pembuka database + pemilik repository
    │   └── models.dart            # MediaDraft, ImportReport, PlaylistSummary
    ├── media/
    │   ├── media_item.dart        # model media untuk UI
    │   ├── media_library.dart     # picker, penyimpanan aplikasi, alur impor/hapus
    │   └── media_metadata.dart    # pembaca tag ID3/Vorbis/MP4
    ├── playback/
    │   ├── audio_engine.dart      # kontrak mesin audio + implementasi tiruan
    │   ├── audio_handler.dart     # audio_service handler + adapter just_audio
    │   └── notification_permission.dart
    ├── screens/                   # home, library, playlists, videos, player, settings
    └── widgets/
        ├── shared.dart            # komponen bersama + alur impor
        └── dynamic_island_nav.dart
```

"Backend" pada aplikasi ini berarti lapisan layanan dan penyimpanan **lokal**, bukan
server; PRD bagian 11 menyatakan server tidak diperlukan untuk MVP.

### Skema database

`media_items`, `playlists`, `playlist_items`, `playback_state`, `queue_items`,
`app_settings` — foreign key aktif, constraint di level SQL, dan `schemaVersion` untuk
migrasi. Regenerasi kode Drift setelah mengubah skema:

```bash
dart run build_runner build
```

## Menjalankan pemeriksaan

```bash
cd ~/Documents/Projects/sonora
export JAVA_HOME=/opt/android-studio/jbr
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/.local/opt/flutter/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Build dan pemasangan

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n id.sonora.sonora/.MainActivity
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`

Konfigurasi Android: `minSdk 24`, `targetSdk 36`, `applicationId id.sonora.sonora`.
Manifest memuat `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`,
dan `POST_NOTIFICATIONS` untuk pemutaran background, serta service
`com.ryanheise.audioservice.AudioService` dan receiver tombol media.

## Pengujian

`flutter test` menjalankan 46 pengujian:

- `test/data_repository_test.dart` — constraint, duplikat, transaksi, dan urutan posisi.
- `test/app_state_test.dart` — antrean/repeat/shuffle, riwayat, impor, hapus media,
  persistensi antrean + playlist + posisi, dan pencarian.
- `test/preferences_test.dart` — pemulihan preferensi dan fallback.
- `test/screens_test.dart` — lima layar, Now Playing, antrean, playlist, dynamic island,
  pencarian, serta anti-overflow pada lebar 360 dan skala teks 1.3.
- `test/video_player_test.dart` — posisi mulai pemutaran video: melanjutkan dari posisi
  terakhir, kembali ke awal bila sudah di ujung (termasuk toleransi beberapa milidetik),
  dan aman saat durasi belum diketahui.
- `test/widget_test.dart` — smoke test aplikasi penuh.

Widget test memakai `FakeAudioEngine` dan database di memori, sehingga tidak membutuhkan
perangkat maupun plugin native.

## Privasi dan aset

Seluruh data berada di perangkat. Tidak ada unggahan media, akun, atau telemetri.
Artwork diambil dari cover di dalam berkas bila tersedia; bila tidak, aplikasi menggambar
artwork sendiri. Font Manrope dibundel dengan lisensi SIL Open Font License
(`assets/fonts/OFL.txt`). Kode proyek memakai lisensi MIT (`LICENSE`).
