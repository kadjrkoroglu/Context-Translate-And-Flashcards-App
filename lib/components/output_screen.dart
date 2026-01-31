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
    return SizedBox(
      height: 200,
      child: TextField(
        controller: controller,
        readOnly: true,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.primary,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          hintText: hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
