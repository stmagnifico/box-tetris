import 'box.dart';

/// A node in the nesting tree: one box and boxes nested directly inside it.
class NestingNode {
  const NestingNode({
    required this.box,
    this.children = const [],
  });

  final Box box;

  /// Boxes nested inside [box] (each may have its own subtree).
  final List<NestingNode> children;

  /// Occupied volume at this tree level (outer volume of this container only).
  double get occupiedVolume => box.volume;

  /// Deepest nesting depth including this node (1 = leaf).
  int get maxDepth {
    if (children.isEmpty) return 1;
    return 1 + children.map((c) => c.maxDepth).reduce((a, b) => a > b ? a : b);
  }

  /// Total count of boxes in this subtree (including [box]).
  int get boxCount => 1 + children.fold(0, (sum, c) => sum + c.boxCount);

  /// All boxes in preorder (parent before children).
  Iterable<Box> get allBoxes sync* {
    yield box;
    for (final child in children) {
      yield* child.allBoxes;
    }
  }
}

/// Result of the optimizer: forest of nesting trees plus volume statistics.
class NestingResult {
  const NestingResult({
    required this.roots,
    required this.originalTotalVolume,
    required this.optimizedTotalVolume,
  });

  /// Top-level containers (not nested inside any other box).
  final List<NestingNode> roots;

  final double originalTotalVolume;
  final double optimizedTotalVolume;

  double get savedVolume => originalTotalVolume - optimizedTotalVolume;

  double get savedPercent =>
      originalTotalVolume > 0 ? (savedVolume / originalTotalVolume) * 100 : 0;

  int get rootCount => roots.length;
}
