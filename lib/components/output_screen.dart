import 'package:flutter/material.dart';

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
    // Border stilini bir kere tanımlıyoruz
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
    );

    return SizedBox(
      height: 200,
      child: TextField(
        controller: controller,
        readOnly: true,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(
          fontSize: 26,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.primary,
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
