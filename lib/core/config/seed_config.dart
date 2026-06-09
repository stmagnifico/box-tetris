import '../../features/boxes/domain/entities/box.dart';

/// One box entry from [SeedConfig].
class SeedBoxEntry {
  const SeedBoxEntry({
    required this.width,
    required this.height,
    required this.depth,
    this.wallThickness = 0,
    this.label,
  });

  final double width;
  final double height;
  final double depth;
  final double wallThickness;
  final String? label;

  factory SeedBoxEntry.fromJson(Map<String, dynamic> json) {
    return SeedBoxEntry(
      width: _readPositive(json['width'], 'width'),
      height: _readPositive(json['height'], 'height'),
      depth: _readPositive(json['depth'], 'depth'),
      wallThickness: _readNonNegative(json['wallThickness'], defaultValue: 0),
      label: json['label'] as String?,
    );
  }

  Box toBox({required String id}) {
    return Box(
      id: id,
      width: width,
      height: height,
      depth: depth,
      wallThickness: wallThickness,
      label: label,
    );
  }

  static double _readPositive(Object? value, String field) {
    final number = _asDouble(value, field);
    if (number <= 0) {
      throw FormatException('$field must be a positive number');
    }
    return number;
  }

  static double _readNonNegative(Object? value, {required double defaultValue}) {
    if (value == null) return defaultValue;
    final number = _asDouble(value, 'wallThickness');
    if (number < 0) {
      throw FormatException('wallThickness must be non-negative');
    }
    return number;
  }

  static double _asDouble(Object? value, String field) {
    if (value is num) return value.toDouble();
    throw FormatException('$field must be a number');
  }
}

/// Startup seed data loaded from config/seed_boxes.json.
class SeedConfig {
  const SeedConfig({
    required this.enabled,
    required this.boxes,
  });

  final bool enabled;
  final List<SeedBoxEntry> boxes;

  factory SeedConfig.fromJson(Map<String, dynamic> json) {
    final rawBoxes = json['boxes'];
    if (rawBoxes is! List) {
      throw const FormatException('boxes must be a list');
    }

    return SeedConfig(
      enabled: json['enabled'] as bool? ?? false,
      boxes: rawBoxes
          .map((item) => SeedBoxEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  List<Box> toBoxes() {
    return [
      for (var i = 0; i < boxes.length; i++)
        boxes[i].toBox(id: 'seed_$i'),
    ];
  }
}
