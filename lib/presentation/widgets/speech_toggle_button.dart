import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translate_app/data/services/tts_service.dart';

class SpeechToggleButton extends StatefulWidget {
  const SpeechToggleButton({
    super.key,
    required this.text,
    required this.language,
  });

  final String text;
  final String language;

  @override
  State<SpeechToggleButton> createState() => _SpeechToggleButtonState();
}

class _SpeechToggleButtonState extends State<SpeechToggleButton> {
  bool _speaking = false;

  void _finish() {
    if (mounted && _speaking) setState(() => _speaking = false);
  }

  Future<void> _toggle(TtsService tts) async {
    if (_speaking) {
      setState(() => _speaking = false);
      await tts.stop();
      return;
    }

    if (widget.text.trim().isEmpty) return;

    setState(() => _speaking = true);
    try {
      await tts.speak(widget.text.trim(), widget.language, onDone: _finish);
    } catch (_) {
      try {
        await tts.speak(widget.text.trim(), 'English', onDone: _finish);
      } catch (_) {
        _finish();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tts = context.read<TtsService>();
    return IconButton(
      icon: Icon(
        _speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
        color: Colors.white.withValues(alpha: _speaking ? 0.9 : 0.5),
      ),
      onPressed: () => _toggle(tts),
    );
  }
}
