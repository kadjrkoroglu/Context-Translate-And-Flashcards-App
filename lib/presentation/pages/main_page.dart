import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:translate_app/presentation/pages/ml_translate_page.dart';
import 'package:translate_app/presentation/pages/gemini_translate_page.dart';
import 'package:translate_app/presentation/pages/history_page.dart';
import 'package:translate_app/presentation/pages/favorites_page.dart';
import 'package:translate_app/presentation/pages/profile_page.dart';
import 'package:translate_app/presentation/pages/decks_page.dart';
import 'package:translate_app/presentation/widgets/output_screen.dart';
import 'package:translate_app/presentation/widgets/app_background.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/ml_translate_viewmodel.dart';
import 'package:translate_app/presentation/viewmodels/gemini_translate_viewmodel.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);
    final mlViewModel = Provider.of<MLTranslateViewModel>(context);
    final geminiViewModel = Provider.of<GeminiTranslateViewModel>(context);

    const Color inversePrimary = Colors.white; // Modern white for dark mode

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for gradient
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 10),
                child: Center(
                  child: Text(
                    'Context Translate',
                    style: GoogleFonts.caveat(
                      color: inversePrimary,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildPageSelector(context, viewModel, inversePrimary),
              const SizedBox(height: 20),
              SizedBox(
                height: 295,
                child: PageView(
                  controller: viewModel.pageController,
                  onPageChanged: (index) => viewModel.clearOutput(),
                  children: [
                    MLTranslatePage(
                      outputController: viewModel.outputController,
                    ),
                    GeminiTranslatePage(
                      outputController: viewModel.outputController,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: OutputScreen(controller: viewModel.outputController),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildGlassMicrophoneButton(
        viewModel,
        mlViewModel,
        geminiViewModel,
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
      width: 140,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: viewModel.pageController,
            builder: (context, child) {
              double offset = 0;
              if (viewModel.pageController.hasClients) {
                offset = viewModel.pageController.page ?? 0;
              }
              return Align(
                alignment: Alignment(offset * 2 - 1, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
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
              _buildToggleButton(context, viewModel, 'Basic', 0),
              _buildToggleButton(context, viewModel, 'AI', 1),
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
            double page = 0;
            if (viewModel.pageController.hasClients)
              page = viewModel.pageController.page ?? 0;
            double selectionFactor = (index == 0) ? (1 - page) : page;
            selectionFactor = selectionFactor.clamp(0, 1);
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
    MainViewModel viewModel,
    MLTranslateViewModel mlVM,
    GeminiTranslateViewModel gVM,
    Color inversePrimary,
  ) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF89979D), Color.fromARGB(255, 94, 106, 121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final isMLPage = (viewModel.pageController.page ?? 0) < 0.5;
            if (isMLPage) {
              mlVM.isListening
                  ? mlVM.stopListening()
                  : mlVM.startListening(viewModel.outputController);
            } else {
              gVM.isListening
                  ? gVM.stopListening()
                  : gVM.startListening(
                      (_) => gVM.translate(viewModel.outputController),
                    );
            }
          },
          customBorder: const CircleBorder(),
          child: Icon(
            Icons.mic_rounded,
            color: mlVM.isListening || gVM.isListening
                ? Colors.redAccent
                : Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, Color ip) {
    return BottomAppBar(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 85,
      color: Colors.white.withValues(alpha: 0.1), // Hafif saydam beyaz
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      notchMargin: 12,
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
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, Widget page) {
    return IconButton(
      icon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 28),
      onPressed: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }
}
