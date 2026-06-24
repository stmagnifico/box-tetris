import 'package:box_tetris/core/config/seed_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SeedConfig', () {
    test('parses enabled config with wall thickness', () {
      final config = SeedConfig.fromJson({
        'enabled': true,
        'boxes': [
          {
            'label': 'Thick',
            'width': 24,
            'height': 24,
            'depth': 24,
            'wallThickness': 2,
          },
          {
            'width': 15,
            'height': 15,
            'depth': 15,
          },
        ],
      });

      expect(config.enabled, isTrue);
      expect(config.boxes.length, 2);
      expect(config.boxes.first.wallThickness, 2);
      expect(config.boxes.first.label, 'Thick');
    });

    test('disabled config can be represented', () {
      final config = SeedConfig.fromJson({
        'enabled': false,
        'boxes': [
          {'width': 10, 'height': 10, 'depth': 10},
        ],
      });

      expect(config.enabled, isFalse);
    });

    test('rejects non-positive dimensions', () {
      expect(
        () => SeedConfig.fromJson({
          'enabled': true,
          'boxes': [
            {'width': 0, 'height': 10, 'depth': 10},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
