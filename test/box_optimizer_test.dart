import 'package:box_tetris/features/boxes/domain/entities/box.dart';
import 'package:box_tetris/features/boxes/domain/entities/nesting_node.dart';
import 'package:box_tetris/features/boxes/domain/services/box_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BoxOptimizer optimizer;

  setUp(() {
    optimizer = BoxOptimizer();
  });

  group('canNest', () {
    test('fits only with a valid 90° rotation', () {
      final outer = Box(id: 'o', width: 25, height: 12, depth: 20);
      final inner = Box(id: 'i', width: 10, height: 11, depth: 22);
      expect(optimizer.canNest(inner, outer), isTrue);
    });

    test('rejects when any edge equals cavity (strict inequality)', () {
      final outer = Box(id: 'o', width: 20, height: 20, depth: 20);
      final sameSize = Box(id: 'i', width: 20, height: 20, depth: 20);
      expect(optimizer.canNest(sameSize, outer), isFalse);

      final oneEdgeEqual = Box(id: 'i2', width: 20, height: 19, depth: 19);
      expect(optimizer.canNest(oneEdgeEqual, outer), isFalse);
    });

    test('rejects larger box in smaller container', () {
      final outer = Box(id: 'small', width: 10, height: 10, depth: 10);
      final inner = Box(id: 'large', width: 15, height: 15, depth: 15);
      expect(optimizer.canNest(inner, outer), isFalse);
    });

    test('respects wall thickness on container cavity', () {
      final outer = Box(
        id: 'o',
        width: 20,
        height: 20,
        depth: 20,
        wallThickness: 2,
      );
      // Inner cavity is 16×16×16.
      final tooBig = Box(id: 'i', width: 17, height: 17, depth: 17);
      expect(optimizer.canNest(tooBig, outer), isFalse);

      final fits = Box(id: 'i2', width: 15, height: 15, depth: 15);
      expect(optimizer.canNest(fits, outer), isTrue);
    });

    test('inner box wall thickness does not affect fitting check', () {
      final outer = Box(id: 'o', width: 30, height: 30, depth: 30);
      final thickWalledInner = Box(
        id: 'i',
        width: 20,
        height: 20,
        depth: 20,
        wallThickness: 3,
      );
      expect(optimizer.canNest(thickWalledInner, outer), isTrue);
    });

    test('thick walls can block nesting that works without them', () {
      final thinOuter = Box(id: 'thin', width: 22, height: 22, depth: 22);
      final inner = Box(id: 'inner', width: 21, height: 21, depth: 21);
      expect(optimizer.canNest(inner, thinOuter), isTrue);

      final thickOuter = Box(
        id: 'thick',
        width: 22,
        height: 22,
        depth: 22,
        wallThickness: 1,
      );
      // Cavity 20×20×20 — 21 does not fit.
      expect(optimizer.canNest(inner, thickOuter), isFalse);
    });

    test('fits flat box when rotated to align shallow edge with depth', () {
      final outer = Box(id: 'o', width: 40, height: 30, depth: 12);
      final flat = Box(id: 'f', width: 35, height: 28, depth: 10);
      expect(optimizer.canNest(flat, outer), isTrue);
    });
  });

  group('optimize', () {
    test('empty list returns zero volumes', () {
      final result = optimizer.optimize([]);
      expect(result.roots, isEmpty);
      expect(result.optimizedTotalVolume, 0);
      expect(result.savedPercent, 0);
    });

    test('single box stays a root with no savings', () {
      final box = Box(id: 'solo', width: 30, height: 30, depth: 30);
      final result = optimizer.optimize([box]);

      expect(result.roots.length, 1);
      expect(result.roots.first.box.id, 'solo');
      expect(result.optimizedTotalVolume, box.volume);
      expect(result.savedPercent, 0);
    });

    test('nests three cubic boxes into one root chain', () {
      final boxes = [
        Box(id: 'large', width: 50, height: 50, depth: 50),
        Box(id: 'medium', width: 40, height: 40, depth: 40),
        Box(id: 'small', width: 30, height: 30, depth: 30),
      ];

      final result = optimizer.optimize(boxes);

      expect(result.roots.length, 1);
      expect(result.optimizedTotalVolume, boxes[0].volume);
      expect(result.originalTotalVolume, greaterThan(result.optimizedTotalVolume));
      expect(result.savedPercent, greaterThan(0));
      expect(_deepestChain(result.roots.first), 3);
    });

    test('keeps separate roots when identical boxes cannot nest', () {
      final boxes = [
        Box(id: 'a', width: 10, height: 10, depth: 10),
        Box(id: 'b', width: 10, height: 10, depth: 10),
      ];

      final result = optimizer.optimize(boxes);

      expect(result.roots.length, 2);
      expect(result.optimizedTotalVolume, result.originalTotalVolume);
      expect(result.savedPercent, 0);
    });

    test('packs two 19×19×9 boxes inside 20×20×20', () {
      final large = Box(id: 'large', width: 20, height: 20, depth: 20);
      final small = Box(id: 'small', width: 19, height: 19, depth: 9);
      final boxes = [
        large,
        small.copyWith(id: 'small_a'),
        small.copyWith(id: 'small_b'),
      ];

      expect(optimizer.canPackTogether(large, boxes.sublist(1)), isTrue);

      final result = optimizer.optimize(boxes);

      final largeRoot = result.roots.single;
      expect(largeRoot.box.id, 'large');
      expect(largeRoot.children.length, 2);
      expect(result.optimizedTotalVolume, large.volume);
    });

    test('does not pack four 19×19×9 boxes into one 20×20×20', () {
      final large = Box(id: 'large', width: 20, height: 20, depth: 20);
      final small = Box(id: 'small', width: 19, height: 19, depth: 9);
      final boxes = [
        large,
        ...List.generate(4, (i) => small.copyWith(id: 'small_$i')),
      ];

      expect(optimizer.canPackTogether(large, boxes.sublist(1)), isFalse);

      final result = optimizer.optimize(boxes);

      final largeRoot = result.roots.firstWhere((r) => r.box.id == 'large');
      expect(largeRoot.children.length, 2);
      expect(result.roots.length, 3);
      expect(
        result.optimizedTotalVolume,
        large.volume + small.volume * 2,
      );
    });

    test('builds deepest chain when intermediate boxes exist', () {
      final boxes = [
        Box(id: 'a', width: 100, height: 100, depth: 100),
        Box(id: 'b', width: 80, height: 80, depth: 80),
        Box(id: 'c', width: 60, height: 60, depth: 60),
        Box(id: 'd', width: 40, height: 40, depth: 40),
      ];

      final result = optimizer.optimize(boxes);

      expect(result.roots.length, 1);
      expect(_deepestChain(result.roots.first), 4);
      expect(result.optimizedTotalVolume, boxes.first.volume);
    });

    test('wall thickness breaks an otherwise valid chain', () {
      final outer = Box(
        id: 'outer',
        width: 25,
        height: 25,
        depth: 25,
        wallThickness: 3,
      );
      // Cavity 19×19×19 — 20 does not fit.
      final middle = Box(id: 'mid', width: 20, height: 20, depth: 20);
      final inner = Box(id: 'inner', width: 15, height: 15, depth: 15);

      final result = optimizer.optimize([outer, middle, inner]);

      // middle cannot nest in outer; inner may nest in middle only.
      expect(result.roots.length, greaterThanOrEqualTo(2));
      expect(result.optimizedTotalVolume, greaterThan(outer.volume));
    });

    test('packs multiple boxes into the largest container when they fit', () {
      final huge = Box(id: 'huge', width: 100, height: 100, depth: 100);
      final medium = Box(id: 'medium', width: 50, height: 50, depth: 50);
      final tiny = Box(id: 'tiny', width: 10, height: 10, depth: 10);

      final result = optimizer.optimize([huge, medium, tiny]);

      expect(result.roots.length, 1);
      expect(result.optimizedTotalVolume, huge.volume);
      // Prefer matryoshka chain (medium → tiny) over loose siblings when both fit.
      expect(_deepestChain(result.roots.first), 3);
    });

    test('chooses nesting that minimizes total root volume', () {
      // Two large roots vs one large + one nested small.
      final a = Box(id: 'a', width: 30, height: 30, depth: 30);
      final b = Box(id: 'b', width: 28, height: 28, depth: 28);
      final c = Box(id: 'c', width: 10, height: 10, depth: 10);

      final result = optimizer.optimize([a, b, c]);

      expect(result.optimizedTotalVolume, lessThan(result.originalTotalVolume));
      expect(_totalRootVolume(result), result.optimizedTotalVolume);
    });

    test('handles many boxes with valid sibling packing', () {
      final boxes = List.generate(
        15,
        (i) => Box(
          id: 'box_$i',
          width: 30 - i.toDouble(),
          height: 30 - i.toDouble(),
          depth: 30 - i.toDouble(),
        ),
      );

      final result = optimizer.optimize(boxes);

      expect(result.roots, isNotEmpty);
      expect(result.optimizedTotalVolume, lessThanOrEqualTo(result.originalTotalVolume));
      for (final root in result.roots) {
        _assertValidTree(optimizer, root);
      }
    });

    test('nests Bar C inside Bar B when both bars are siblings', () {
      final boxes = [
        Box(id: '0', label: 'Container 20³', width: 20, height: 20, depth: 20),
        Box(id: '3', label: 'Bar A', width: 19, height: 9, depth: 9),
        Box(id: '4', label: 'Bar B', width: 19, height: 9, depth: 9),
        Box(id: '8', label: 'Bar C', width: 18, height: 8, depth: 8),
      ];

      final result = BoxOptimizer().optimize(boxes);
      final container = result.roots.single;
      final barB = container.children.firstWhere((n) => n.box.label == 'Bar B');
      final barCParent = _findParentLabel(container, 'Bar C');

      expect(barB.children.single.box.label, 'Bar C');
      expect(barCParent, 'Bar B');
      expect(
        container.children.any((n) => n.box.label == 'Bar A' && n.children.isEmpty),
        isTrue,
      );
    });

    test('respects wall thickness across full optimization', () {
      final container = Box(
        id: 'c',
        width: 24,
        height: 24,
        depth: 24,
        wallThickness: 2,
      );
      final candidate = Box(id: 'n', width: 21, height: 21, depth: 21);
      final small = Box(id: 's', width: 15, height: 15, depth: 15);

      final result = optimizer.optimize([container, candidate, small]);

      final containerRoot =
          result.roots.where((r) => r.box.id == 'c').firstOrNull;
      if (containerRoot != null) {
        expect(containerRoot.children.map((c) => c.box.id), isNot(contains('n')));
      }
      expect(optimizer.canNest(candidate, container), isFalse);
      expect(optimizer.canNest(small, container), isTrue);
    });
  });

  group('canPackTogether', () {
    test('stacks identical flat boxes along depth axis', () {
      final container = Box(id: 'c', width: 20, height: 20, depth: 20);
      final flat = Box(id: 'f', width: 19, height: 19, depth: 9);
      expect(
        optimizer.canPackTogether(container, [flat, flat.copyWith(id: 'f2')]),
        isTrue,
      );
      expect(
        optimizer.canPackTogether(
          container,
          List.generate(3, (i) => flat.copyWith(id: 'f$i')),
        ),
        isFalse,
      );
    });
  });
}

/// Deepest nesting depth in a subtree.
int _deepestChain(NestingNode node) {
  if (node.children.isEmpty) return 1;
  return 1 + node.children.map(_deepestChain).reduce((a, b) => a > b ? a : b);
}

String? _findParentLabel(NestingNode root, String childLabel) {
  String? search(NestingNode node) {
    for (final child in node.children) {
      if (child.box.label == childLabel) return node.box.label;
      final nested = search(child);
      if (nested != null) return nested;
    }
    return null;
  }
  return search(root);
}

double _totalRootVolume(NestingResult result) {
  return result.roots.fold<double>(0, (sum, r) => sum + r.box.volume);
}

/// Verifies siblings pack in the parent cavity and recurses into subtrees.
void _assertValidTree(BoxOptimizer optimizer, NestingNode node) {
  if (node.children.isNotEmpty) {
    expect(
      optimizer.canPackTogether(
        node.box,
        node.children.map((c) => c.box).toList(),
      ),
      isTrue,
    );
  }
  for (final child in node.children) {
    _assertValidTree(optimizer, child);
  }
}
