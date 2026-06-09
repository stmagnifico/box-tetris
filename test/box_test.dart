import 'package:box_tetris/features/boxes/domain/entities/box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Box', () {
    test('computes outer and inner volume', () {
      final box = Box(
        id: '1',
        width: 100,
        height: 50,
        depth: 40,
        wallThickness: 1,
      );
      expect(box.volume, 100 * 50 * 40);
      expect(box.innerWidth, 98);
      expect(box.innerHeight, 48);
      expect(box.innerDepth, 38);
      expect(box.innerVolume, 98 * 48 * 38);
    });
  });
}
