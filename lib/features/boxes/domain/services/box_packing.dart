import '../entities/box.dart';

/// Axis-aligned 3D packing check for multiple boxes inside one cavity.
class BoxPacking {
  BoxPacking._();

  static const List<List<int>> _permutationIndices = [
    [0, 1, 2],
    [0, 2, 1],
    [1, 0, 2],
    [1, 2, 0],
    [2, 0, 1],
    [2, 1, 0],
  ];

  /// Returns true if all [items] fit together inside [container]'s inner cavity.
  static bool canPackInCavity(Box container, List<Box> items) {
    if (items.isEmpty) return true;
    return _packAll(
      items,
      container.innerWidth,
      container.innerHeight,
      container.innerDepth,
    );
  }

  static List<({double w, double h, double d})> _orientations(Box box) {
    final dims = [box.width, box.height, box.depth];
    return _permutationIndices
        .map((perm) => (
              w: dims[perm[0]],
              h: dims[perm[1]],
              d: dims[perm[2]],
            ))
        .toList();
  }

  static bool _packAll(List<Box> items, double cavityW, double cavityH, double cavityD) {
    final orientations = items.map(_orientations).toList();
    return _searchPack(
      0,
      orientations,
      cavityW,
      cavityH,
      cavityD,
      [],
    );
  }

  static bool _searchPack(
    int itemIndex,
    List<List<({double w, double h, double d})>> orientations,
    double cavityW,
    double cavityH,
    double cavityD,
    List<_PlacedBox> placed,
  ) {
    if (itemIndex == orientations.length) return true;

    for (final oriented in orientations[itemIndex]) {
      if (oriented.w >= cavityW ||
          oriented.h >= cavityH ||
          oriented.d >= cavityD) {
        continue;
      }

      for (final position in _candidatePositions(oriented, placed)) {
        final candidate = _PlacedBox(
          x: position.$1,
          y: position.$2,
          z: position.$3,
          w: oriented.w,
          h: oriented.h,
          d: oriented.d,
        );
        if (!_fitsInCavity(candidate, cavityW, cavityH, cavityD)) continue;
        if (_overlapsAny(candidate, placed)) continue;

        placed.add(candidate);
        if (_searchPack(
          itemIndex + 1,
          orientations,
          cavityW,
          cavityH,
          cavityD,
          placed,
        )) {
          return true;
        }
        placed.removeLast();
      }
    }
    return false;
  }

  /// Bottom-left-depth positions: origin plus faces of already placed boxes.
  static Iterable<(double, double, double)> _candidatePositions(
    ({double w, double h, double d}) oriented,
    List<_PlacedBox> placed,
  ) sync* {
    yield (0, 0, 0);

    for (final box in placed) {
      yield (box.x + box.w, box.y, box.z);
      yield (box.x, box.y + box.h, box.z);
      yield (box.x, box.y, box.z + box.d);
    }
  }

  static bool _fitsInCavity(
    _PlacedBox box,
    double cavityW,
    double cavityH,
    double cavityD,
  ) {
    return box.x + box.w <= cavityW + _epsilon &&
        box.y + box.h <= cavityH + _epsilon &&
        box.z + box.d <= cavityD + _epsilon;
  }

  static bool _overlapsAny(_PlacedBox candidate, List<_PlacedBox> placed) {
    for (final other in placed) {
      if (_overlaps(candidate, other)) return true;
    }
    return false;
  }

  static bool _overlaps(_PlacedBox a, _PlacedBox b) {
    return a.x < b.x + b.w - _epsilon &&
        a.x + a.w > b.x + _epsilon &&
        a.y < b.y + b.h - _epsilon &&
        a.y + a.h > b.y + _epsilon &&
        a.z < b.z + b.d - _epsilon &&
        a.z + a.d > b.z + _epsilon;
  }

  static const double _epsilon = 1e-9;
}

class _PlacedBox {
  const _PlacedBox({
    required this.x,
    required this.y,
    required this.z,
    required this.w,
    required this.h,
    required this.d,
  });

  final double x;
  final double y;
  final double z;
  final double w;
  final double h;
  final double d;
}
