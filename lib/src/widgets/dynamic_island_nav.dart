import 'dart:ui';

import 'package:flutter/material.dart';

import '../artwork.dart';
import '../media/media_item.dart';
import '../theme.dart';

/// Satu tujuan navigasi pada dynamic island.
class IslandDestination {
  const IslandDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Navigasi bawah berbentuk kapsul mengambang.
///
/// Perilaku khas *dynamic island*: kapsul tidak selebar layar, item aktif
/// mengembang dan menampilkan labelnya sementara item lain menyusut menjadi
/// ikon saja, dan mini player menempel sebagai pulau kecil di atasnya. Semua
/// animasi mengikuti [reduceMotion].
class DynamicIslandNavigation extends StatelessWidget {
  const DynamicIslandNavigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.reduceMotion,
  });

  final List<IslandDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 320);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: SonoraColors.raised.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: SonoraColors.border.withValues(alpha: .9),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Label item aktif disembunyikan pada lebar sempit atau saat
                // skala teks besar agar kapsul tidak melampaui layar.
                final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
                final compact = constraints.maxWidth < 330 * scale;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final (index, destination) in destinations.indexed)
                      _IslandItem(
                        key: ValueKey('nav-${destination.label}'),
                        destination: destination,
                        selected: index == selectedIndex,
                        duration: duration,
                        showLabel: !compact,
                        onTap: () => onSelected(index),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IslandItem extends StatelessWidget {
  const _IslandItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.duration,
    required this.onTap,
    this.showLabel = true,
  });

  final IslandDestination destination;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: SonoraColors.text,
      fontSize: textScaler.scale(12),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 16 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? LinearGradient(
                    colors: [
                      SonoraColors.primary.withValues(alpha: .26),
                      SonoraColors.accent.withValues(alpha: .14),
                    ],
                  )
                : null,
            border: selected
                ? Border.all(color: SonoraColors.primary.withValues(alpha: .38))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: selected ? SonoraColors.primary : SonoraColors.muted,
              ),
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: selected && showLabel
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(destination.label, style: labelStyle),
                      )
                    : const SizedBox(width: 0, height: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kapsul mini player yang mengambang di atas dynamic island.
///
/// Ketuk untuk membuka Now Playing; garis tipis di bawah judul menunjukkan
/// kemajuan pemutaran tanpa perlu membuka layar penuh.
class IslandMiniPlayer extends StatelessWidget {
  const IslandMiniPlayer({
    super.key,
    required this.item,
    required this.playing,
    required this.position,
    required this.duration,
    required this.reduceMotion,
    required this.onOpen,
    required this.onTogglePlay,
  });

  final MediaItem item;
  final bool playing;
  final Duration position;
  final Duration? duration;
  final bool reduceMotion;
  final VoidCallback onOpen;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final total = duration?.inMilliseconds ?? 0;
    final progress = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: SonoraColors.raised.withValues(alpha: .88),
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                child: Row(
                  children: [
                    MediaArtwork.forItem(item, dimension: 40, radius: 999),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 2.5,
                              backgroundColor: SonoraColors.border,
                              valueColor: const AlwaysStoppedAnimation(
                                SonoraColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: playing ? 'Jeda' : 'Putar',
                      onPressed: onTogglePlay,
                      icon: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(playing),
                          color: SonoraColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
