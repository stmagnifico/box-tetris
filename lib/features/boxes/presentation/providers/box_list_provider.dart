import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/box.dart';
import '../../domain/entities/nesting_node.dart';

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

/// Last optimization result. Resets automatically whenever the box list changes.
final nestingResultProvider =
    StateNotifierProvider<NestingResultNotifier, NestingResult?>((ref) {
  return NestingResultNotifier(ref);
});

class NestingResultNotifier extends StateNotifier<NestingResult?> {
  NestingResultNotifier(Ref ref) : super(null) {
    ref.listen<List<Box>>(boxListProvider, (_, __) {
      state = null;
    });
  }

  void setResult(NestingResult result) => state = result;
}
