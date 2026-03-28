class VoiceTriggerService {
  Future<void> initialize() async {}

  // Replace with an offline keyword spotting SDK/plugin in production.
  Stream<String> get keywordStream async* {}
}
