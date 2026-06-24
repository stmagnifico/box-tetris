/// Converts a volume in cm³ to a human-readable string.
///
/// • ≥ 1 000 000 cm³ → m³ (2 decimal places)
/// • ≥ 1 000 cm³     → litres (1 decimal place)
/// • otherwise       → cm³ (integer)
String formatVolume(double v) {
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(2)} m³';
  }
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(1)} L';
  }
  return '${v.toStringAsFixed(0)} cm³';
}
