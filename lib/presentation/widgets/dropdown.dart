import 'package:flutter/material.dart';
import 'dart:ui';

class LanguageDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String>? items;
  final List<String> recentLanguages;
  final Set<String> downloadedModels;
  final bool showIcons;
  final bool isLoading;
  final bool showHeader;
  final String? labelText;

  const LanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.items,
    this.recentLanguages = const [],
    this.downloadedModels = const {},
    this.showIcons = true,
    this.isLoading = false,
    this.showHeader = true,
    this.labelText,
  });

  static const List<String> languages = [
    'English',
    'German',
    'French',
    'Spanish',
    'Italian',
    'Russian',
    'Japanese',
    'Chinese',
    'Korean',
    'Arabic',
    'Portuguese',
    'Hindi',
    'Urdu',
    'Persian',
    'Dutch',
    'Swedish',
    'Norwegian',
    'Danish',
    'Finnish',
    'Polish',
    'Greek',
    'Hebrew',
    'Turkish',
  ];

  @override
  Widget build(BuildContext context) {
    const Color color = Colors.white;

    final List<dynamic> dropdownData = [];
    final List<String> allLangs = items ?? languages;

    if (showHeader) {
      dropdownData.add('SELECT_HEADER');
    }
    if (recentLanguages.isNotEmpty && items == null) {
      dropdownData.add('RECENTS');
      dropdownData.addAll(recentLanguages);
      dropdownData.add('DIVIDER');
      dropdownData.add('ALL LANGUAGES');
      dropdownData.addAll(
        allLangs.where((lang) => !recentLanguages.contains(lang)),
      );
    } else {
      dropdownData.addAll(allLangs);
    }

    final bool isPlaceholder = value == '-';
    final String? effectiveValue = isPlaceholder ? null : value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: color.withValues(alpha: 0.2),
              canvasColor: const Color(
                0xFF2D3238,
              ).withValues(alpha: 0.6), // Glassy menu background
            ),
            child: DropdownButtonFormField<String>(
              initialValue: effectiveValue,
              hint: isPlaceholder
                  ? Center(
                      child: Text(
                        labelText ?? 'Select',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              isExpanded: true,
              iconEnabledColor: Colors.white70,
              icon: const Icon(Icons.expand_more_rounded),
              borderRadius: BorderRadius.circular(16),
              dropdownColor: const Color(0xFF2D3238).withValues(alpha: 0.7),
              decoration: InputDecoration(
                labelText: labelText,
                labelStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.never,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
              selectedItemBuilder: (context) {
                return dropdownData.map((data) {
                  final String text = data is String ? data : '';
                  return Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        : Text(
                            text,
                            style: const TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                }).toList();
              },
              items: dropdownData.map((data) {
                if (data == 'DIVIDER') {
                  return const DropdownMenuItem<String>(
                    enabled: false,
                    child: Divider(color: Colors.white12),
                  );
                }
                if (data == 'RECENTS' ||
                    data == 'ALL LANGUAGES' ||
                    data == 'SELECT_HEADER') {
                  final String displayText = data == 'SELECT_HEADER'
                      ? 'SELECT TARGET LANGUAGE'
                      : data;
                  return DropdownMenuItem<String>(
                    enabled: false,
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                final String lang = data as String;
                final bool isDownloaded = downloadedModels.contains(lang);
                return DropdownMenuItem<String>(
                  value: lang,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lang,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (showIcons)
                        Icon(
                          isDownloaded
                              ? Icons.check_circle_outline_rounded
                              : Icons.file_download_outlined,
                          color: Colors.white38,
                          size: 20,
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
