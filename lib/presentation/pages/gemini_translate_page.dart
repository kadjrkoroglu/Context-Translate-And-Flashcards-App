import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:translate_app/core/languages.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/widgets/dropdown.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/utils/font_size_helper.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/presentation/utils/ai_error_text.dart';
import 'package:translate_app/presentation/widgets/upgrade_required_dialog.dart';
import 'package:translate_app/presentation/widgets/restart_required_dialog.dart';
import 'package:translate_app/l10n/l10n.dart';

class GeminiLanguageHeader extends StatelessWidget {
  final TextEditingController outputController;
  const GeminiLanguageHeader({super.key, required this.outputController});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GeminiTranslateViewModel>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
          child: _buildLanguageRow(context, viewModel),
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

  Widget _buildLanguageRow(
    BuildContext context,
    GeminiTranslateViewModel geminiVM,
  ) {
    return Stack(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: LanguageDropdown(
                  value: geminiVM.sourceLanguage,
                  recentLanguages: geminiVM.recentLanguages,
                  showIcons: false,
                  autoDetect: true,
                  onChanged: (v) =>
                      geminiVM.setSourceLanguage(v!, outputController),
                ),
              ),
              IconButton(
                onPressed: geminiVM.sourceLanguage == autoDetect
                    ? null
                    : () => geminiVM.swapLanguages(outputController),
                icon: const Icon(Icons.swap_horiz_rounded),
                color: Colors.white,
                disabledColor: Colors.white24,
              ),
              Expanded(
                child: LanguageDropdown(
                  value: geminiVM.targetLanguage,
                  recentLanguages: geminiVM.recentLanguages,
                  showIcons: false,
                  onChanged: (v) =>
                      geminiVM.setTargetLanguage(v!, outputController),
                ),
              ),
            ],
          ),
        ),
        if (geminiVM.isListening)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          l10n.listening,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class GeminiInputBody extends StatelessWidget {
  final TextEditingController outputController;
  const GeminiInputBody({super.key, required this.outputController});

  static bool _errorDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GeminiTranslateViewModel>(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: viewModel.textController,
          builder: (context, value, child) {
            final fontSize = FontSizeHelper.getDynamicFontSize(
              value.text.length,
            );
            final hasText = value.text.isNotEmpty;
            return Stack(
              children: [
                TextField(
                  controller: viewModel.textController,
                  focusNode: viewModel.inputFocus,
                  maxLines: null,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: l10n.enterText,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    // Room for the clear button, kept after translating so the text doesn't reflow.
                    contentPadding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      hasText ? 52 : 20,
                      8,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    if (val.isEmpty) outputController.clear();
                  },
                ),
                Positioned(
                  top: 11,
                  // In line with the X shown after translating.
                  right: 12,
                  // Only while typing; gone once Translate is pressed.
                  child: ListenableBuilder(
                    listenable: outputController,
                    builder: (context, _) {
                      final visible =
                          hasText &&
                          outputController.text.isEmpty &&
                          !viewModel.isLoading;
                      return AnimatedOpacity(
                        opacity: visible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !visible,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              viewModel.inputFocus.unfocus();
                              viewModel.clear(outputController);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),

        if (viewModel.error != null)
          Builder(
            builder: (_) {
              _showTranslationErrorDialog(context);
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  static void _showTranslationErrorDialog(BuildContext context) {
    if (_errorDialogOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || _errorDialogOpen) return;
      final exception = context.read<GeminiTranslateViewModel>().lastException;
      context.read<GeminiTranslateViewModel>().clearError();

      if (exception is QuotaExceededException) {
        if (exception.isDailyLimit) {
          _showDailyLimitDialog(context);
        } else {
          _showSlowDownDialog(context);
        }
        return;
      }
      // No Firebase session at all (e.g. right after sign-out).
      if (exception is AuthException) {
        _errorDialogOpen = true;
        showRestartRequiredDialog(
          context,
        ).whenComplete(() => _errorDialogOpen = false);
        return;
      }
      _showErrorDialog(context, exception);
    });
  }

  static void _showDailyLimitDialog(BuildContext context) {
    _errorDialogOpen = true;
    showUpgradeRequiredDialog(
      context,
      title: l10n.dailyLimitTitle,
      message: l10n.dailyLimitBody,
    ).whenComplete(() => _errorDialogOpen = false);
  }

  static void _showSlowDownDialog(BuildContext context) {
    _errorDialogOpen = true;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Text(
            l10n.slowDownTitle,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            l10n.slowDownBody,
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.ok, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _errorDialogOpen = false);
  }

  static void _showErrorDialog(BuildContext context, AppException? exception) {
    final text = aiErrorText(exception);
    _errorDialogOpen = true;
    HapticFeedback.warningNotification();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AlertDialog(
          backgroundColor: const Color(0xFF2D3238).withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Text(
            text.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                text.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _errorDialogOpen = false);
  }
}
