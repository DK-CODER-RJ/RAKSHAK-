import 'package:hive/hive.dart';

class LocalStorageService {
  LocalStorageService(this.boxName);

  final String boxName;

  Future<Box<String>> _open() async => Hive.openBox<String>(boxName);

  Future<void> put(String key, String encryptedPayload) async {
    final box = await _open();
    await box.put(key, encryptedPayload);
  }

  Future<Map<String, String>> getAll() async {
    final box = await _open();
    return Map.fromEntries(
        box.keys.map((key) => MapEntry(key.toString(), box.get(key)!)));
  }

  Future<void> delete(String key) async {
    final box = await _open();
    await box.delete(key);
  }
}
