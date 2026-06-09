import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/box.dart';
import '../../domain/entities/nesting_node.dart';
import '../../domain/services/box_optimizer.dart';

final boxOptimizerProvider = Provider<BoxOptimizer>((ref) {
  return BoxOptimizer();
});

/// User-managed list of boxes (manual input; CV module will plug in here later).
class BoxListNotifier extends StateNotifier<List<Box>> {
  BoxListNotifier([List<Box>? initial]) : super(initial ?? []);

  static const _uuid = Uuid();

  void addBox({
    required double width,
    required double height,
    required double depth,
    double wallThickness = 0.0,
    String? label,
  }) {
    state = [
      ...state,
      Box(
        id: _uuid.v4(),
        width: width,
        height: height,
        depth: depth,
        wallThickness: wallThickness,
        label: label,
      ),
    ];
  }

  void updateBox({
    required String id,
    required double width,
    required double height,
    required double depth,
    double wallThickness = 0.0,
    String? label,
  }) {
    state = [
      for (final box in state)
        if (box.id == id)
          box.copyWith(
            width: width,
            height: height,
            depth: depth,
            wallThickness: wallThickness,
            label: label,
          )
        else
          box,
    ];
  }

  void removeBox(String id) {
    state = state.where((b) => b.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

final boxListProvider =
    StateNotifierProvider<BoxListNotifier, List<Box>>((ref) {
  return BoxListNotifier();
});

/// Last optimization result (null until user runs calculation).
final nestingResultProvider = StateProvider<NestingResult?>((ref) => null);
