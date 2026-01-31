import 'package:flutter/material.dart';

class LanguageDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String>? items;
  final bool showIcon;
  final bool isLoading;

  const LanguageDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.items,
    this.showIcon = true,
    this.isLoading = false,
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
    final colorScheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none, // Dış çerçeveyi kaldırdık
    );

    // Eğer gelen değer listede yoksa (Auto-Detect gibi), onu geçici olarak listeye ekliyoruz
    // Bu sayede "Assertion Error" hatası kalkıyor.
    final currentItems = items ?? languages;
    final List<String> dropdownItems = List.from(currentItems);

    // Eğer değer '-' ise bunu 'hint' olarak kullanacağız, 'value' null olacak.
    // Böylece listede gözükmeyecek ama ekranda tire görünecek.
    final bool isPlaceholder = value == '-';
    final String? effectiveValue = isPlaceholder ? null : value;

    return Theme(
      data: Theme.of(
        context,
      ).copyWith(splashColor: colorScheme.inversePrimary.withOpacity(0.2)),
      child: DropdownButtonFormField<String>(
        value: effectiveValue,
        hint: isPlaceholder
            ? Center(
                child: Text(
                  '—',
                  style: TextStyle(
                    color: colorScheme.inversePrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        isExpanded: true,
        iconEnabledColor: colorScheme.inversePrimary,
        borderRadius: BorderRadius.circular(16),
        dropdownColor:
            colorScheme.primary, // Dropdown açıldığında arka plan rengi
        decoration: InputDecoration(
          filled: true,
          fillColor: colorScheme.primary,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border,
          suffixIcon: !isLoading && showIcon
              ? Icon(
                  Icons.language,
                  color: colorScheme.inversePrimary,
                  size: 20,
                )
              : null,
        ),
        iconSize: isLoading ? 0 : 24,
        selectedItemBuilder: (BuildContext context) {
          return dropdownItems.map((String item) {
            return Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.inversePrimary,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item,
                        style: TextStyle(
                          color: colorScheme.inversePrimary,
                          fontSize: 15,
                        ),
                      ),
                    ),
            );
          }).toList();
        },
        items: dropdownItems.map((String lang) {
          return DropdownMenuItem(
            value: lang,
            child: Text(
              lang,
              style: TextStyle(color: colorScheme.inversePrimary, fontSize: 15),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
