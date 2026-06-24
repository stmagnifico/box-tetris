import 'package:box_tetris/features/boxes/domain/entities/box.dart';
import 'package:box_tetris/features/boxes/domain/services/box_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';

List<Box> _seedBoxes() => [
      Box(id: '0', label: 'Long Rod', width: 30, height: 5, depth: 5),
      Box(id: '1', label: 'Wide Plate', width: 5, height: 30, depth: 5),
      Box(id: '2', label: 'Tall Tower', width: 5, height: 5, depth: 30),
      Box(id: '3', label: 'Perfect Cube 12³', width: 12, height: 12, depth: 12),
      Box(id: '4', label: 'Flat Board', width: 25, height: 25, depth: 2),
      Box(id: '5', label: 'Big Block', width: 15, height: 15, depth: 15),
    ];

void main() {
  test('12 cube fits in 15 cube physically', () {
    final optimizer = BoxOptimizer();
    final big = Box(id: 'b', label: 'Big Block', width: 15, height: 15, depth: 15);
    final small = Box(id: 's', label: 'Perfect Cube 12³', width: 12, height: 12, depth: 12);
    expect(optimizer.canNest(small, big), isTrue);
  });

  test('nests 12 cube inside 15 block in seed scenario', () {
    final result = BoxOptimizer().optimize(_seedBoxes());
    final big = result.roots.where((n) => n.box.label == 'Big Block').firstOrNull;

    expect(
      big?.children.map((c) => c.box.label),
      contains('Perfect Cube 12³'),
    );
    expect(result.optimizedTotalVolume, lessThan(result.originalTotalVolume));
    expect(result.roots.length, 5);
  });
}
