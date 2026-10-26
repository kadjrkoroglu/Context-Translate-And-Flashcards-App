import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:translate_app/core/errors/app_exception.dart';
import 'package:translate_app/domain/entities/example_sentence.dart';
import 'package:translate_app/presentation/utils/ai_error_text.dart';
import 'package:translate_app/l10n/l10n.dart';

/// Which side of the examples to show: a card's front shows the sentences,
/// its back their translations.
enum ExampleSide { both, sentences, translations }

class ExampleSentencesSheet extends StatefulWidget {
  final String title;
  final ExampleSide side;
  final Future<List<ExampleSentence>> Function() load;

  const ExampleSentencesSheet({
    super.key,
    required this.title,
    required this.side,
    required this.load,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Future<List<ExampleSentence>> Function() load,
    ExampleSide side = ExampleSide.both,
  }) {
    return showModalBottomSheet(
      context: context,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          ExampleSentencesSheet(title: title, side: side, load: load),
    );
  }

  @override
  State<ExampleSentencesSheet> createState() => _ExampleSentencesSheetState();
}

class _ExampleSentencesSheetState extends State<ExampleSentencesSheet> {
  late Future<List<ExampleSentence>> _examples = widget.load();

  static String _errorText(Object? error) {
    if (error is QuotaExceededException) {
      return error.isDailyLimit ? l10n.dailyLimitBody : l10n.slowDownBody;
    }
    return aiErrorText(error is AppException ? error : null).message;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D3238).withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(36),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.exampleSentences,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 17),
                Flexible(
                  child: FutureBuilder<List<ExampleSentence>>(
                    future: _examples,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        );
                      }
                      final examples = snapshot.data;
                      if (snapshot.hasError || examples == null) {
                        return _ErrorView(
                          message: _errorText(snapshot.error),
                          onRetry: () =>
                              setState(() => _examples = widget.load()),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.fromLTRB(
                          24,
                          8,
                          24,
                          24 + MediaQuery.paddingOf(context).bottom,
                        ),
                        itemCount: examples.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 18),
                        itemBuilder: (_, i) => _ExampleTile(
                          example: examples[i],
                          side: widget.side,
                        ),
                      );
                    },
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

class _ExampleTile extends StatelessWidget {
  final ExampleSentence example;
  final ExampleSide side;

  const _ExampleTile({required this.example, required this.side});

  // The [[marked]] word in blue.
  static TextSpan _marked(String text, TextStyle style) {
    final spans = <TextSpan>[];
    text.splitMapJoin(
      RegExp(r'\[\[(.+?)\]\]'),
      onMatch: (m) {
        spans.add(
          TextSpan(
            text: m[1],
            style: const TextStyle(
              color: Colors.lightBlueAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        return '';
      },
      onNonMatch: (plain) {
        spans.add(TextSpan(text: plain));
        return '';
      },
    );
    return TextSpan(style: style, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    const main = TextStyle(color: Colors.white, fontSize: 17, height: 1.35);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (side != ExampleSide.translations)
          Text.rich(_marked(example.sentence, main)),
        if (side == ExampleSide.both) const SizedBox(height: 4),
        if (side != ExampleSide.sentences)
          Text.rich(
            _marked(
              example.translation,
              side == ExampleSide.both
                  ? TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                      height: 1.35,
                    )
                  : main,
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              l10n.retry,
              style: const TextStyle(color: Colors.lightBlueAccent),
            ),
          ),
        ],
      ),
    );
  }
}
