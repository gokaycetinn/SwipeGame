import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/fut_background.dart';
import '../../../core/widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  @override
  Widget build(BuildContext context) {
    return FutBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ProfileTopBar(),
            const SizedBox(height: 20),
            Text('Statistics', style: Theme.of(context).textTheme.displayMedium),
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 68,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFFFA7BA),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: _QuickStat(icon: Icons.emoji_events_rounded, value: '14', label: 'HIGH SCORE')),
                SizedBox(width: 10),
                Expanded(child: _QuickStat(icon: Icons.sports_soccer_rounded, value: '42', label: 'TOTAL GAMES')),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: _QuickStat(icon: Icons.trending_up_rounded, value: '8.2', label: 'AVG SCORE')),
                SizedBox(width: 10),
                Expanded(child: _QuickStat(icon: Icons.flash_on_rounded, value: '7', label: 'BEST STREAK')),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'PREFERENCES',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  _PreferenceTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound Effects',
                    value: _soundEnabled,
                    onChanged: (v) => setState(() => _soundEnabled = v),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                  _PreferenceTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    value: _hapticEnabled,
                    onChanged: (v) => setState(() => _hapticEnabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'DATA MANAGEMENT',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  Text(
                    'Reset Statistics',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFFFFB0BE),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  const Icon(Icons.refresh_rounded, color: Color(0xFFFFB0BE)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(0),
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'STAY ON TOP',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: const Color(0xFFFFB0BE),
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You are in the top 15% of players this season.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings_rounded, size: 30)),
        Expanded(
          child: Text(
            'FUTSWIPE',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.bar_chart_rounded, size: 30)),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFC4D0)),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.displayMedium),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        child: Icon(icon, size: 22),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF00D45E),
      ),
    );
  }
}
