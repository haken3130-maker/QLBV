import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Salary Splitting Logic Tests', () {
    test('Perfect split division (no remainder)', () {
      const int totalAmount = 9000000;
      const int numParticipants = 5;

      final baseSplit = totalAmount ~/ numParticipants;
      final remainder = totalAmount % numParticipants;

      final List<int> splits = [];
      for (int i = 0; i < numParticipants; i++) {
        splits.add(baseSplit + (i < remainder ? 1 : 0));
      }

      expect(splits.length, numParticipants);
      for (var s in splits) {
        expect(s, 1800000);
      }

      final sum = splits.fold<int>(0, (a, b) => a + b);
      expect(sum, totalAmount);
    });

    test('Indivisible split division (distributes remainder)', () {
      const int totalAmount = 4000000;
      const int numParticipants = 3;

      final baseSplit = totalAmount ~/ numParticipants;
      final remainder = totalAmount % numParticipants;

      final List<int> splits = [];
      for (int i = 0; i < numParticipants; i++) {
        splits.add(baseSplit + (i < remainder ? 1 : 0));
      }

      expect(splits, [1333334, 1333333, 1333333]);

      final sum = splits.fold<int>(0, (a, b) => a + b);
      expect(sum, totalAmount);
    });

    test('Indivisible split division - remainder is 2', () {
      const int totalAmount = 5000000;
      const int numParticipants = 3;

      final baseSplit = totalAmount ~/ numParticipants;
      final remainder = totalAmount % numParticipants;

      final List<int> splits = [];
      for (int i = 0; i < numParticipants; i++) {
        splits.add(baseSplit + (i < remainder ? 1 : 0));
      }

      expect(splits, [1666667, 1666667, 1666666]);

      final sum = splits.fold<int>(0, (a, b) => a + b);
      expect(sum, totalAmount);
    });
  });
}
