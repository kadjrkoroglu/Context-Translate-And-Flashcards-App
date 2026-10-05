import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/entities/entitlements_entity.dart';
import 'package:translate_app/domain/entities/live_entry.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/utils/ai_error_text.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/live_translate_viewmodel.dart';
import 'package:translate_app/presentation/widgets/dropdown.dart';

/// Header row: [Auto-detect] → [target language].
class LiveLanguageHeader extends StatelessWidget {
  const LiveLanguageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LiveTranslateViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const Expanded(child: _AutoDetectChip()),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
                Expanded(
                  child: IgnorePointer(
                    ignoring: vm.isActive,
                    child: Opacity(
                      opacity: vm.isActive ? 0.6 : 1,
                      child: LanguageDropdown(
                        value: vm.targetLanguage,
                        recentLanguages: vm.recentLanguages,
                        showIcons: false,
                        onChanged: (language) {
                          if (language != null) vm.setTargetLanguage(language);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            color: Colors.white.withValues(alpha: 0.1),
            thickness: 0.5,
            height: 12,
          ),
        ),
      ],
    );
  }
}

class _AutoDetectChip extends StatelessWidget {
  const _AutoDetectChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hearing_rounded, color: Colors.white70, size: 18),
          SizedBox(width: 8),
          Text(
            'Auto-detect',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live page body; the main mic button starts and stops it.
class LiveTranslateBody extends StatefulWidget {
  const LiveTranslateBody({super.key});

  @override
  State<LiveTranslateBody> createState() => _LiveTranslateBodyState();
}

class _LiveTranslateBodyState extends State<LiveTranslateBody> {
  final ScrollController _scroll = ScrollController();
  late final LiveTranslateViewModel _vm;
  AppException? _handled;

  @override
  void initState() {
    super.initState();
    _vm = context.read<LiveTranslateViewModel>();
    _vm.addListener(_onChange);
  }

  @override
  void dispose() {
    _vm.removeListener(_onChange);
    _scroll.dispose();
    super.dispose();
  }

  void _onChange() {
    final exception = _vm.exception;
    if (exception is QuotaExceededException &&
        exception.isTrial &&
        !identical(exception, _handled)) {
      _handled = exception;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showTrialUsedDialog(context);
      });
    }
    if (exception is FeatureNotAvailableException &&
        !identical(exception, _handled)) {
      _handled = exception;
      // Not Premium: straight to the plans.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _vm.clearError();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UpgradePage()),
        );
      });
    }
    _followNewText();
  }

  // Follow new text unless the user scrolled up.
  void _followNewText() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.maxScrollExtent - position.pixels < 120) {
        _scroll.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LiveTranslateViewModel>();
    final entitlements = context.watch<EntitlementsViewModel>().entitlements;
    final remaining = vm.remainingSeconds ?? entitlements?.liveQuota.remaining;
    final error = vm.status == LiveStatus.error ? vm.exception : null;
    final trialMinutes = entitlements?.tier == AppTier.trialPremium
        ? (entitlements!.liveQuota.limit ?? 0) ~/ 60
        : null;

    return Column(
      children: [
        _StatusRow(
          vm: vm,
          remainingSeconds: remaining,
          trial: trialMinutes != null,
        ),
        Expanded(
          child: vm.entries.isEmpty
              ? _EmptyState(vm: vm, trialMinutes: trialMinutes)
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: vm.entries.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 28,
                    thickness: 0.5,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  itemBuilder: (context, i) => _EntryView(
                    entry: vm.entries[i],
                    isLatest: i == vm.entries.length - 1,
                  ),
                ),
        ),
        if (error != null) _ErrorBanner(exception: error),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final LiveTranslateViewModel vm;
  final int? remainingSeconds;
  final bool trial;

  const _StatusRow({
    required this.vm,
    required this.remainingSeconds,
    required this.trial,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (vm.status) {
      LiveStatus.connecting => 'Connecting…',
      LiveStatus.listening => 'Listening',
      LiveStatus.error => 'Stopped',
      LiveStatus.idle => 'Ready',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 18,
            child: vm.status == LiveStatus.listening
                ? const _ListeningBars()
                : vm.status == LiveStatus.connecting
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Icon(
                    Icons.graphic_eq_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: vm.status == LiveStatus.idle ? 0.6 : 1,
              ),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (remainingSeconds != null) ...[
            _RemainingChip(
              seconds: remainingSeconds!,
              counting: vm.isActive,
              trial: trial,
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: vm.speakerOn ? 'Mute translated voice' : 'Unmute',
            visualDensity: VisualDensity.compact,
            onPressed: vm.toggleSpeaker,
            icon: Icon(
              vm.speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.white.withValues(alpha: vm.speakerOn ? 0.9 : 0.5),
              size: 22,
            ),
          ),
          if (vm.entries.isNotEmpty && !vm.isActive)
            IconButton(
              tooltip: 'Clear',
              visualDensity: VisualDensity.compact,
              onPressed: vm.clear,
              icon: Icon(
                Icons.clear_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

class _RemainingChip extends StatelessWidget {
  final int seconds;
  final bool counting;
  final bool trial;

  const _RemainingChip({
    required this.seconds,
    required this.counting,
    required this.trial,
  });

  @override
  Widget build(BuildContext context) {
    final time = counting
        ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} left'
        : seconds >= 60
        ? '${seconds ~/ 60} min left'
        : '$seconds s left';
    final text = trial ? 'Trial · $time' : time;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final LiveTranslateViewModel vm;

  /// Set during the free trial.
  final int? trialMinutes;

  const _EmptyState({required this.vm, required this.trialMinutes});

  @override
  Widget build(BuildContext context) {
    final active = vm.isActive;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(
                active
                    ? Icons.hearing_rounded
                    : Icons.record_voice_over_rounded,
                color: Colors.white.withValues(alpha: 0.85),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              active ? 'Start speaking' : 'Live Translation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              active
                  ? 'The translation appears here as the speaker talks.'
                  : 'Tap the mic and let someone speak. You hear the '
                        'translation as they talk, and it is written here too.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (trialMinutes != null && !active) ...[
              const SizedBox(height: 16),
              Text(
                'Your trial includes $trialMinutes minutes of Live. '
                'Premium includes 60 minutes every month.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryView extends StatelessWidget {
  final LiveEntry entry;
  final bool isLatest;

  const _EntryView({required this.entry, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.heard.isNotEmpty)
          Text(
            entry.heard.trim(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              height: 1.3,
            ),
          ),
        if (entry.heard.isNotEmpty && entry.translated.isNotEmpty)
          const SizedBox(height: 6),
        if (entry.translated.isNotEmpty)
          Text(
            entry.translated.trim(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: isLatest ? 1 : 0.72),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final AppException exception;

  const _ErrorBanner({required this.exception});

  String get _message {
    final e = exception;
    if (e is MicrophoneDeniedException) {
      return 'Microphone access is off. Allow it in Settings > Privacy > '
          'Microphone.';
    }
    if (e is QuotaExceededException && e.isTrial) {
      return "You've used your trial minutes. Premium includes 60 minutes of "
          'Live translation every month.';
    }
    if (e is QuotaExceededException) {
      final resets = e.resetsAt?.toLocal();
      return resets == null
          ? 'You have used this month\'s live translation time.'
          : 'You have used this month\'s live translation time. It resets on '
                '${resets.day}/${resets.month}.';
    }
    if (e is AiServiceException || e is NetworkException) {
      return aiErrorText(e).message;
    }
    return 'Live translation stopped. Tap the mic to try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningBars extends StatefulWidget {
  const _ListeningBars();

  @override
  State<_ListeningBars> createState() => _ListeningBarsState();
}

class _ListeningBarsState extends State<_ListeningBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 3,
              height:
                  6 +
                  10 *
                      (0.5 +
                          0.5 *
                              math.sin(
                                _controller.value * 2 * math.pi + i * 1.3,
                              )),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _showTrialUsedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: AlertDialog(
        backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: const Text(
          'Trial minutes used',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "You've used your free trial minutes of Live translation. Premium "
          'includes 60 minutes every month once your subscription starts.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
