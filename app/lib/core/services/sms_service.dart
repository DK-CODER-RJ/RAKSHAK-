class SmsService {
  Future<void> sendEmergencySms({
    required List<String> contacts,
    required String message,
  }) async {
    // Integrate SMS plugin/platform channel here.
    for (final _ in contacts) {}
    final _ = message;
  }
}
