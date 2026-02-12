import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/presentation/viewmodels/main_viewmodel.dart';

class OutputScreen extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const OutputScreen({
    super.key,
    required this.controller,
    this.hintText = 'Translation will appear here',
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainViewModel>(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
    );

    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: viewModel.pageController,
        builder: (context, child) {
          double page = 0;
          if (viewModel.pageController.hasClients) {
            page = viewModel.pageController.page ?? 0;
          }
          final fontSize = 26 - (page * 8);

          return TextField(
            controller: controller,
            readOnly: true,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              fontSize: fontSize,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
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
          );
        },
      ),
    );
  }
}
