import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();

  factory SecureStorageService() {
    return _instance;
  }

  SecureStorageService._internal();
  static const String _dataBox = 'secure_data';
  static const String _encryptionKeyKey = 'master_key';

  late Box _box;
  late encrypt.Encrypter _encrypter;
  final _secureStorage = const FlutterSecureStorage();

  Future<void> init() async {
    await Hive.initFlutter();

    // 1. Retrieve or Generate Master Key defined in SecureStorage
    String? base64Key = await _secureStorage.read(key: _encryptionKeyKey);

    if (base64Key == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      base64Key = base64Url.encode(key.bytes);
      await _secureStorage.write(key: _encryptionKeyKey, value: base64Key);
    }

    final keyBytes = base64Url.decode(base64Key);
    final key = encrypt.Key(keyBytes);
    // Fixed IV for simplicity in this demo, in prod use random IV per record

    _encrypter = encrypt.Encrypter(encrypt.AES(key));

    // 2. Open Hive Box with encryption (Hive supports encryption natively too, but we'll do manual for granular control if needed)
    // Actually, Hive's native encryption is better for the whole box.
    // Let's use Hive's native encryption for the box itself using the key.

    _box =
        await Hive.openBox(_dataBox, encryptionCipher: HiveAesCipher(keyBytes));
  }

  Future<void> saveData(String key, dynamic value) async {
    await _box.put(key, value);
  }

  dynamic getData(String key) {
    return _box.get(key);
  }

  Future<void> deleteData(String key) async {
    await _box.delete(key);
  }

  // File Encryption Helper
  List<int> encryptBytes(List<int> bytes) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encryptBytes(bytes, iv: iv);
    // Prepend IV to ciphertext for decryption
    return [...iv.bytes, ...encrypted.bytes];
  }

  List<int> decryptBytes(List<int> encryptedBytes) {
    final iv = encrypt.IV(Uint8List.fromList(encryptedBytes.sublist(0, 16)));
    final ciphertext =
        encrypt.Encrypted(Uint8List.fromList(encryptedBytes.sublist(16)));
    return _encrypter.decryptBytes(ciphertext, iv: iv);
  }
}
