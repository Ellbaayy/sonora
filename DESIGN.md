# SONORA — Kontrak Desain Frontend

Sumber kebutuhan: `/home/ellbaayy/Unduhan/prd.md`, dibaca sebelum implementasi.

## 0. Research Log

- PRD SONORA: arah Premium Dark Aurora, lima destinasi navigasi, mini player, now playing, pustaka lokal, playlist, video, dan pengaturan. Media asli belum diimpor pada fase frontend.
- Dokumentasi Material 3 Android Media3, dicari pada pembuatan awal: tombol player dapat disusun khusus, tetapi status kontrol harus berasal dari satu sumber status. Fase ini hanya memakai simulasi UI dan tidak mengklaim playback engine.
- Dokumentasi Android Accessibility Principles: label bermakna untuk kontrol dan isyarat selain warna. Flutter Accessibility Release Checklist: target sentuh minimal 48x48 logical pixels, kontras teks 4.5:1, dan dukungan text scaling.
- Referensi desain lokal `omh design data --context mobile`: satu aksi utama per layar, target sentuh minimal 44px, empty state harus membantu tugas berikutnya. Kontrak ini memilih target minimum 48px sesuai panduan Flutter.
- Preset warna Pocket Mint ditolak karena bertema terang dan tidak sesuai PRD. Pretendard tidak dipilih karena aplikasi berbahasa Indonesia; native sans memastikan fallback sistem.
- Tidak memakai referensi aplikasi pihak ketiga, logo pihak ketiga, gambar jarak jauh, atau aset Storyset pada fase ini. Artwork dan ilustrasi digambar lokal oleh komponen proyek.
- Fase ini adalah frontend Android, bukan web: breakpoint web dan Core Web Vitals tidak diterapkan sebagai bukti performa. Responsivitas diperiksa pada lebar Android 360 dan 412 logical pixels serta layar emulator.

## 1. Atmosphere & Identity

- Tiga sifat: **imersif, tenang, terarah**.
- Arah utama: **Premium / soft**, dibatasi kepadatan kontrol khas pemutar media operasional. Bukan editorial krem/serif, bukan dashboard bisnis, bukan glassmorphism menyeluruh.
- Audiens: pengguna Android yang mengelola MP3 dan MP4 sendiri tanpa streaming.
- Elemen khas: monogram **S** berbentuk alur suara, dengan satu garis sinyal cyan di dalam bentuk violet; dipakai pada wordmark, artwork, dan ilustrasi kosong.
- Label produk, navigasi, aksi, dan pesan memakai bahasa Indonesia formal. Judul lagu contoh boleh mempertahankan nama aslinya.
- Satu aksi utama per layar. Data contoh diberi label "Pratinjau antarmuka" agar tidak disalahartikan sebagai koleksi perangkat.

## 2. Color

Semua komponen memakai token berikut. Proporsi sasaran 60% latar gelap, 30% permukaan netral, 10% aksen; gradient hanya untuk identitas dan artwork, bukan latar seluruh layar.

| Token | Hex | Pasangan / fungsi |
|---|---|---|
| `background` | `#0B0C14` | `onBackground #F6F5FC` |
| `surface` | `#141522` | `onSurface #F6F5FC` |
| `surfaceRaised` | `#1D1E30` | `onSurfaceRaised #F6F5FC` |
| `surfaceSubtle` | `#11131F` | `onSurfaceSubtle #C6C7D8` |
| `mutedText` | `#A8A9BC` | teks sekunder pada latar gelap |
| `border` | `#2B2C41` | pemisah, bukan dekorasi menyeluruh |
| `primary` | `#AE8CFF` | `onPrimary #171024` |
| `accent` | `#65DDE3` | `onAccent #082226` |
| `focusRing` | `#D9F7F5` | fokus keyboard / accessibility |
| `success` | `#7CE1AC` | teks sukses dengan ikon centang |
| `warning` | `#F0C980` | informasi pratinjau dengan ikon info |
| `danger` | `#FF9DAD` | error dan aksi destruktif dengan label |

- Light/system tetap menjadi opsi konfigurasi fase lanjutan. Pada fase ini pengaturan tema menampilkan status yang jujur: dark tersedia, light dan system belum diaktifkan agar tidak ada cabang warna tak teruji.
- Aksen dapat dipilih violet/cyan. Komponen memakai semantic token, tidak ada warna hard-coded per layar selain nilai ilustrasi lokal yang terdokumentasi sebagai bagian dari artwork.
- Artwork boleh memakai kombinasi violet `#AE8CFF`, cyan `#65DDE3`, coral `#F19EAC`, dan biru `#89ACF7` dengan latar `#17182A`; teks tidak ditempatkan di atas artwork tanpa scrim gelap.
- Satu radius dasar 16: small 8, medium 16, large 24, pill 999. Tombol player utama memakai lingkaran 64, bukan radius tombol umum.

## 3. Typography

- Display dan body: **Manrope**, dibundel dari Google Fonts OFL; fallback sistem sans/Roboto. Hanya satu keluarga, signature berasal dari monogram, bukan font default yang dipaksakan.
- Skala: hero 34/40 w700, title 28/34 w700, section 20/26 w700, card 16/22 w700, body 14/21 w400–500, caption 12/18 w500.
- Angka durasi memakai tabular figures; judul lagu maksimal dua baris, subtitle satu baris dengan ellipsis bila ruang tidak cukup.
- Minimum body 14 untuk teks penting. Label navigasi 12 diperbolehkan dengan ukuran target 48 dan kontras tinggi.
- Tidak ada efek per huruf yang menghalangi screen reader.

## 4. Spacing & Layout

- Basis 4; langkah 4, 8, 12, 16, 20, 24, 32, 40.
- Padding horizontal layar 20; jarak antar bagian 28; jarak internal kartu 12–20.
- Safe area dimiliki shell. Konten utama scroll sendiri; navigasi berbentuk **dynamic island** (kapsul mengambang) dengan mini player sebagai kapsul kecil di atasnya. Layar player menjadi route terpisah agar kontrol tidak tertutup navigasi.
- Lebar maksimum konten pada perangkat besar 680; layar sempit memakai satu kolom, artwork horizontal hanya bila ruang cukup.
- Home: header → pencarian → Recently Played → Recently Added → Your Playlists.
- Library: tab Songs/Artists/Albums, pencarian, sort/filter, daftar/grid sesuai tab. Videos memakai grid dua kolom pada lebar 360+.
- Playlist mendukung create/rename/delete serta detail dengan Play All, Shuffle, tambah lagu, dan reorder drag-and-drop. Semua perubahan tersimpan di database lokal.
- Empty state menawarkan impor berkas; impor membuka pemilih berkas sistem, menampilkan progres, lalu ringkasan berhasil/duplikat/ditolak.

## 5. Components

- `AppButton`: primary (satu per layar), secondary, text, danger; tinggi minimal 48; default, pressed, focus-visible, disabled, loading.
- `IconControl`: tooltip, semantics, 48x48; player utama 64x64; status aktif memakai ikon dan label/tooltip, bukan warna saja.
- `SearchField`: label aksesibel, clear button, focus ring, hasil kosong, input error jika pencarian gagal.
- `MediaTile` / `MediaCard`: artwork (cover asli bila ada), judul, artis, durasi, menu; tekan memutar media; item aktif diberi ikon equalizer dan warna primer.
- `DynamicIslandNavigation`: kapsul mengambang berisi lima destinasi (Home, Library, Playlist, Video, Settings). Item aktif mengembang dan menampilkan label; label disembunyikan otomatis saat lebar kapsul < 330 atau skala teks besar. Kapsul memakai blur latar, border, dan bayangan tunggal.
- `IslandMiniPlayer`: kapsul kecil di atas navigasi berisi artwork, judul, progres tipis, dan tombol play/pause; tidak ada jika tidak ada media dipilih.
- `Slider`: seek dan volume mengontrol pemutaran nyata; nilai posisi berasal dari stream pemutar.
- `ModalSheet` dan `Dialog`: aksi tambah playlist, rename, delete confirmation, ringkasan impor; input kosong memunculkan error yang dapat diperbaiki.
- `MediaIllustration`: bentuk headphone/vinyl lokal, tanpa teks penting di dalam gambar; decorative untuk screen reader.
- Empty: artwork kecil + penjelasan + satu aksi impor; loading: skeleton atau progress terpusat; error: pesan + retry; disabled: opacity dan callback nonaktif.

## 6. Motion & Interaction

- `fast 120ms`, `standard 200ms`, `page 280ms`; easing `Curves.easeOutCubic` untuk masuk dan `Curves.easeInOutCubic` untuk perubahan state. Tidak ada bounce dekoratif.
- Transisi halaman memakai fade+slide 12px; artwork berubah memakai fade/scale ringan; shimmer hanya saat loading aktual.
- Equalizer dekoratif bergerak hanya saat status simulasi "playing" dan Reduce Motion mati. Pause harus menghentikannya.
- Reduce Motion mengganti transisi dengan perpindahan instan, menghentikan equalizer, dan tidak mengurangi fungsi kontrol.
- Slider dan tap selalu merespons sebelum animasi selesai. Tidak ada autoplay setelah aplikasi dibuka.

## 7. Depth & Surface

- Latar solid deep navy; lapisan dibedakan oleh permukaan dan border halus. Tidak ada bayangan pada setiap kartu.
- Gradient hanya pada logo/artwork dan player utama; glow satu sumber pada artwork now playing dengan opacity terbatas.
- Blur latar (`BackdropFilter`) hanya dipakai pada dynamic island dan mini player yang mengambang di atas konten; permukaan lain tetap solid.
- Equalizer dekoratif berhenti saat jeda atau saat Reduce Motion aktif.

## 8. Accessibility Constraints & Accepted Debt

- Target sentuh 48x48; label semantik untuk seluruh tombol; decorative image disembunyikan dari semantics.
- Status selected/playing menggabungkan ikon dan teks/tooltip, bukan warna saja. Teks utama/surface memenuhi target 4.5:1; hasil pengukuran final perlu diverifikasi pada implementasi.
- Search tetap dapat digunakan dengan keyboard; urutan fokus mengikuti urutan visual; aksi destruktif perlu konfirmasi.
- Konten dapat discroll pada text scaling; QA minimum pada 1.0 dan 1.3.
- Hutang yang diterima secara eksplisit: thumbnail video dari frame asli belum dibuat (memakai
  artwork prosedural), posisi video tidak dilanjutkan setelah keluar pemutar, dan tidak ada
  Picture-in-Picture. Paket rilis bertanda tangan serta distribusi Play Store belum disiapkan.
- Pengujian TalkBack pada perangkat fisik, performa animasi pada perangkat lambat, dan
  distribusi release bukan bukti yang tersedia dari tahap ini. Bukti yang ada: 42 pengujian
  otomatis, `flutter analyze` bersih, dan build APK debug.
