import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/core/languages.dart';
import 'package:translate_app/l10n/l10n.dart';

void main() {
  AppLocalizations stringsFor(Locale device) =>
      lookupAppLocalizations(appLocale(device));

  test('a Turkish phone gets Turkish', () {
    final t = stringsFor(const Locale('tr', 'TR'));
    expect(t.signIn, 'Giriş Yap');
    expect(t.cardCount(3), '3 kart');
    expect(languageLabel('German', t), 'Almanca');
    expect(languageLabel(autoDetect, t), 'Otomatik algıla');
  });

  test('every other language gets English', () {
    for (final device in const [
      Locale('de'),
      Locale('en', 'US'),
      Locale('ar'),
    ]) {
      final t = stringsFor(device);
      expect(t.signIn, 'Sign In');
      expect(languageLabel('German', t), 'German');
    }
    final t = stringsFor(const Locale('fr'));
    expect(t.cardCount(1), '1 card');
    expect(t.cardCount(3), '3 cards');
  });

  test('unknown language values are shown as they are', () {
    expect(languageLabel('Klingon', stringsFor(const Locale('tr'))), 'Klingon');
  });
}
