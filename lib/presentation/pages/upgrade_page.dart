import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:translate_app/core/app_links.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/presentation/pages/auth/login_page.dart';
import 'package:translate_app/presentation/viewmodels/auth_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/subscription_viewmodel.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/l10n/l10n.dart';

class _PlanStyle {
  final String name;
  final Color color;

  const _PlanStyle(this.name, this.color);
}

const _styles = {
  PlanOption.standard: _PlanStyle('Standard', Colors.lightBlueAccent),
  PlanOption.premium: _PlanStyle('Premium', Colors.amberAccent),
};

class _Feature {
  final IconData icon;
  final String title;
  final String detail;

  const _Feature(this.icon, this.title, this.detail);
}

List<_Feature> get _sharedFeatures => [
  _Feature(
    Icons.auto_awesome_rounded,
    l10n.featTranslations,
    l10n.featTranslationsDetail,
  ),
  _Feature(Icons.school_rounded, l10n.studyWithAi, l10n.featStudyDetail),
  _Feature(Icons.photo_camera_rounded, l10n.featPhoto, l10n.featPhotoDetail),
  _Feature(
    Icons.library_add_rounded,
    l10n.featPhotoWords,
    l10n.featPhotoWordsDetail,
  ),
  _Feature(Icons.quiz_rounded, l10n.featDecks, l10n.featDecksDetail),
];

// Spelled out per plan (no "everything in Standard"); Premium-only first.
List<_Feature> _featuresOf(PlanOption plan, {required bool trial}) =>
    switch (plan) {
      PlanOption.standard => _sharedFeatures,
      PlanOption.premium => [
        _Feature(
          Icons.graphic_eq_rounded,
          l10n.featLive,
          '${l10n.featLiveDetail}${trial ? '*' : ''}',
        ),
        ..._sharedFeatures,
      ],
    };

/// A subscription belongs to an account, so guests sign in first.
bool _requireAccount(BuildContext context) {
  if (context.read<AuthViewModel>().isAuthenticated) return true;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.signInToSubscribe)));
  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  return false;
}

Future<void> restorePurchases(BuildContext context) async {
  if (!_requireAccount(context)) return;
  final messenger = ScaffoldMessenger.of(context);
  final outcome = await context.read<SubscriptionViewModel>().restore();
  messenger.showSnackBar(
    SnackBar(
      content: Text(switch (outcome) {
        RestoreOutcome.restored => l10n.restoreDone,
        RestoreOutcome.nothing => l10n.restoreNothing,
        RestoreOutcome.failed => l10n.restoreFailed,
      }),
    ),
  );
}

/// Plans screen: pick Standard or Premium (Premium preselected), see exactly
/// what that plan includes and subscribe from the pinned button. Prices and
/// the trial come from the App Store through RevenueCat.
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  late PlanOption _selected;

  bool get _onPremium => switch (context.read<EntitlementsViewModel>().tier) {
    AppTier.premium || AppTier.trialPremium => true,
    _ => false,
  };

  bool get _onStandard => switch (context.read<EntitlementsViewModel>().tier) {
    AppTier.standard || AppTier.trialStandard => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    // The plan you're on, else the recommended Premium.
    _selected = _onStandard ? PlanOption.standard : PlanOption.premium;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SubscriptionViewModel>().load();
    });
  }

  Future<void> _buy() async {
    if (!_requireAccount(context)) return;
    final messenger = ScaffoldMessenger.of(context);
    // Apple moves Premium down to Standard when the paid period ends.
    final downgrade = _selected == PlanOption.standard && _onPremium;
    final outcome = await context.read<SubscriptionViewModel>().buy(_selected);
    if (outcome == PurchaseOutcome.cancelled) return;
    if (outcome == PurchaseOutcome.done) HapticFeedback.successNotification();
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (outcome) {
          PurchaseOutcome.done when downgrade => l10n.switchScheduled,
          PurchaseOutcome.done => l10n.purchaseDone,
          _ => l10n.purchaseFailed,
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tier = context.watch<EntitlementsViewModel>().tier;
    final plans = context.watch<SubscriptionViewModel>();
    final onStandard =
        tier == AppTier.standard || tier == AppTier.trialStandard;
    final onPremium = tier == AppTier.premium || tier == AppTier.trialPremium;
    final price = plans.priceOf(_selected);
    final trialDays = plans.trialDaysOf(_selected);
    // Apple decides who gets the trial: one per Apple ID in the group.
    final trial = !onStandard && !onPremium && plans.trialAvailable(_selected);
    final style = _styles[_selected]!;
    final cta = _ctaFor(
      _selected,
      onStandard: onStandard,
      onPremium: onPremium,
      price: price,
      trialDays: trial ? trialDays : null,
      standardSwitch: plans.standardSwitch,
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
            Text(
              l10n.plansHeadline,
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
                  ? l10n.plansTrialLine(trialDays!)
                  : l10n.yourPlanLine(tier.label),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 18),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final option in PlanOption.values) ...[
                    if (option != PlanOption.values.first)
                      const SizedBox(width: 10),
                    Expanded(
                      child: _PlanTile(
                        plan: _styles[option]!,
                        price: plans.priceOf(option),
                        badge: option == PlanOption.premium
                            ? l10n.recommended
                            : null,
                        selected: _selected == option,
                        current: option == PlanOption.premium
                            ? onPremium
                            : onStandard,
                        trialDays:
                            !onStandard &&
                                !onPremium &&
                                plans.trialAvailable(option)
                            ? plans.trialDaysOf(option)
                            : null,
                        onTap: () => setState(() => _selected = option),
                      ),
                    ),
                  ],
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
                  color: style.color,
                  features: _featuresOf(_selected, trial: trial),
                ),
              ),
            ),
            if (trial) ...[
              const SizedBox(height: 14),
              _TrialTimeline(plan: style, price: price!, days: trialDays!),
            ],
            if (trial && _selected == PlanOption.premium) ...[
              const SizedBox(height: 10),
              Text(
                l10n.liveTrialNote,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            if (plans.loadFailed) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.plansLoadFailed,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(onPressed: plans.load, child: Text(l10n.tryAgain)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '${trial ? l10n.trialTerms(trialDays!) : ''}${l10n.renewalTerms}',
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
                  (l10n.restorePurchases, () => restorePurchases(context)),
                  (l10n.termsOfUse, () => AppLinks.open(AppLinks.termsOfUse)),
                  (
                    l10n.privacyPolicy,
                    () => AppLinks.open(AppLinks.privacyPolicy),
                  ),
                ])
                  TextButton(
                    onPressed: plans.isBusy ? null : onPressed,
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
          color: style.color,
          label: cta.label,
          subtitle: cta.subtitle,
          busy: plans.isBusy,
          onTap: cta.enabled && !plans.isBusy ? _buy : null,
        ),
      ),
    );
  }

  static ({String label, String? subtitle, bool enabled}) _ctaFor(
    PlanOption selected, {
    required bool onStandard,
    required bool onPremium,
    required String? price,
    required int? trialDays,
    required ({DateTime? at})? standardSwitch,
  }) {
    if ((selected == PlanOption.premium && onPremium) ||
        (selected == PlanOption.standard && onStandard)) {
      return (label: l10n.currentPlan, subtitle: null, enabled: false);
    }
    // Not loaded from the App Store yet (or it failed).
    final enabled = price != null;
    if (selected == PlanOption.standard && standardSwitch != null) {
      final at = standardSwitch.at;
      return (
        label: l10n.switchPlanned,
        subtitle: at == null
            ? l10n.switchAtPeriodEnd
            : l10n.switchStartsOn(
                DateFormat.yMMMMd(l10n.localeName).format(at),
              ),
        enabled: false,
      );
    }
    if (selected == PlanOption.standard && onPremium) {
      return (
        label: l10n.switchToStandard,
        subtitle: enabled ? l10n.switchStartsLater(price) : null,
        enabled: enabled,
      );
    }
    if (onStandard) {
      return (
        label: l10n.upgradeToPremium,
        subtitle: enabled ? l10n.perMonthCancelAnytime(price) : null,
        enabled: enabled,
      );
    }
    if (trialDays != null) {
      return (
        label: l10n.startTrial(trialDays),
        subtitle: enabled ? l10n.thenPerMonth(price) : null,
        enabled: enabled,
      );
    }
    return (
      label: l10n.subscribe,
      subtitle: enabled ? l10n.perMonthCancelAnytime(price) : null,
      enabled: enabled,
    );
  }
}

class _PlanTile extends StatelessWidget {
  final _PlanStyle plan;
  final String? price;
  final bool selected;
  final bool current;
  final int? trialDays;
  final String? badge;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.price,
    required this.selected,
    required this.current,
    required this.trialDays,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final note = current
        ? l10n.yourPlan
        : trialDays != null
        ? l10n.daysFree(trialDays!)
        : null;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.planSemantics(plan.name, price ?? ''),
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
                // Filled in once the App Store answers.
                price == null ? '…' : l10n.pricePerMonth(price!),
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

/// Today → billing day. Apple itself reminds people before a trial ends.
class _TrialTimeline extends StatelessWidget {
  final _PlanStyle plan;
  final String price;
  final int days;

  const _TrialTimeline({
    required this.plan,
    required this.price,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        Icons.lock_open_rounded,
        l10n.trialToday,
        l10n.trialTodayDetail(plan.name),
      ),
      (
        Icons.event_available_rounded,
        l10n.trialDay(days),
        l10n.trialDay14Detail(price),
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
          Text(
            l10n.howTrialWorks,
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
  final bool busy;
  final VoidCallback? onTap;

  const _CtaBar({
    required this.color,
    required this.label,
    required this.subtitle,
    required this.busy,
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
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : Text(
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
