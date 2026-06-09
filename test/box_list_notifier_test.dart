import 'package:box_tetris/features/boxes/presentation/providers/box_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoxListNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('updateBox changes dimensions while preserving id', () {
      final notifier = container.read(boxListProvider.notifier);
      notifier.addBox(width: 10, height: 10, depth: 10, label: 'A');
      final id = container.read(boxListProvider).single.id;

      notifier.updateBox(
        id: id,
        width: 20,
        height: 15,
        depth: 12,
        wallThickness: 1,
        label: 'Updated',
      );

      final updated = container.read(boxListProvider).single;
      expect(updated.id, id);
      expect(updated.width, 20);
      expect(updated.height, 15);
      expect(updated.depth, 12);
      expect(updated.wallThickness, 1);
      expect(updated.label, 'Updated');
    });
  });
}
