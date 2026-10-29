import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'media/media_item.dart';
import 'theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.compact = false});
  final double size;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SonoraColors.primary, Color(0xFF6B54B9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * .3),
          ),
          child: CustomPaint(painter: _SoundMarkPainter()),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Text(
            'SONORA',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              letterSpacing: 2.8,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _SoundMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .66, size.height * .2)
      ..cubicTo(
        size.width * .36,
        size.height * .11,
        size.width * .28,
        size.height * .38,
        size.width * .54,
        size.height * .47,
      )
      ..cubicTo(
        size.width * .79,
        size.height * .57,
        size.width * .59,
        size.height * .86,
        size.width * .29,
        size.height * .74,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = SonoraColors.background
        ..strokeWidth = size.width * .1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(size.width * .65, size.height * .69),
      Offset(size.width * .78, size.height * .56),
      Paint()
        ..color = SonoraColors.accent
        ..strokeWidth = size.width * .055
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MediaArtwork extends StatelessWidget {
  const MediaArtwork({
    super.key,
    required this.style,
    this.dimension = 64,
    this.radius = 16,
    this.hero = false,
    this.artworkPath,
  });

  /// Artwork untuk sebuah [MediaItem]: memakai cover dari berkas bila tersedia,
  /// dan artwork prosedural sebagai fallback.
  MediaArtwork.forItem(
    MediaItem item, {
    super.key,
    this.dimension = 64,
    this.radius = 16,
    this.hero = false,
  }) : style = item.style,
       artworkPath = item.artworkPath;

  final ArtworkStyle style;
  final double dimension;
  final double radius;
  final bool hero;

  /// Path cover hasil ekstraksi metadata, bila ada.
  final String? artworkPath;

  @override
  Widget build(BuildContext context) {
    final fallback = CustomPaint(painter: _ArtworkPainter(style, hero));
    final path = artworkPath;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: path == null || path.isEmpty
              ? fallback
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _ArtworkPainter extends CustomPainter {
  const _ArtworkPainter(this.style, this.hero);
  final ArtworkStyle style;
  final bool hero;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    final palettes = <ArtworkStyle, List<Color>>{
      ArtworkStyle.waves: [
        const Color(0xFF263A61),
        const Color(0xFF65DDE3),
        const Color(0xFFAE8CFF),
      ],
      ArtworkStyle.midnight: [
        const Color(0xFF111D3D),
        const Color(0xFF89ACF7),
        const Color(0xFFAE8CFF),
      ],
      ArtworkStyle.orbital: [
        const Color(0xFF302341),
        const Color(0xFFAE8CFF),
        const Color(0xFFF19EAC),
      ],
      ArtworkStyle.bloom: [
        const Color(0xFF422C41),
        const Color(0xFFF19EAC),
        const Color(0xFFF0C980),
      ],
      ArtworkStyle.cassette: [
        const Color(0xFF233F43),
        const Color(0xFF65DDE3),
        const Color(0xFFF0C980),
      ],
      ArtworkStyle.cinema: [
        const Color(0xFF191D36),
        const Color(0xFF89ACF7),
        const Color(0xFFAE8CFF),
      ],
    };
    final colors = palettes[style]!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [colors[0], const Color(0xFF141522)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final glowCenter = Offset(w * .72, h * .26);
    canvas.drawCircle(
      glowCenter,
      w * .56,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors[1].withValues(alpha: .35),
            colors[1].withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: w * .56)),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * .012)
      ..strokeCap = StrokeCap.round;
    switch (style) {
      case ArtworkStyle.waves:
        for (var i = 0; i < 3; i++) {
          final path = Path();
          for (var x = -w * .1; x <= w * 1.1; x += w * .04) {
            final y =
                h * (.35 + .19 * i) +
                math.sin(x / w * math.pi * 2 + i * .7) * h * .08;
            x == -w * .1 ? path.moveTo(x, y) : path.lineTo(x, y);
          }
          canvas.drawPath(
            path,
            line..color = colors[(i + 1) % 3].withValues(alpha: .75 - i * .15),
          );
        }
        canvas.drawCircle(
          Offset(w * .69, h * .26),
          w * .09,
          Paint()..color = colors[2].withValues(alpha: .7),
        );
      case ArtworkStyle.midnight:
        canvas.drawCircle(
          Offset(w * .64, h * .35),
          w * .24,
          Paint()
            ..shader = LinearGradient(colors: [colors[1], colors[2]])
                .createShader(
                  Rect.fromCircle(
                    center: Offset(w * .64, h * .35),
                    radius: w * .24,
                  ),
                ),
        );
        canvas.drawCircle(
          Offset(w * .72, h * .29),
          w * .22,
          Paint()..color = colors[0],
        );
        for (var i = 0; i < 7; i++) {
          canvas.drawCircle(
            Offset(w * (.16 + (i * .173) % .68), h * (.18 + (i * .239) % .55)),
            math.max(1, w * .008),
            Paint()..color = SonoraColors.text.withValues(alpha: .65),
          );
        }
      case ArtworkStyle.orbital:
        canvas.save();
        canvas.translate(w * .5, h * .48);
        canvas.rotate(-.5);
        for (var i = 0; i < 3; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * (.85 - i * .14),
              height: h * (.36 - i * .025),
            ),
            line..color = colors[(i + 1) % 3].withValues(alpha: .7),
          );
        }
        canvas.drawCircle(
          Offset.zero,
          w * .18,
          Paint()
            ..shader = RadialGradient(colors: [colors[2], colors[0]])
                .createShader(
                  Rect.fromCircle(center: Offset.zero, radius: w * .18),
                ),
        );
        canvas.restore();
      case ArtworkStyle.bloom:
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final center = Offset(
            w * .5 + math.cos(angle) * w * .17,
            h * .46 + math.sin(angle) * h * .17,
          );
          canvas.drawCircle(
            center,
            w * .18,
            Paint()..color = colors[(i % 2) + 1].withValues(alpha: .38),
          );
        }
        canvas.drawCircle(
          Offset(w * .5, h * .46),
          w * .17,
          Paint()..color = colors[1].withValues(alpha: .6),
        );
        canvas.drawCircle(
          Offset(w * .5, h * .46),
          w * .07,
          Paint()..color = colors[2],
        );
      case ArtworkStyle.cassette:
        final box = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .16, h * .25, w * .68, h * .53),
          Radius.circular(w * .07),
        );
        canvas.drawRRect(
          box,
          Paint()
            ..color = const Color(0xFF19252F)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(box, line..color = colors[1].withValues(alpha: .75));
        for (final x in [.35, .65]) {
          canvas.drawCircle(
            Offset(w * x, h * .49),
            w * .1,
            Paint()..color = colors[1].withValues(alpha: .25),
          );
          canvas.drawCircle(
            Offset(w * x, h * .49),
            w * .065,
            line..color = colors[1],
          );
        }
        canvas.drawLine(
          Offset(w * .29, h * .68),
          Offset(w * .71, h * .68),
          line..color = colors[2],
        );
      case ArtworkStyle.cinema:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .1, h * .19, w * .8, h * .55),
            Radius.circular(w * .03),
          ),
          line..color = colors[1].withValues(alpha: .7),
        );
        canvas.drawPath(
          Path()
            ..moveTo(w * .42, h * .32)
            ..lineTo(w * .42, h * .61)
            ..lineTo(w * .65, h * .465)
            ..close(),
          Paint()..color = colors[2].withValues(alpha: .85),
        );
        for (var i = 0; i < 4; i++) {
          canvas.drawRect(
            Rect.fromLTWH(w * (.14 + i * .19), h * .13, w * .1, h * .04),
            Paint()..color = colors[1].withValues(alpha: .5),
          );
        }
    }
    if (hero) {
      canvas.drawCircle(
        Offset(w * .18, h * .85),
        math.max(2, w * .007),
        Paint()..color = SonoraColors.text.withValues(alpha: .65),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArtworkPainter oldDelegate) =>
      style != oldDelegate.style || hero != oldDelegate.hero;
}

class MediaIllustration extends StatelessWidget {
  const MediaIllustration({super.key, this.dimension = 150});
  final double dimension;
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: CustomPaint(painter: _IllustrationPainter()),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w / 2, h * .55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * .86),
        width: w * .7,
        height: h * .12,
      ),
      Paint()..color = SonoraColors.primary.withValues(alpha: .09),
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .08
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: center, width: w * .6, height: h * .62),
      math.pi,
      math.pi,
      false,
      arc
        ..shader = const LinearGradient(
          colors: [SonoraColors.primary, SonoraColors.accent],
        ).createShader(Offset.zero & size),
    );
    for (final x in [.2, .8]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * x, h * .57),
            width: w * .18,
            height: h * .28,
          ),
          Radius.circular(w * .065),
        ),
        Paint()..color = SonoraColors.raised,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * x, h * .57),
            width: w * .08,
            height: h * .17,
          ),
          Radius.circular(w * .03),
        ),
        Paint()..color = x == .2 ? SonoraColors.primary : SonoraColors.accent,
      );
    }
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * (.42 + i * .055),
            h * (.72 - (i % 3) * .06),
            w * .027,
            h * (.07 + (i % 3) * .06),
          ),
          Radius.circular(w * .02),
        ),
        Paint()..color = SonoraColors.primary.withValues(alpha: .5 + i * .1),
      );
    }
    canvas.drawCircle(
      Offset(w * .83, h * .2),
      w * .035,
      Paint()..color = SonoraColors.accent.withValues(alpha: .7),
    );
    canvas.drawCircle(
      Offset(w * .16, h * .25),
      w * .024,
      Paint()..color = SonoraColors.primary.withValues(alpha: .7),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Equalizer extends StatefulWidget {
  const Equalizer({super.key, required this.animate, this.size = 20});
  final bool animate;
  final double size;
  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.animate) controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Equalizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.animate ? controller.repeat(reverse: true) : controller.stop();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (index) {
          final amount = widget.animate
              ? .35 +
                    .65 *
                        (math
                            .sin(controller.value * math.pi + index * 1.6)
                            .abs())
              : .6 + index * .1;
          return Container(
            width: 3,
            height: widget.size * amount,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: SonoraColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
