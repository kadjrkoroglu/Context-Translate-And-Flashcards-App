import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class LanguageDropdown extends StatefulWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String>? items;
  final List<String> recentLanguages;
  final Set<String> downloadedModels;
  final bool showIcons;
  final bool isLoading;
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
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  OverlayEntry? _menuEntry;

  @override
  void dispose() {
    _menuEntry?.remove();
    super.dispose();
  }

  List<dynamic> get _dropdownData {
    final List<dynamic> data = [];
    final List<String> allLangs = widget.items ?? LanguageDropdown.languages;

    if (widget.recentLanguages.isNotEmpty && widget.items == null) {
      data.add('RECENTS');
      data.addAll(widget.recentLanguages);
      data.add('DIVIDER');
      data.add('ALL LANGUAGES');
      data.addAll(
        allLangs.where((lang) => !widget.recentLanguages.contains(lang)),
      );
    } else {
      data.addAll(allLangs);
    }
    return data;
  }

  double _estimateHeight() {
    double height = 16;
    for (final d in _dropdownData) {
      if (d == 'DIVIDER') {
        height += 17;
      } else if (d is String && (d == 'RECENTS' || d == 'ALL LANGUAGES')) {
        height += 24;
      } else if (d is String) {
        height += 42;
      }
    }
    return height;
  }

  void _openMenu() {
    if (_dropdownData.isEmpty) return;

    final overlay = Overlay.of(context);
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero);
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    // Same 4px gap above the menu and below it (menu never enters keyboard).
    const double gap = 4;
    final double keyboardTop = screenSize.height - media.viewInsets.bottom;

    final double belowAvail =
        keyboardTop - anchor.dy - box.size.height - 2 * gap;
    final double aboveAvail = anchor.dy - gap;
    final bool openDown = belowAvail >= aboveAvail;
    final double maxMenuHeight = math.min(
      openDown ? belowAvail : aboveAvail,
      480,
    );

    _closeMenu();
    _menuEntry = OverlayEntry(
      builder: (ctx) {
        final double menuHeight = math.min(_estimateHeight(), maxMenuHeight);
        final double top = openDown
            ? anchor.dy + box.size.height + gap
            : anchor.dy - menuHeight - gap;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenu,
              ),
            ),
            Positioned(
              left: anchor.dx,
              top: top,
              width: box.size.width,
              child: _buildMenuCard(menuHeight),
            ),
          ],
        );
      },
    );
    overlay.insert(_menuEntry!);
  }

  void _closeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  // Frosted menu: blurs only its own area, like the deck long-press dialog.
  Widget _buildMenuCard(double menuHeight) {
    final BorderRadius radius = BorderRadius.circular(28);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Glass blur layer; border paints on top for a clean corner seam.
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3238).withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: menuHeight),
                child: ClipRRect(
                  borderRadius: radius,
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (final d in _dropdownData) _buildMenuItem(d),
                    ],
                  ),
                ),
              ),
              // Border on top: crisp corner curve under one clip.
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(dynamic data) {
    if (data == 'DIVIDER') {
      return const Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.white12,
        indent: 12,
        endIndent: 12,
      );
    }
    if (data is String && (data == 'RECENTS' || data == 'ALL LANGUAGES')) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
        child: Text(
          data,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final String lang = data as String;
    final bool isSelected = widget.value == lang;
    final bool isDownloaded = widget.downloadedModels.contains(lang);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onChanged(lang);
        _closeMenu();
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: isSelected ? Colors.white.withValues(alpha: 0.08) : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                lang,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                ),
              ),
            ),
            if (widget.showIcons)
              Icon(
                isDownloaded
                    ? Icons.check_circle_outline_rounded
                    : Icons.file_download_outlined,
                color: Colors.white38,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color color = Colors.white;
    final bool isPlaceholder = widget.value == '-';

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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openMenu,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: widget.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: color,
                                  ),
                                )
                              : Text(
                                  isPlaceholder
                                      ? (widget.labelText ?? 'Select')
                                      : widget.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isPlaceholder
                                        ? Colors.white54
                                        : color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
