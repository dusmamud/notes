import 'package:flutter_test/flutter_test.dart';
import 'package:note/core/services/math_notes_engine.dart';

void main() {
  test('MathNotesEngine arithmetic evaluation test', () {
    final engine = MathNotesEngine(mode: MathResultsMode.suggest);
    final result = engine.evaluateLine('125 * 4 =');
    expect(result, '500');
  });

  test('MathNotesEngine percentage calculation test', () {
    final engine = MathNotesEngine(mode: MathResultsMode.suggest);
    final result = engine.evaluateLine('500 - 10% =');
    expect(result, '450');
  });

  test('MathNotesEngine square root test', () {
    final engine = MathNotesEngine(mode: MathResultsMode.suggest);
    final result = engine.evaluateLine('sqrt(144) =');
    expect(result, '12');
  });
}
