import 'package:flutter/foundation.dart';

import '../entities/box.dart';
import '../entities/nesting_node.dart';
import 'box_optimizer.dart';

/// Runs optimization off the UI thread when possible.
Future<NestingResult> runOptimization(List<Box> boxes) {
  if (kIsWeb || boxes.length > BoxOptimizer.exhaustiveSearchLimit) {
    return Future(() => BoxOptimizer().optimize(boxes));
  }
  return compute(_optimizeIsolate, boxes);
}

NestingResult _optimizeIsolate(List<Box> boxes) {
  return BoxOptimizer().optimize(boxes);
}
