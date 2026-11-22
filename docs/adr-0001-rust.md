# ADR-0001: Bahasa implementasi SONORA

- **Status:** Diusulkan
- **Tanggal:** 23 November 2026
- **Pengambil keputusan:** pemilik proyek
- **Dokumen pendukung:** [`docs/rust-feasibility.md`](rust-feasibility.md)

---

## Konteks

SONORA adalah pemutar musik dan video lokal untuk Android, saat ini ditulis dengan Flutter:
7.334 baris di `lib/` (tanpa kode hasil generator), 1.338 baris tes (46 tes), dan APK debug 172,9 MB.
Pemutaran memakai `just_audio`, `audio_service`, `audio_session`, dan `video_player`; basis data
memakai `drift`; pemilih berkas memakai `file_picker`.

Pertanyaan yang dijawab: dapatkah SONORA ditulis penuh dalam Rust?

Bukti yang sudah dikumpulkan:

1. **Toolchain.** `rustc`/`cargo` 1.99.1 tersedia, tetapi sysroot hanya memuat
   `x86_64-unknown-linux-gnu`. `rustup` tidak terpasang, sehingga target Android tidak dapat
   ditambahkan. Percobaan `cargo build --target aarch64-linux-android` gagal dengan
   `error[E0463]: can't find crate for `core``.
2. **Kapabilitas.** Dari 12 kapabilitas, hanya 2 yang punya crate Rust stabil (`lofty` untuk
   metadata, `rusqlite` untuk SQLite). Lima kapabilitas adalah API platform yang tidak punya
   padanan matang: MediaSession, notifikasi media, tombol headset, pemilih SAF, dan permukaan video.
3. **Spike.** Membaca tag MP3 dan menulis ke SQLite dari Rust berhasil di host
   (`Uji Sonora — Rust Spike (7 dtk)`, satu baris tersimpan). Biner Android belum dapat dibangun
   karena prasyarat toolchain pada butir 1.

---

## Keputusan

1. **SONORA tetap memakai Flutter untuk produksi.** Tidak ada migrasi total ke Rust.
2. **"Full Rust" dinyatakan tidak layak** dan tidak akan dikejar, karena shell Android
   (MediaSession, foreground service, SAF, permukaan video) tetap membutuhkan Kotlin/Java.
3. Bila ada kebutuhan konkret untuk memakai Rust, jalur yang disetujui adalah **Opsi B: inti Rust +
   UI Flutter**, bertahap, dimulai dari metadata (`lofty`) dan basis data (`rusqlite`) melalui
   `flutter_rust_bridge`, dengan perekat Kotlin hanya untuk API platform.

---

## Konsekuensi

**Yang didapat**

- Tidak ada risiko regresi pada 2.575 baris UI dan 46 tes yang sudah ada.
- Tidak ada penambahan toolchain baru ke mesin pengembangan.
- Jalur Opsi B tetap terbuka bila motivasinya belajar Rust.

**Yang hilang / ditunda**

- Peluang memakai satu bahasa di seluruh tumpukan tidak diambil.
- Bila kelak Opsi B dijalankan: dua bahasa, dua toolchain, dan `flutter_rust_bridge` harus dirawat;
  ukuran APK bertambah karena `libcore.so` ikut dibundel.

**Prasyarat bila Opsi B dimulai**

- Memasang `rustup` dan melepas paket `rust` dari pacman (keduanya menyediakan berkas yang sama).
- Menambahkan target `aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-linux-android`.
- Menulis ulang 46 tes di sisi Rust untuk modul yang dipindah; tes widget Flutter tetap di Flutter.

---

## Alternatif yang ditolak

| Opsi | Alasan ditolak |
|---|---|
| **A. Full Rust (Slint/Dioxus/egui)** | UI mobile Rust belum setara Flutter; 2.575 baris UI harus ditulis ulang; MediaSession/SAF/video tetap Kotlin sehingga "full" tidak tercapai. Skor 7/20. |
| **C. Inti Rust + UI Compose** | Membuang 2.575 baris UI dan 46 tes Flutter tanpa manfaat yang sebanding; waktu 3–5 bulan. Skor 10/20. |

## Opsi yang diterima

| Opsi | Status | Skor |
|---|---|---|
| **D. Tetap Flutter** | **Dipilih untuk produksi.** | 18/20 |
| **B. Inti Rust + UI Flutter** | **Disetujui bersyarat**, hanya bila tujuan belajar Rust menjadi prioritas. | 14/20 — kolom "kesesuaian" menjadi 5 bila tujuannya belajar |

---

## Catatan

Angka pada dokumen ini berasal dari perintah yang tercatat di `docs/rust-feasibility.md` pada
23 November 2026. Bila kode berubah, hitung ulang sebelum mengutip angka ini.
