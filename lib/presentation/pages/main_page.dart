import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/pages/ml_translate_page.dart';
import 'package:translate_app/presentation/pages/gemini_translate_page.dart';
import 'package:translate_app/presentation/pages/history_page.dart';
import 'package:translate_app/presentation/pages/favorites_page.dart';
import 'package:translate_app/presentation/pages/profile_page.dart';
import 'package:translate_app/presentation/pages/decks_page.dart';
import 'package:translate_app/presentation/widgets/output_screen.dart';
import 'package:translate_app/presentation/widgets/speech_toggle_button.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/entitlements_viewmodel.dart';
import 'package:translate_app/presentation/pages/photo_translate_page.dart';
import 'package:translate_app/presentation/pages/upgrade_page.dart';
import 'package:translate_app/presentation/viewmodels/live_translate_viewmodel.dart';
import 'package:translate_app/presentation/widgets/live_translate_body.dart';
import 'package:translate_app/presentation/widgets/upgrade_required_dialog.dart';
import 'package:translate_app/theme/theme.dart';
import 'dart:ui';
import 'dart:math' as math;

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);
    final mlViewModel = Provider.of<MLTranslateViewModel>(context);
    final geminiViewModel = Provider.of<GeminiTranslateViewModel>(context);
    final liveViewModel = Provider.of<LiveTranslateViewModel>(context);
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    const Color inversePrimary = Colors.white;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final double bottomAreaHeight = 45 + 38;
    final double fixedGap = 15;
    final double totalBottomPadding =
        bottomAreaHeight + fixedGap + safeAreaBottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0, bottom: 0),
                  child: Center(
                    child: Text(
                      'Context Translate & Flashcards',
                      style: GoogleFonts.caveat(
                        color: inversePrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                _buildPageSelector(context, viewModel, inversePrimary),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: math.max(totalBottomPadding, keyboardHeight + 8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.alphaBlend(
                              glassTheme?.baseGlassColor ??
                                  Colors.white.withValues(alpha: 0.12),
                              glassTheme?.backgroundGradient.first ??
                                  (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF2D3436)
                                      : const Color(0xFF7A8386)),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 72,
                                child: PageView(
                                  controller: viewModel.pageController,
                                  onPageChanged: (index) {
                                    // Keep restored text when history/favorites switch pages.
                                    if (!viewModel.isRestoring) {
                                      geminiViewModel.clear(
                                        viewModel.outputController,
                                      );
                                      mlViewModel.clear(
                                        viewModel.outputController,
                                      );
                                    }
                                    if (index == MainViewModel.livePage) {
                                      _ensureLiveAccess(context, viewModel);
                                    } else {
                                      liveViewModel.stop();
                                    }
                                  },
                                  children: [
                                    const LiveLanguageHeader(),
                                    GeminiLanguageHeader(
                                      outputController:
                                          viewModel.outputController,
                                    ),
                                    MLLanguageHeader(
                                      outputController:
                                          viewModel.outputController,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: AnimatedBuilder(
                                  animation: viewModel.pageController,
                                  builder: (context, _) => viewModel.isLivePage
                                      ? const LiveTranslateBody()
                                      : LayoutBuilder(
                                          builder: (context, constraints) {
                                            return SingleChildScrollView(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  minHeight:
                                                      constraints.maxHeight,
                                                ),
                                                child: IntrinsicHeight(
                                                  child: ValueListenableBuilder<TextEditingValue>(
                                                    valueListenable: viewModel
                                                        .outputController,
                                                    builder: (context, outputValue, _) {
                                                      final bool hasOutput =
                                                          outputValue
                                                              .text
                                                              .isNotEmpty;

                                                      return Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          AnimatedBuilder(
                                                            animation: viewModel
                                                                .pageController,
                                                            builder: (context, _) {
                                                              final isML =
                                                                  viewModel
                                                                      .isMLPage;
                                                              return isML
                                                                  ? MLInputBody(
                                                                      outputController:
                                                                          viewModel
                                                                              .outputController,
                                                                    )
                                                                  : GeminiInputBody(
                                                                      outputController:
                                                                          viewModel
                                                                              .outputController,
                                                                    );
                                                            },
                                                          ),

                                                          if (!hasOutput)
                                                            const Spacer(),
                                                          if (hasOutput)
                                                            const Spacer(),
                                                          if (hasOutput &&
                                                              !(viewModel
                                                                      .isMLPage
                                                                  ? mlViewModel
                                                                        .isLoading
                                                                  : geminiViewModel
                                                                        .isLoading))
                                                            Align(
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: Transform.translate(
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      10,
                                                                    ),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        right:
                                                                            8,
                                                                      ),
                                                                  child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      SpeechToggleButton(
                                                                        text:
                                                                            viewModel.isMLPage
                                                                            ? mlViewModel.textController.text
                                                                            : geminiViewModel.textController.text,
                                                                        language:
                                                                            viewModel.isMLPage
                                                                            ? mlViewModel.sourceLanguage
                                                                            : geminiViewModel.sourceLanguage,
                                                                      ),
                                                                      IconButton(
                                                                        icon: Icon(
                                                                          Icons
                                                                              .clear_rounded,
                                                                          color: Colors.white.withValues(
                                                                            alpha:
                                                                                0.5,
                                                                          ),
                                                                        ),
                                                                        onPressed: () {
                                                                          if (viewModel
                                                                              .isMLPage) {
                                                                            mlViewModel.clear(
                                                                              viewModel.outputController,
                                                                            );
                                                                          } else {
                                                                            geminiViewModel.clear(
                                                                              viewModel.outputController,
                                                                            );
                                                                          }
                                                                        },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),

                                                          if (hasOutput)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical: 8,
                                                                  ),
                                                              child: Divider(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.15,
                                                                    ),
                                                                thickness: 0.5,
                                                              ),
                                                            ),

                                                          if (hasOutput)
                                                            OutputTranslationField(
                                                              controller: viewModel
                                                                  .outputController,
                                                            ),

                                                          if (hasOutput)
                                                            const Spacer(),
                                                          if (hasOutput)
                                                            OutputActionButtons(
                                                              controller: viewModel
                                                                  .outputController,
                                                            ),

                                                          if (!hasOutput)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 6,
                                                                    bottom: 15,
                                                                  ),
                                                              child: _buildTranslateButton(
                                                                viewModel,
                                                                geminiViewModel,
                                                              ),
                                                            ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
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
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildGlassMicrophoneButton(
        context,
        viewModel,
        mlViewModel,
        geminiViewModel,
        liveViewModel,
        inversePrimary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(context, inversePrimary),
    );
  }

  Widget _buildPageSelector(
    BuildContext context,
    MainViewModel viewModel,
    Color inversePrimary,
  ) {
    return Container(
      height: 36,
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: viewModel.pageController,
            builder: (context, child) {
              return Align(
                alignment: Alignment(viewModel.page - 1, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              _buildToggleButton(context, viewModel, 'Live', 0),
              _buildToggleButton(context, viewModel, 'AI', 1),
              _buildToggleButton(context, viewModel, 'Basic', 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    MainViewModel viewModel,
    String label,
    int index,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.animateToPage(index),
        behavior: HitTestBehavior.translucent,
        child: AnimatedBuilder(
          animation: viewModel.pageController,
          builder: (context, child) {
            final selectionFactor = (1 - (viewModel.page - index).abs()).clamp(
              0.0,
              1.0,
            );
            return Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color.lerp(
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white,
                    selectionFactor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassMicrophoneButton(
    BuildContext context,
    MainViewModel viewModel,
    MLTranslateViewModel mlVM,
    GeminiTranslateViewModel gVM,
    LiveTranslateViewModel liveVM,
    Color inversePrimary,
  ) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors:
              glassTheme?.micGradient ??
              [
                const Color(0xFF89979D),
                const Color.fromARGB(255, 94, 106, 121),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (viewModel.isLivePage) {
              liveVM.isActive ? liveVM.stop() : liveVM.start();
              return;
            }
            if (viewModel.isMLPage) {
              mlVM.isListening
                  ? mlVM.stopListening()
                  : mlVM.startListening(viewModel.outputController);
            } else {
              gVM.isListening ? gVM.stopListening() : gVM.startListening();
            }
          },
          customBorder: const CircleBorder(),
          child: Icon(
            liveVM.isActive ? Icons.stop_rounded : Icons.mic_rounded,
            color: mlVM.isListening || gVM.isListening || liveVM.isActive
                ? Colors.redAccent
                : Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, Color ip) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 45,
      color: glassTheme?.baseGlassColor ?? Colors.white.withValues(alpha: 0.1),
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      notchMargin: 12,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(context, Icons.history_rounded, const HistoryPage()),
            _navIcon(context, Icons.favorite_rounded, const FavoritesPage()),
            const SizedBox(width: 50),
            _navIcon(context, Icons.quiz_rounded, const DecksPage()),
            _navIcon(context, Icons.person_rounded, const ProfilePage()),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, Widget page) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 28),
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }

  Widget _buildTranslateButton(
    MainViewModel viewModel,
    GeminiTranslateViewModel gVM,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([viewModel.pageController, gVM]),
      builder: (context, _) {
        final isMLPage = viewModel.isMLPage;

        return AnimatedOpacity(
          opacity: isMLPage ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: isMLPage || gVM.isLoading,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hidden as soon as Translate is pressed.
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: gVM.isLoading
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _buildCameraButton(context, gVM),
                        ),
                ),
                _buildTranslateButtonBody(viewModel, gVM),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraButton(
    BuildContext context,
    GeminiTranslateViewModel gVM,
  ) {
    return SizedBox(
      width: 42,
      height: 42,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            onPressed: () => _openPhotoTranslate(context, gVM),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: const Icon(Icons.photo_camera_rounded, size: 20),
          ),
        ),
      ),
    );
  }

  // Premium only: others get the plans screen. Unknown (offline) passes;
  // the backend enforces the plan.
  Future<void> _ensureLiveAccess(
    BuildContext context,
    MainViewModel mainVM,
  ) async {
    final entitlementsVM = context.read<EntitlementsViewModel>();
    if (entitlementsVM.entitlements?.entitlements.live != true) {
      await entitlementsVM.load();
    }
    if (!context.mounted) return;
    final entitlements = entitlementsVM.entitlements;
    if (entitlements != null && !entitlements.entitlements.live) {
      mainVM.animateToPage(MainViewModel.aiPage);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradePage()),
      );
    }
  }

  // A cached "not allowed" is re-checked so an upgrade shows up at once.
  Future<void> _openPhotoTranslate(
    BuildContext context,
    GeminiTranslateViewModel gVM,
  ) async {
    final entitlementsVM = context.read<EntitlementsViewModel>();
    if (entitlementsVM.entitlements?.entitlements.photo != true) {
      await entitlementsVM.load();
    }
    if (!context.mounted) return;

    final entitlements = entitlementsVM.entitlements;
    // Unknown (e.g. offline) is let through; the backend enforces the tier.
    if (entitlements != null && !entitlements.entitlements.photo) {
      showUpgradeRequiredDialog(
        context,
        title: 'Photo Translation',
        message:
            'Translating text in photos is available on the Standard and '
            'Premium plans.',
      );
      return;
    }
    if (gVM.targetLanguage == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a target language first.')),
      );
      return;
    }
    await PhotoTranslatePage.open(context);
  }

  Widget _buildTranslateButtonBody(
    MainViewModel viewModel,
    GeminiTranslateViewModel gVM,
  ) {
    return SizedBox(
      height: 42,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            onPressed: () => gVM.translate(viewModel.outputController),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: gVM.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Translate',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
