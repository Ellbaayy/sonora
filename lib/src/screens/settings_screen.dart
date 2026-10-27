import 'package:flutter/material.dart';

import '../../main.dart';
import '../artwork.dart';
import '../preview_state.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import 'library_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = PreviewScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const ScreenHeader(
          title: 'Pengaturan',
          subtitle: 'Atur ruang dengarmu.',
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: PreviewNotice(compact: true),
        ),
        const SizedBox(height: 24),
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
                  'Repeat, shuffle, dan autoplay diatur dari preview player',
              trailing: IconButton(
                tooltip: 'Baca status preferensi',
                onPressed: () => showAppMessage(
                  context,
                  'Pengaturan playback masih sesi preview. Belum ada preferensi persisten atau autoplay.',
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
              icon: state.previewMode
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              title: 'Tampilan data contoh',
              subtitle: state.previewMode
                  ? 'Koleksi contoh sedang ditampilkan'
                  : 'Koleksi kosong sedang ditampilkan',
              trailing: Switch(
                value: state.previewMode,
                onChanged: (value) {
                  value ? state.showPreview() : state.showEmptyLibrary();
                },
              ),
            ),
            _SettingRow(
              icon: Icons.folder_open_outlined,
              title: 'Impor media',
              subtitle: 'MP3 dan MP4 • integrasi perangkat belum aktif',
              trailing: IconButton(
                tooltip: 'Buka alur impor',
                onPressed: () =>
                    showImportPreview(context, kind: MediaKind.audio),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            _SettingRow(
              icon: Icons.storage_outlined,
              title: 'Informasi penyimpanan',
              subtitle: 'Belum ada media perangkat yang dipindai',
              trailing: IconButton(
                tooltip: 'Lihat status penyimpanan',
                onPressed: () => showAppMessage(
                  context,
                  'Penggunaan penyimpanan belum dapat dihitung sebelum integrasi media dan database lokal.',
                ),
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
              subtitle: 'Versi 0.1.0 • tahap frontend',
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
                ? 'Fungsi inti dirancang untuk bekerja secara lokal. Tahap frontend ini tidak mengimpor, membaca, atau mengunggah media perangkat. Tidak ada akun maupun telemetri. Penghapusan item dari library tidak boleh menghapus file asli.'
                : 'Pemutar musik dan video lokal offline-first.\n\nVersi 0.1.0 merupakan preview frontend. Backend lokal/media service, file picker, playback, database, dan persistensi belum diimplementasikan.\n\nArtwork dan ilustrasi digambar secara lokal oleh kode aplikasi. Font Manrope digunakan berdasarkan SIL Open Font License; salinan lisensi disertakan dalam proyek. Tidak ada aset Storyset yang digunakan pada tahap ini.',
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
