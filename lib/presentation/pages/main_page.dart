import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/pages/ml_translate_page.dart';
import 'package:translate_app/presentation/pages/translate_page.dart';
import 'package:translate_app/presentation/pages/history_page.dart';
import 'package:translate_app/presentation/pages/favorites_page.dart';
import 'package:translate_app/presentation/pages/profile_page.dart';
import 'package:translate_app/presentation/pages/cards_page.dart';
import 'package:translate_app/presentation/widgets/output_screen.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        centerTitle: true,
        toolbarHeight: 100,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Text(
            'Context Translate',
            style: GoogleFonts.caveat(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Center(
              child: Container(
                height: 30,
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.inversePrimary,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 290,
              child: PageView(
                controller: viewModel.pageController,
                onPageChanged: (index) {
                  viewModel.clearOutput();
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: MLTranslatePage(
                      outputController: viewModel.outputController,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TranslatePage(
                      outputController: viewModel.outputController,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120.0),
                child: AnimatedBuilder(
                  animation: viewModel.pageController,
                  builder: (context, child) {
                    double page = 0;
                    if (viewModel.pageController.hasClients) {
                      page = viewModel.pageController.page ?? 0;
                    }

                    double dynamicFontSize = 26 - (page * 8);

                    return OutputScreen(
                      controller: viewModel.outputController,
                      fontSize: dynamicFontSize,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: () {
            final isMLPage = (viewModel.pageController.page ?? 0) < 0.5;
            if (isMLPage) {
              if (mlViewModel.isListening) {
                mlViewModel.stopListening();
              } else {
                mlViewModel.startListening(viewModel.outputController);
              }
            } else {
              if (geminiViewModel.isListening) {
                geminiViewModel.stopListening();
              } else {
                geminiViewModel.startListening(
                  (_) => geminiViewModel.translate(viewModel.outputController),
                );
              }
            }
          },
          elevation: 2,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          shape: const CircleBorder(),
          child: Icon(
            Icons.mic,
            color: Theme.of(context).colorScheme.surface,
            size: 40,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 50,
        color: Theme.of(context).colorScheme.primary,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 48), // Space for the FAB
            IconButton(
              icon: Icon(
                Icons.quiz_outlined,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CardsPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.person_outline,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
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
        onTap: () {
          viewModel.animateToPage(index);
        },
        behavior: HitTestBehavior.translucent,
        child: AnimatedBuilder(
          animation: viewModel.pageController,
          builder: (context, child) {
            double page = 0;
            if (viewModel.pageController.hasClients) {
              page = viewModel.pageController.page ?? 0;
            }
            double selectionFactor = (index == 0) ? (1 - page) : page;
            selectionFactor = selectionFactor.clamp(0, 1);
            return Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color.lerp(
                    Theme.of(context).colorScheme.onSurface,
                    Theme.of(context).colorScheme.onPrimary,
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
}
