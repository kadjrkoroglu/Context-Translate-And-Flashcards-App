import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/theme/theme.dart';

/// Temporary plan-picker: no billing is wired up yet, so tapping a plan
/// only shows a "coming soon" message instead of ever pretending to charge
/// anyone or granting a tier for free.
class UpgradePage extends StatelessWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<GlassThemeExtension>();
    const Color textColor = Colors.white;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Upgrade', style: TextStyle(color: textColor)),
          iconTheme: const IconThemeData(color: textColor),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const Text(
                'Choose your plan',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Prices to be announced.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _PlanCard(
                glass: glass,
                title: 'Standard',
                accentColor: Colors.lightBlueAccent,
                features: const [
                  'Unlimited AI translations',
                  'Photo translation',
                  'Unlimited decks and cards',
                ],
                onTap: () => _showComingSoon(context),
              ),
              const SizedBox(height: 16),
              _PlanCard(
                glass: glass,
                title: 'Premium',
                accentColor: Colors.amberAccent,
                features: const [
                  'Everything in Standard',
                  'Live translation (60 min/month)',
                  'AI chat using your deck\'s words',
                ],
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon — subscriptions aren\'t live yet.'),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final GlassThemeExtension? glass;
  final String title;
  final Color accentColor;
  final List<String> features;
  final VoidCallback onTap;

  const _PlanCard({
    required this.glass,
    required this.title,
    required this.accentColor,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseGlass =
        glass?.baseGlassColor ?? Colors.white.withValues(alpha: 0.08);
    final borderGlass = glass?.borderGlassColor ?? Colors.white24;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: baseGlass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderGlass),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_rounded, size: 18, color: accentColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Subscribe to $title'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
