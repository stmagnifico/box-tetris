/// Placeholder for the future CV/Camera module.
///
/// Will replace manual dimension entry with detected W×H×D from camera frames.
class CvModuleStub {
  const CvModuleStub();

  bool get isAvailable => false;

  String get statusMessage =>
      'Camera module not integrated yet. Use manual input on the home screen.';
}
