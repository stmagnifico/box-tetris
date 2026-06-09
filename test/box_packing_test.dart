import 'package:box_tetris/features/boxes/domain/entities/box.dart';
import 'package:box_tetris/features/boxes/domain/services/box_packing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoxPacking', () {
    test('empty list always fits', () {
      final container = Box(id: 'c', width: 10, height: 10, depth: 10);
      expect(BoxPacking.canPackInCavity(container, []), isTrue);
    });

    test('two flat boxes stack in cubic cavity', () {
      final container = Box(id: 'c', width: 20, height: 20, depth: 20);
      final flat = Box(id: 'f', width: 19, height: 19, depth: 9);
      expect(
        BoxPacking.canPackInCavity(
          container,
          [flat, flat.copyWith(id: 'f2')],
        ),
        isTrue,
      );
    });

    test('three flat boxes do not fit in cubic cavity', () {
      final container = Box(id: 'c', width: 20, height: 20, depth: 20);
      final flat = Box(id: 'f', width: 19, height: 19, depth: 9);
      expect(
        BoxPacking.canPackInCavity(
          container,
          List.generate(3, (i) => flat.copyWith(id: 'f$i')),
        ),
        isFalse,
      );
    });

    test('wall thickness shrinks usable packing space', () {
      final container = Box(
        id: 'c',
        width: 20,
        height: 20,
        depth: 20,
        wallThickness: 1,
      );
      final flat = Box(id: 'f', width: 19, height: 19, depth: 9);
      expect(BoxPacking.canPackInCavity(container, [flat]), isFalse);
      expect(
        BoxPacking.canPackInCavity(
          container,
          [flat.copyWith(id: 'f2', width: 17, height: 17, depth: 8)],
        ),
        isTrue,
      );
    });
  });
}
