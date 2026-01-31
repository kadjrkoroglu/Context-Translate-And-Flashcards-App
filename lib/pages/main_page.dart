import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:translate_app/pages/ml_translate_page.dart';
import 'package:translate_app/pages/translate_page.dart';
import 'package:translate_app/components/output_screen.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final PageController _pageController = PageController();
  final TextEditingController _outputController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      animation: _pageController,
                      builder: (context, child) {
                        double offset = 0;
                        if (_pageController.hasClients) {
                          offset = _pageController.page ?? 0;
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
                        _buildToggleButton('Basic', 0),
                        _buildToggleButton('AI', 1),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 290,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _outputController.clear();
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: MLTranslatePage(outputController: _outputController),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TranslatePage(outputController: _outputController),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: OutputScreen(controller: _outputController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        },
        behavior: HitTestBehavior.translucent,
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = 0;
            if (_pageController.hasClients) page = _pageController.page ?? 0;
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
