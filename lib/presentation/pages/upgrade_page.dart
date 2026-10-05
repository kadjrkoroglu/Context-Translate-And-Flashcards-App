import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';

enum _Plan { standard, premium }

class _PlanInfo {
  final String name;
  final String price;
  final Color color;

  const _PlanInfo(this.name, this.price, this.color);
}

// Prices are placeholders until App Store prices are loaded from StoreKit.
const _standard = _PlanInfo('Standard', r'$5.99', Colors.lightBlueAccent);
const _premium = _PlanInfo('Premium', r'$9.99', Colors.amberAccent);

class _Feature {
  final IconData icon;
  final String title;
  final String detail;

  const _Feature(this.icon, this.title, this.detail);
}

const _sharedFeatures = [
  _Feature(
    Icons.auto_awesome_rounded,
    'Unlimited AI translations',
    'Standard, formal and slang versions of every sentence.',
  ),
  _Feature(
    Icons.photo_camera_rounded,
    'AI photo translation',
    'Point the camera at signs, menus and documents.',
  ),
  _Feature(
    Icons.library_add_rounded,
    'Words from photos to your decks',
    'AI picks out the useful words; add them in one tap.',
  ),
  _Feature(
    Icons.quiz_rounded,
    'Unlimited decks and cards',
    'Save every word you want to learn and study it later.',
  ),
];

// Spelled out per plan (no "everything in Standard"); Premium-only first.
List<_Feature> _featuresOf(_Plan plan, {required bool trial}) => switch (plan) {
  _Plan.standard => _sharedFeatures,
  _Plan.premium => [
    _Feature(
      Icons.graphic_eq_rounded,
      'Live translation',
      'Speech translated as it is spoken, with live captions. '
          '60 min/month${trial ? '*' : ''}',
    ),
    const _Feature(
      Icons.school_rounded,
      'Study with AI',
      'An AI tutor quizzes you on your saved words and checks every answer.',
    ),
    ..._sharedFeatures,
  ],
};

/// Billing isn't wired up yet; every purchase button says so.
void showSubscriptionsComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Coming soon — subscriptions aren't live yet."),
    ),
  );
}

/// Plans screen: pick Standard or Premium (Premium preselected), see exactly
/// what that plan includes, start the trial from the pinned button. Billing
/// isn't wired up yet, so the buttons only say "coming soon"; the tier can
/// only change on the server.
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  _Plan _selected = _Plan.premium;

  @override
  Widget build(BuildContext context) {
    final tier = context.watch<EntitlementsViewModel>().tier;
    final onStandard =
        tier == AppTier.standard || tier == AppTier.trialStandard;
    final onPremium = tier == AppTier.premium || tier == AppTier.trialPremium;
    // One free trial per account: only people on no plan are offered it.
    final trial = !onStandard && !onPremium;
    final plan = _selected == _Plan.premium ? _premium : _standard;
    final cta = _ctaFor(
      _selected,
      onStandard: onStandard,
      onPremium: onPremium,
    );

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const Text(
              'Translate more.\nRemember more.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              trial
                  ? 'Try any plan free for 14 days. Cancel anytime.'
                  : 'Your plan: ${tier.label}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PlanTile(
                      plan: _standard,
                      selected: _selected == _Plan.standard,
                      current: onStandard,
                      trial: trial,
                      onTap: () => setState(() => _selected = _Plan.standard),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlanTile(
                      plan: _premium,
                      badge: 'Recommended',
                      selected: _selected == _Plan.premium,
                      current: onPremium,
                      trial: trial,
                      onTap: () => setState(() => _selected = _Plan.premium),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _FeatureList(
                  key: ValueKey(_selected),
                  color: plan.color,
                  features: _featuresOf(_selected, trial: trial),
                ),
              ),
            ),
            if (trial) ...[
              const SizedBox(height: 14),
              _TrialTimeline(plan: plan),
            ],
            if (trial && _selected == _Plan.premium) ...[
              const SizedBox(height: 10),
              const Text(
                '* The Premium trial includes 5 minutes of Live translation.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '${trial ? _trialTerms : ''}$_renewalTerms',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            // Apple wants the terms and privacy policy linked where people subscribe.
            Wrap(
              spacing: 16,
              children: [
                for (final (label, onPressed) in [
                  (
                    'Restore purchases',
                    () => showSubscriptionsComingSoon(context),
                  ),
                  ('Terms of Use', () => AppLinks.open(AppLinks.termsOfUse)),
                  (
                    'Privacy Policy',
                    () => AppLinks.open(AppLinks.privacyPolicy),
                  ),
                ])
                  TextButton(
                    onPressed: onPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(label),
                  ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _CtaBar(
          color: plan.color,
          label: cta.label,
          subtitle: cta.subtitle,
          onTap: cta.enabled
              ? () => showSubscriptionsComingSoon(context)
              : null,
        ),
      ),
    );
  }

  static const _trialTerms =
      'After the 14-day free trial, the subscription starts automatically '
      'unless you cancel at least 24 hours before the trial ends. One free '
      'trial per account. ';

  static const _renewalTerms =
      'Subscriptions renew automatically each month at the price shown '
      'unless you cancel at least 24 hours before the current period ends. '
      'Payment is charged to your Apple ID. You can manage or cancel your '
      'subscription in your App Store account settings.';

  static ({String label, String? subtitle, bool enabled}) _ctaFor(
    _Plan selected, {
    required bool onStandard,
    required bool onPremium,
  }) {
    final plan = selected == _Plan.premium ? _premium : _standard;
    if ((selected == _Plan.premium && onPremium) ||
        (selected == _Plan.standard && onStandard)) {
      return (label: 'Current plan', subtitle: null, enabled: false);
    }
    if (selected == _Plan.standard && onPremium) {
      return (label: 'Included in Premium', subtitle: null, enabled: false);
    }
    if (onStandard) {
      return (
        label: 'Upgrade to Premium',
        subtitle: '${plan.price}/month · cancel anytime',
        enabled: true,
      );
    }
    return (
      label: 'Start 14-day free trial',
      subtitle: 'then ${plan.price}/month · cancel anytime',
      enabled: true,
    );
  }
}

class _PlanTile extends StatelessWidget {
  final _PlanInfo plan;
  final bool selected;
  final bool current;
  final bool trial;
  final String? badge;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.current,
    required this.trial,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final note = current
        ? 'Your plan'
        : trial
        ? '14 days free'
        : null;
    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.name}, ${plan.price} per month',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
          decoration: BoxDecoration(
            color: selected
                ? plan.color.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? plan.color
                  : Colors.white.withValues(alpha: 0.15),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? plan.color : Colors.white54,
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: plan.color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: plan.color,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan.name,
                style: TextStyle(
                  color: plan.color,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${plan.price}/month',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final Color color;
  final List<_Feature> features;

  const _FeatureList({super.key, required this.color, required this.features});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          for (final f in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f.icon, size: 20, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.detail,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Today → day 12 reminder → day 14 billing. The day-12 reminder is a promise:
/// it must be scheduled when billing goes live.
class _TrialTimeline extends StatelessWidget {
  final _PlanInfo plan;

  const _TrialTimeline({required this.plan});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.lock_open_rounded, 'Today', 'Full access to ${plan.name} starts.'),
      (
        Icons.notifications_active_rounded,
        'Day 12',
        "We'll remind you that your trial is ending.",
      ),
      (
        Icons.event_available_rounded,
        'Day 14',
        'Your subscription starts at ${plan.price}/month unless you cancel.',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How the free trial works',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: plan.color.withValues(
                              alpha: i == 0 ? 0.9 : 0.22,
                            ),
                          ),
                          child: Icon(
                            steps[i].$1,
                            size: 16,
                            color: i == 0 ? Colors.black87 : plan.color,
                          ),
                        ),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              color: plan.color.withValues(alpha: 0.3),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: i < steps.length - 1 ? 14 : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            steps[i].$3,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pinned to the bottom so the button is always in view.
class _CtaBar extends StatelessWidget {
  final Color color;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;

  const _CtaBar({
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2226).withValues(alpha: 0.55),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.12,
                        ),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
