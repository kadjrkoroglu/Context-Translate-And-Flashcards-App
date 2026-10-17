import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/presentation/pages/profile_page.dart';

void main() {
  test('first and last name give two letters', () {
    expect(profileInitials('Kadir Köroğlu', 'a@b.c'), 'KK');
    expect(profileInitials('  ada   lovelace byron ', null), 'AB');
  });

  test('a single name gives one letter', () {
    expect(profileInitials('Kadir', null), 'K');
  });

  test('no name falls back to the email, then to nothing', () {
    expect(profileInitials(null, 'zeynep@example.com'), 'Z');
    expect(profileInitials('   ', ''), '');
    expect(profileInitials(null, null), '');
  });
}
