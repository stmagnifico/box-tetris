import 'dart:convert';

import 'package:flutter/services.dart';

import '../../features/boxes/domain/entities/box.dart';
import 'seed_config.dart';

/// Loads optional startup boxes from assets/config/seed_boxes.json.
class SeedConfigLoader {
  SeedConfigLoader._();

  static const assetPath = 'config/seed_boxes.json';

  /// Returns seed boxes when config exists, is enabled, and has entries.
  static Future<List<Box>?> load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final config = SeedConfig.fromJson(json);
      if (!config.enabled || config.boxes.isEmpty) return null;
      return config.toBoxes();
    } on FormatException {
      // Invalid JSON shape — ignore seed data.
      return null;
    } catch (_) {
      // Asset missing or unreadable — start with an empty list.
      return null;
    }
  }
}
