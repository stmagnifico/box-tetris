import '../entities/box.dart';
import '../entities/nesting_node.dart';
import 'box_packing.dart';

/// Finds an optimal nesting arrangement for a set of boxes.
///
/// Goal: minimize the sum of outer volumes of top-level (root) boxes.
/// When boxes are placed inside a container, only the container's outer
/// volume counts toward storage footprint.
///
/// Direct children of a container must all fit together in its inner cavity
/// (axis-aligned 3D packing). A child may itself contain nested boxes inside
/// its own cavity (matryoshka chain).
class BoxOptimizer {
  /// Maximum box count for exhaustive search; larger lists use greedy heuristic.
  static const int exhaustiveSearchLimit = 12;

  NestingResult optimize(List<Box> boxes) {
    if (boxes.isEmpty) {
      return const NestingResult(
        roots: [],
        originalTotalVolume: 0,
        optimizedTotalVolume: 0,
      );
    }

    final originalTotal = boxes.fold<double>(0, (sum, b) => sum + b.volume);

    final rawParents = boxes.length <= exhaustiveSearchLimit
        ? _findOptimalParentsExhaustive(boxes)
        : _findParentsGreedy(boxes);
    final improved = _improveParents(boxes, rawParents);
    final parentIndex = _refineMatryoshkaParents(boxes, improved);

    final roots = _buildForest(boxes, parentIndex);

    final optimizedTotal =
        roots.fold<double>(0, (sum, node) => sum + node.box.volume);

    return NestingResult(
      roots: roots,
      originalTotalVolume: originalTotal,
      optimizedTotalVolume: optimizedTotal,
    );
  }

  /// Returns true if [inner] can fit inside [outer]'s cavity in some orientation.
  bool canNest(Box inner, Box outer) {
    return canPackTogether(outer, [inner]);
  }

  /// Returns true if all [items] fit together inside [container]'s inner cavity.
  bool canPackTogether(Box container, List<Box> items) {
    return BoxPacking.canPackInCavity(container, items);
  }

  /// Exhaustive search over parent assignments (forest, no cycles).
  List<int> _findOptimalParentsExhaustive(List<Box> boxes) {
    final n = boxes.length;
    var bestRootsVolume = double.infinity;
    late List<int> bestParents;

    void assign(int index, List<int> parents) {
      if (index == n) {
        if (!_formsValidForest(boxes, parents)) return;
        final volume = _rootsVolume(boxes, parents);
        if (volume < bestRootsVolume) {
          bestRootsVolume = volume;
          bestParents = List<int>.from(parents);
        }
        return;
      }

      // Option: this box is a root (not nested).
      parents[index] = -1;
      assign(index + 1, parents);

      // Option: place inside a valid container together with its siblings.
      for (var container = 0; container < n; container++) {
        if (container == index) continue;
        if (!canNest(boxes[index], boxes[container])) continue;
        parents[index] = container;
        if (_hasCycle(parents, index)) continue;
        if (!_siblingsFit(boxes, parents, container)) continue;
        assign(index + 1, parents);
      }
    }

    bestParents = List.filled(n, -1);
    assign(0, List.filled(n, -1));
    return bestParents;
  }

  /// Greedy: nest smallest-volume boxes into the best fitting larger container.
  List<int> _findParentsGreedy(List<Box> boxes) {
    final n = boxes.length;
    final parents = List<int>.filled(n, -1);
    final indices = List.generate(n, (i) => i)
      ..sort((a, b) => boxes[a].volume.compareTo(boxes[b].volume));

    for (final child in indices) {
      var bestParent = -1;
      var bestParentVolume = double.infinity;

      for (var container = 0; container < n; container++) {
        if (container == child) continue;

        parents[child] = container;
        if (_hasCycle(parents, child)) {
          parents[child] = -1;
          continue;
        }
        if (!_siblingsFit(boxes, parents, container)) {
          parents[child] = -1;
          continue;
        }

        // Prefer nesting into the smallest outer box that still fits (tighter pack).
        final containerVolume = boxes[container].volume;
        if (containerVolume < bestParentVolume) {
          bestParentVolume = containerVolume;
          bestParent = container;
        }
        parents[child] = -1;
      }

      if (bestParent >= 0) {
        parents[child] = bestParent;
      }
    }

    return parents;
  }

  bool _formsValidForest(List<Box> boxes, List<int> parents) {
    final childrenByParent = <int, List<int>>{};
    for (var i = 0; i < parents.length; i++) {
      if (_hasCycle(parents, i)) return false;
      final parent = parents[i];
      if (parent >= 0) {
        childrenByParent.putIfAbsent(parent, () => []).add(i);
      }
    }

    for (final entry in childrenByParent.entries) {
      final siblings = entry.value.map((i) => boxes[i]).toList();
      if (!canPackTogether(boxes[entry.key], siblings)) return false;
    }

    return true;
  }

  /// True when every direct child of [container] fits together in its cavity.
  bool _siblingsFit(List<Box> boxes, List<int> parents, int container) {
    final siblings = <Box>[];
    for (var i = 0; i < parents.length; i++) {
      if (parents[i] == container) siblings.add(boxes[i]);
    }
    return canPackTogether(boxes[container], siblings);
  }

  bool _hasCycle(List<int> parents, int start) {
    final visited = <int>{};
    var current = start;
    while (parents[current] >= 0) {
      if (!visited.add(current)) return true;
      current = parents[current];
    }
    return false;
  }

  double _rootsVolume(List<Box> boxes, List<int> parents) {
    var total = 0.0;
    for (var i = 0; i < boxes.length; i++) {
      if (parents[i] < 0) total += boxes[i].volume;
    }
    return total;
  }

  /// Greedily nests boxes while the total root footprint keeps shrinking.
  List<int> _improveParents(List<Box> boxes, List<int> parents) {
    var result = List<int>.from(parents);
    var changed = true;

    while (changed) {
      changed = false;
      final baseline = _rootsVolume(boxes, result);
      final indices = List.generate(boxes.length, (i) => i)
        ..sort((a, b) => boxes[a].volume.compareTo(boxes[b].volume));

      for (final child in indices) {
        var bestParent = result[child];
        var bestVolume = baseline;

        for (var container = 0; container < boxes.length; container++) {
          if (container == child) continue;
          if (!canNest(boxes[child], boxes[container])) continue;

          final trial = List<int>.from(result);
          trial[child] = container;
          if (_hasCycle(trial, child)) continue;
          if (!_formsValidForest(boxes, trial)) continue;

          final trialVolume = _rootsVolume(boxes, trial);
          if (trialVolume < bestVolume) {
            bestVolume = trialVolume;
            bestParent = container;
          }
        }

        if (bestVolume < baseline) {
          result[child] = bestParent;
          changed = true;
          break;
        }
      }
    }

    return result;
  }

  /// Pushes boxes deeper into matryoshka chains when footprint stays the same.
  ///
  /// Example: Bar C may fit both Bar A and Bar B; prefer the tighter / later
  /// valid container so Bar C nests inside Bar B instead of beside it under A.
  List<int> _refineMatryoshkaParents(List<Box> boxes, List<int> parents) {
    final result = List<int>.from(parents);
    final targetRoots = _rootsVolume(boxes, parents);
    var improved = true;

    while (improved) {
      improved = false;
      for (var i = 0; i < boxes.length; i++) {
        final currentParent = result[i];
        var bestParent = currentParent;
        var bestScore = currentParent < 0
            ? double.negativeInfinity
            : _matryoshkaParentScore(boxes, result, i, currentParent);

        for (var j = 0; j < boxes.length; j++) {
          if (j == i) continue;
          if (!canNest(boxes[i], boxes[j])) continue;

          final trial = List<int>.from(result);
          trial[i] = j;
          if (_hasCycle(trial, i)) continue;
          if (!_formsValidForest(boxes, trial)) continue;
          if (_rootsVolume(boxes, trial) > targetRoots) continue;

          final score = _matryoshkaParentScore(boxes, trial, i, j);
          if (score > bestScore) {
            bestScore = score;
            bestParent = j;
            improved = true;
          }
        }

        result[i] = bestParent;
      }
    }

    return result;
  }

  double _matryoshkaParentScore(
    List<Box> boxes,
    List<int> parents,
    int child,
    int parent,
  ) {
    final depth = _nestingDepth(parents, child);
    final waste = boxes[parent].innerVolume - boxes[child].volume;
    return depth * 1e6 - waste + parent * 1e-3;
  }

  int _nestingDepth(List<int> parents, int index) {
    var depth = 0;
    var current = index;
    while (parents[current] >= 0) {
      depth++;
      current = parents[current];
    }
    return depth;
  }

  List<NestingNode> _buildForest(List<Box> boxes, List<int> parents) {
    final n = boxes.length;
    final childrenMap = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      final p = parents[i];
      if (p >= 0) {
        childrenMap.putIfAbsent(p, () => []).add(i);
      }
    }

    NestingNode buildNode(int index) {
      final childIndices = childrenMap[index] ?? [];
      childIndices.sort((a, b) => _compareChildOrder(boxes, a, b));
      return NestingNode(
        box: boxes[index],
        children: childIndices.map(buildNode).toList(),
      );
    }

    final roots = <int>[];
    for (var i = 0; i < n; i++) {
      if (parents[i] < 0) roots.add(i);
    }
    roots.sort((a, b) => boxes[b].volume.compareTo(boxes[a].volume));

    return roots.map(buildNode).toList();
  }

  int _compareChildOrder(List<Box> boxes, int a, int b) {
    final volumeCmp = boxes[a].volume.compareTo(boxes[b].volume);
    if (volumeCmp != 0) return volumeCmp;

    final labelA = boxes[a].label ?? '';
    final labelB = boxes[b].label ?? '';
    final labelCmp = labelA.compareTo(labelB);
    if (labelCmp != 0) return labelCmp;

    return a.compareTo(b);
  }
}
