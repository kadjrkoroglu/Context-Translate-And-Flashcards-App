import 'package:flutter_test/flutter_test.dart';
import 'package:translate_app/core/text_case.dart';

void main() {
  test('the first letter goes up, the rest stays as typed', () {
    expect(capitalizeFirst('car'), 'Car');
    expect(capitalizeFirst('how are you?'), 'How are you?');
    expect(capitalizeFirst('iPhone case'), 'IPhone case');
    expect(capitalizeFirst('  wie  '), 'Wie');
    expect(capitalizeFirst('Danke'), 'Danke');
    expect(capitalizeFirst(''), '');
  });

  test('Turkish gets a dotted capital I', () {
    expect(capitalizeFirst('iyi', language: 'Turkish'), 'İyi');
    expect(capitalizeFirst('ılık', language: 'Turkish'), 'Ilık');
    expect(capitalizeFirst('idea', language: 'English'), 'Idea');
    // No language given: letters only Turkish has decide.
    expect(capitalizeFirst('işte'), 'İşte');
    expect(capitalizeFirst('ich'), 'Ich');
  });

  test('scripts without capitals are left alone', () {
    expect(capitalizeFirst('猫'), '猫');
    expect(capitalizeFirst('مرحبا'), 'مرحبا');
  });
}
