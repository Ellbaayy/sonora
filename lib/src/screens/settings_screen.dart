import 'package:flutter/material.dart';

import '../app_state.dart';
import '../artwork.dart';
import '../media/media_item.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'library_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    final unavailable = state.songs.where((song) => !song.available).length;
    final repeatLabel = switch (state.repeat) {
      SonoraRepeat.off => 'mati',
      SonoraRepeat.one => 'satu lagu',
      SonoraRepeat.all => 'semua',
    };
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const ScreenHeader(
          title: 'Pengaturan',
          subtitle: 'Atur ruang dengarmu.',
        ),
        const _GroupLabel('TAMPILAN'),
        const _SettingsGroup(
          children: [
            _SettingRow(
              icon: Icons.dark_mode_outlined,
              title: 'Tema',
              subtitle: 'Premium Dark Aurora',
              trailing: Text('Gelap'),
            ),
          ],
        ),
        const _GroupLabel('AKSEN'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _AccentChoice(
                  cyan: false,
                  selected: !state.cyanAccent,
                  onTap: () => state.setAccent(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AccentChoice(
                  cyan: true,
                  selected: state.cyanAccent,
                  onTap: () => state.setAccent(true),
                ),
              ),
            ],
          ),
        ),
        const _GroupLabel('PEMUTARAN & AKSESIBILITAS'),
        _SettingsGroup(
          children: [
            _SettingRow(
              icon: Icons.motion_photos_off_outlined,
              title: 'Reduce Motion',
              subtitle: 'Kurangi animasi transisi dan dekoratif',
              trailing: Switch(
                value: state.reduceMotion,
                onChanged: state.setReduceMotion,
              ),
            ),
            _SettingRow(
              icon: Icons.repeat_rounded,
              title: 'Preferensi pemutaran',
              subtitle:
                  'Repeat $repeatLabel • acak ${state.shuffle ? 'aktif' : 'mati'}',
              trailing: IconButton(
                tooltip: 'Baca status preferensi',
                onPressed: () => showAppMessage(
                  context,
                  'Repeat dan shuffle diatur dari layar Now Playing. Semua '
                  'preferensi tersimpan di perangkat.',
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
        const _GroupLabel('KOLEKSI & PENYIMPANAN'),
        _SettingsGroup(
          children: [
            _SettingRow(
              icon: Icons.library_music_outlined,
              title: 'Isi library',
              subtitle:
                  '${state.songs.length} lagu • ${state.videos.length} video',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: SonoraColors.muted,
              ),
            ),
            _StorageRow(
              key: ValueKey(
                'storage-${state.songs.length}-${state.videos.length}',
              ),
            ),
            _SettingRow(
              icon: Icons.audio_file_outlined,
              title: 'Impor musik',
              subtitle: 'MP3, M4A, AAC, WAV, FLAC, OGG, OPUS',
              trailing: IconButton(
                tooltip: 'Impor musik dari perangkat',
                onPressed: () => runMediaImport(context, MediaKind.audio),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            _SettingRow(
              icon: Icons.video_file_outlined,
              title: 'Impor video',
              subtitle: 'MP4, M4V, MKV, WEBM, 3GP',
              trailing: IconButton(
                tooltip: 'Impor video dari perangkat',
                onPressed: () => runMediaImport(context, MediaKind.video),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            if (unavailable > 0)
              _SettingRow(
                icon: Icons.cleaning_services_outlined,
                title: 'Bersihkan media tidak tersedia',
                subtitle: '$unavailable media tidak dapat diakses',
                trailing: IconButton(
                  tooltip: 'Hapus media tidak tersedia',
                  onPressed: () async {
                    final removed = await state.removeUnavailableMedia();
                    if (!context.mounted) return;
                    showAppMessage(
                      context,
                      removed == 0
                          ? 'Tidak ada media yang perlu dibersihkan.'
                          : '$removed media dibersihkan dari library.',
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
          ],
        ),
        const _GroupLabel('PRIVASI & APLIKASI'),
        _SettingsGroup(
          children: [
            _SettingRow(
              icon: Icons.lock_outline_rounded,
              title: 'Privasi',
              subtitle: 'Tanpa akun, unggah media, atau telemetri',
              trailing: IconButton(
                tooltip: 'Baca informasi privasi',
                onPressed: () => _showAbout(context, privacy: true),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            _SettingRow(
              icon: Icons.info_outline_rounded,
              title: 'Tentang SONORA',
              subtitle: 'Versi 1.0.0',
              trailing: IconButton(
                tooltip: 'Tentang aplikasi',
                onPressed: () => _showAbout(context),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Center(child: BrandMark(size: 32, compact: true)),
        const SizedBox(height: 12),
        Text(
          'Ruangmu. Koleksimu. Offline.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _showAbout(BuildContext context, {bool privacy = false}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(privacy ? 'Privasi sejak awal' : 'SONORA'),
        content: SingleChildScrollView(
          child: Text(
            privacy
                ? 'Seluruh fungsi berjalan lokal: pemutaran, pencarian, antrean, '
                      'playlist, dan metadata tersimpan di perangkat ini. Tidak '
                      'ada akun, unggahan media, atau telemetri. Aplikasi meminta '
                      'akses berkas hanya melalui pemilih berkas sistem saat '
                      'kamu mengimpor media, dan izin notifikasi hanya untuk '
                      'kontrol pemutaran. Menghapus item dari library tidak '
                      'menghapus berkas asli di perangkat.'
                : 'Pemutar musik dan video lokal offline-first.\n\n'
                      'Versi 1.0.0 memuat impor media dari perangkat, pemutaran '
                      'MP3 dan MP4, antrean serta playlist yang tersimpan, '
                      'notifikasi media, dan pemulihan posisi terakhir.\n\n'
                      'Artwork diambil dari cover di dalam berkas bila tersedia; '
                      'bila tidak, aplikasi menggambar artwork sendiri. Font '
                      'Manrope digunakan berdasarkan SIL Open Font License.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SonoraScope.of(context);
    return FutureBuilder<StorageSummary>(
      future: state.storageSummary(),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        return _SettingRow(
          icon: Icons.storage_outlined,
          title: 'Penyimpanan salinan media',
          subtitle: summary == null
              ? 'Menghitung…'
              : '${_formatBytes(summary.bytes)} untuk '
                    '${summary.audioCount + summary.videoCount} media',
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: SonoraColors.muted,
          ),
        );
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(letterSpacing: 1.3, fontWeight: FontWeight.w700),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Card(child: Column(children: children)),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: SonoraColors.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: SonoraColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    ),
  );
}

class _AccentChoice extends StatelessWidget {
  const _AccentChoice({
    required this.cyan,
    required this.selected,
    required this.onTap,
  });
  final bool cyan;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = cyan ? SonoraColors.accent : SonoraColors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: cyan ? 'Gunakan aksen cyan' : 'Gunakan aksen violet',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SonoraColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : SonoraColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: cyan
                            ? const Color(0xFF082226)
                            : const Color(0xFF171024),
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  cyan ? 'Cyan' : 'Violet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
