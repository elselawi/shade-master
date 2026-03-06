import 'package:flutter_test/flutter_test.dart';
import 'package:shadesmaster/utils/int_to_letter.dart';

void main() {
  group('intToLetter', () {
    test('converts single digits correctly', () {
      expect(intToLetter(1), 'A');
      expect(intToLetter(2), 'B');
      expect(intToLetter(26), 'Z');
    });

    test('converts double digits correctly', () {
      expect(intToLetter(27), 'AA');
      expect(intToLetter(28), 'AB');
      expect(intToLetter(52), 'AZ');
      expect(intToLetter(53), 'BA');
      expect(intToLetter(702), 'ZZ');
    });

    test('converts triple digits correctly', () {
      expect(intToLetter(703), 'AAA');
      expect(intToLetter(704), 'AAB');
    });

    test('throws ArgumentError for numbers less than 1', () {
      expect(() => intToLetter(0), throwsArgumentError);
      expect(() => intToLetter(-1), throwsArgumentError);
    });

    test('handles large numbers', () {
      expect(intToLetter(18278), 'ZZZ');
      expect(intToLetter(18279), 'AAAA');
    });
  });
}
