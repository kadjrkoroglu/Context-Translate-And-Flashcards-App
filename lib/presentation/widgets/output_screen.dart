import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';

class OutputScreen extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const OutputScreen({
    super.key,
    required this.controller,
    this.hintText = 'Translation',
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);
    final color = Theme.of(context).colorScheme.inversePrimary;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
    );

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([viewModel.pageController, controller]),
        builder: (context, _) {
          final page = viewModel.pageController.hasClients
              ? (viewModel.pageController.page ?? 0)
              : 0.0;

          return Stack(
            children: [
              TextField(
                controller: controller,
                readOnly: true,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontSize: 26 - (page * 8), color: color),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.primary,
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              if (controller.text.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.library_add_outlined,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.favorite_border,
                          color: color.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
