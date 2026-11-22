# Studi Kelayakan: SONORA dengan Rust

**Tanggal:** 23 November 2026
**Lingkup:** menilai apakah SONORA dapat ditulis penuh dalam Rust, dan bila tidak, bagian mana yang
realistis dipindahkan.

---

## 1. Ringkasan keputusan

**"Full Rust" secara harfiah tidak mungkin** untuk aplikasi Android seperti SONORA. Empat hal
berikut adalah API platform yang tidak punya padanan Rust matang dan harus tetap Kotlin/Java:

1. `MediaSession` + foreground service untuk pemutaran latar belakang,
2. penerima tombol headset (`MediaButtonReceiver`),
3. pemilih berkas Storage Access Framework (`ACTION_OPEN_DOCUMENT`),
4. permukaan video (`SurfaceView` + dekoder platform).

Yang **bisa** dicapai: seluruh logika aplikasi di Rust (metadata, basis data, antrean, aturan
pemutaran, playlist, preferensi), dengan Kotlin hanya sebagai perekat platform. Itu setara
**Opsi B** pada bagian 6, dengan perkiraan 6–10 minggu kerja, bukan penulisan ulang total.

---

## 2. Metrik kode (terukur)

Perintah:

```bash
cd ~/Documents/Projects/sonora
find lib -name '*.dart' ! -name '*.g.dart' | xargs wc -l | tail -1
find test -name '*.dart' | xargs wc -l | tail -1
grep -hE "^\s*(test|testWidgets)\(" test/*_test.dart | wc -l
```

Keluaran:

```
7334 total
1338 total
46
```

| Area | Baris |
|---|---|
| `lib/src/screens` (6 layar) | 2.575 |
| `lib/src/data` (Drift + repository) | 927 |
| `lib/src/widgets` | 894 |
| `lib/src/media` | 453 |
| `lib/src/playback` | 395 |
| **Total `lib/` (tanpa `.g.dart`)** | **7.334** |
| `test/` | 1.338 (46 tes) |

Rincian layar: `home_screen.dart` 298, `library_screen.dart` 354, `settings_screen.dart` 389,
`videos_screen.dart` 475, `player_screen.dart` 488, `playlists_screen.dart` 571.

---

## 3. Matriks kapabilitas

Verdict: **LANGSUNG** = crate Rust stabil; **JNI** = perlu perekat Kotlin tipis; **TETAP KOTLIN** =
API platform, tidak realistis dipindah.

| # | Kapabilitas | Plugin sekarang | Padanan Rust | Verdict | Risiko |
|---|---|---|---|---|---|
| 1 | Antarmuka (6 layar) | Flutter | Slint / Dioxus / egui | TETAP FLUTTER (atau Slint kalau memilih Opsi A) | tinggi |
| 2 | Pemutaran audio | `just_audio` | `symphonia` + `cpal`/`oboe` | JNI (AAudio butuh NDK) | tinggi |
| 3 | Service latar + MediaSession | `audio_service` | — | TETAP KOTLIN | tinggi |
| 4 | Notifikasi media | `audio_service` | — | TETAP KOTLIN | tinggi |
| 5 | Tombol headset | `audio_service` | — | TETAP KOTLIN | tinggi |
| 6 | Audio focus | `audio_session` | — | JNI (`AudioManager`) | rendah |
| 7 | Video | `video_player` (ExoPlayer) | `gstreamer` atau JNI ke ExoPlayer | TETAP KOTLIN / JNI | tinggi |
| 8 | Pemilih berkas SAF | `file_picker` | — | TETAP KOTLIN | sedang |
| 9 | Izin runtime | `permission_handler` | — | JNI | rendah |
| 10 | Metadata tag | `audio_metadata_reader` | **`lofty`** | LANGSUNG | rendah |
| 11 | Basis data | `drift` | **`rusqlite`** / `sqlx` | LANGSUNG | rendah |
| 12 | Path & preferensi | `path_provider`, `shared_preferences` | JNI + `rusqlite` | JNI | rendah |

Hasil hitung: 2 kapabilitas `LANGSUNG`, 4 `JNI`, 5 `TETAP KOTLIN`, 1 `TETAP FLUTTER`.

---

## 4. Temuan toolchain (bukti)

```bash
rustc --print sysroot          # /usr
ls "$(rustc --print sysroot)/lib/rustlib"
# etc
# x86_64-unknown-linux-gnu
command -v rustup              # tidak ada
```

Hanya target host yang tersedia. Percobaan membangun untuk Android:

```bash
cd ~/.hermes/cache/scratch/sonora-rust/core-spike
export NDK="$HOME/Android/Sdk/ndk/28.2.13676358"
export PATH="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
cargo build --release --target aarch64-linux-android
```

Keluaran (exit 101, 11 galat):

```
error[E0463]: can't find crate for `core`
  = note: the `aarch64-linux-android` target may not be installed
  = help: consider downloading the target with `rustup target add aarch64-linux-android`
```

**Prasyarat yang harus diselesaikan lebih dulu** (belum dikerjakan; mengubah sistem):

1. `sudo pacman -S rustup`, tetapi paket `rust` harus dilepas karena menyediakan berkas yang sama
   (`sudo pacman -Rdd rust`), lalu
   `rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android`.
2. Alternatif tanpa rustup: toolchain nightly + `cargo build -Z build-std`, lebih lambat dan tidak
   cocok untuk CI jangka panjang.

NDK tersedia: `~/Android/Sdk/ndk/28.2.13676358`.

---

## 5. Spike yang dijalankan

### 5.1 Metadata + SQLite di host — BERHASIL

Proyek: `~/.hermes/cache/scratch/sonora-rust/core-spike` (crate `core-spike`),
dependensi `lofty 0.25.5` + `rusqlite 0.43.0` (`bundled`).

Berkas uji dibuat dengan ffmpeg agar punya tag:

```bash
ffmpeg -y -loglevel error -f lavfi -i "sine=frequency=440:duration=7" \
  -metadata title="Uji Sonora" -metadata artist="Rust Spike" \
  -codec:a libmp3lame uji.mp3
cd core-spike && cargo run --quiet --bin uji ../uji.mp3
```

Keluaran:

```
Uji Sonora — Rust Spike (7 dtk)
baris tersimpan = 1
```

Kesimpulan: membaca tag dan menulis SQLite dari Rust berjalan tanpa Android. Ukuran
`libcore_spike.so` hasil build host: 13.395.312 byte (debug, termasuk SQLite bundled).

### 5.2 Biner Android — GAGAL (sesuai dugaan)

Lihat bagian 4. Kegagalan ini bukan cacat rancangan, melainkan prasyarat toolchain yang belum
dipasang.

---

## 6. Perkiraan biaya perekat Android

Angka adalah perkiraan untuk perencanaan, bukan hasil pengukuran.

| Pekerjaan | API Android | Perkiraan baris Kotlin | Catatan |
|---|---|---|---|
| MediaSession + notifikasi + tombol headset | `android.media.session.MediaSession`, `NotificationCompat`, `MediaButtonReceiver` | 300–500 | paling rumit; menggantikan seluruh `audio_service` |
| Pemilih berkas SAF | `Intent.ACTION_OPEN_DOCUMENT`, `ActivityResultContracts` | 80–150 | termasuk izin URI persisten |
| Izin runtime | `ActivityCompat.requestPermissions` | 60–120 | `POST_NOTIFICATIONS` (Android 13+) |
| Permukaan video | `SurfaceView` / `TextureView` + ExoPlayer | 150–300 | kalau video tetap platform |
| **Total** | | **590–1.070** | di luar kode Rust |

---

## 7. Keputusan video

Dua jalur:

- **`gstreamer`** — semua di Rust, tetapi menambah puluhan MB, butuh build NDK yang rumit, dan
  integrasi Surface harus ditulis sendiri. Belum diukur di mesin ini.
- **JNI ke ExoPlayer + `SurfaceView`** — ringan, didukung penuh Android, tetapi tetap Kotlin.

**Pilihan: JNI ke ExoPlayer.** Alasan: SONORA hanya perlu memutar berkas lokal; menambah
`gstreamer` menaikkan ukuran APK dan kompleksitas build tanpa manfaat yang sebanding. APK debug saat
ini sudah 172,9 MB.

---

## 8. Skor opsi

Skala 1–5, makin tinggi makin baik (untuk "usaha" dan "risiko", 5 = paling ringan/rendah).

| Opsi | Usaha | Risiko | Hasil jangka panjang | Kesesuaian | Total |
|---|---|---|---|---|---|
| A. Full Rust (Slint/Dioxus) | 1 | 1 | 3 | 2 | 7 |
| B. Rust core + Flutter UI | 3 | 3 | 4 | 4 | 14 |
| C. Rust core + Compose | 2 | 2 | 3 | 3 | 10 |
| D. Tetap Flutter | 5 | 5 | 3 | 5 | 18 |

Catatan: kolom "kesesuaian" mengasumsikan tujuan utamanya adalah aplikasi yang selesai dan
terpelihara. Bila tujuan utamanya belajar Rust, nilai B naik menjadi 5 dan D turun menjadi 2.

---

## 9. Rekomendasi

1. **Untuk produksi: tetap Flutter (Opsi D).** Tidak ada masalah performa yang perlu diselesaikan
   Rust — pemutaran audio dan video sudah memakai dekoder native di kedua tumpukan.
2. **Bila tujuannya belajar Rust: Opsi B**, bertahap, dimulai dari modul yang paling aman
   (`lofty` untuk metadata, `rusqlite` untuk basis data), dihubungkan lewat `flutter_rust_bridge`.
3. **Opsi A ditolak**: UI mobile Rust belum setara Flutter, dan 2.575 baris UI + 46 tes harus
   ditulis ulang.
4. **Opsi C ditolak**: membuang UI Flutter yang sudah jadi tanpa alasan yang sebanding.

Prasyarat sebelum Opsi B bisa dimulai: pemasangan `rustup` (menggantikan paket `rust`) dan target
Android, seperti pada bagian 4.
