/// Represents a physical box with outer dimensions and optional wall thickness.
class Box {
  Box({
    required this.id,
    required this.width,
    required this.height,
    required this.depth,
    this.wallThickness = 0.0,
    this.label,
  }) : assert(width > 0 && height > 0 && depth > 0),
       assert(wallThickness >= 0),
       assert(wallThickness * 2 < width),
       assert(wallThickness * 2 < height),
       assert(wallThickness * 2 < depth);

  final String id;
  final double width;
  final double height;
  final double depth;
  final double wallThickness;

  /// Optional display name (e.g. "Kitchen box").
  final String? label;

  /// Usable inner width after subtracting both walls.
  double get innerWidth => width - 2 * wallThickness;

  /// Usable inner height after subtracting both walls.
  double get innerHeight => height - 2 * wallThickness;

  /// Usable inner depth after subtracting both walls.
  double get innerDepth => depth - 2 * wallThickness;

  /// Outer volume (storage footprint when this box is not nested).
  double get volume => width * height * depth;

  /// Inner cavity volume available for smaller boxes.
  double get innerVolume => innerWidth * innerHeight * innerDepth;

  /// Sorted outer edge lengths — useful for rotation checks.
  List<double> get outerDimensionsSorted => [width, height, depth]..sort();

  /// Sorted inner edge lengths.
  List<double> get innerDimensionsSorted =>
      [innerWidth, innerHeight, innerDepth]..sort();

  static const Object _unset = Object();

  Box copyWith({
    String? id,
    double? width,
    double? height,
    double? depth,
    double? wallThickness,
    Object? label = _unset,
  }) {
    return Box(
      id: id ?? this.id,
      width: width ?? this.width,
      height: height ?? this.height,
      depth: depth ?? this.depth,
      wallThickness: wallThickness ?? this.wallThickness,
      label: identical(label, _unset) ? this.label : label as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Box &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          width == other.width &&
          height == other.height &&
          depth == other.depth &&
          wallThickness == other.wallThickness &&
          label == other.label;

  @override
  int get hashCode =>
      Object.hash(id, width, height, depth, wallThickness, label);

  @override
  String toString() =>
      'Box(id: $id, ${width}x$height}x$depth, wall: $wallThickness)';
}
