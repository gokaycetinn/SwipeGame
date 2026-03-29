import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fut_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/neon_button.dart';
import '../../game/data/game_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onStart,
    required this.modes,
  });

  final ValueChanged<String> onStart;
  final List<GameModeConfig> modes;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return FutBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Column(
                children: [
                  const _TopBar(),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: -18,
                          child: SizedBox(
                            width: 400,
                            height: 400,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                'assets/Icon/Icon.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.sports_soccer_rounded,
                                  size: 110,
                                ),
                              ),
                            ),
                          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 300,
                          child: Column(
                            children: [
                              Text(
                                '60 Saniye. Sonsuz Kart. Kusursuz Kaydirma.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: AppColors.textMuted, fontSize: 17),
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                children: [
                                  Expanded(
                                    child: _FeatureTile(
                                      icon: Icons.flash_on_rounded,
                                      iconColor: AppColors.neonGreen,
                                      title: 'SIMSEK\nHIZI',
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: _FeatureTile(
                                      icon: Icons.emoji_events_rounded,
                                      iconColor: AppColors.amber,
                                      title: 'UST\nLIG',
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: _FeatureTile(
                                      icon: Icons.dynamic_feed_rounded,
                                      iconColor: AppColors.hotPink,
                                      title: 'DINAMIK\nAKIS',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              NeonButton(
                                title: 'OYUNU BASLAT',
                                icon: Icons.play_arrow_rounded,
                                onTap: () async {
                                  final modeId = await _showModePicker(context);
                                  if (!context.mounted || modeId == null) {
                                    return;
                                  }
                                  widget.onStart(modeId);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showModePicker(BuildContext context) {
    final modes = widget.modes;
    if (modes.isEmpty) {
      return Future.value('standard');
    }

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.hotPink.withValues(alpha: 0.25)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102238), Color(0xFF0B1626)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x4D000000), blurRadius: 30, offset: Offset(0, 12)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text('MOD SEC', style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 6),
                Text(
                  'Oyunu hangi ritimde oynamak istiyorsun?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                ...modes.map((mode) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).pop(mode.id),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.hotPink.withValues(alpha: 0.18),
                              ),
                              child: const Icon(Icons.tune_rounded, color: AppColors.hotPink),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mode.name, style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text(
                                    mode.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: const Color(0xFFC7D6E8), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_rounded, size: 30),
        ),
        Expanded(
          child: Text(
            'FUTSWIPE',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.bar_chart_rounded, size: 30),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
          ),
        ],
      ),
    );
  }
}
