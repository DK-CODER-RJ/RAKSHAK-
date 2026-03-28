import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  EncryptionService(String key)
      : _key = encrypt.Key.fromUtf8(key.padRight(32, '0').substring(0, 32)),
        _iv = encrypt.IV.fromLength(16);

  final encrypt.Key _key;
  final encrypt.IV _iv;

  String encryptJson(Map<String, dynamic> payload) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    return encrypter.encrypt(jsonEncode(payload), iv: _iv).base64;
  }

  Map<String, dynamic> decryptJson(String encrypted) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final raw = encrypter.decrypt64(encrypted, iv: _iv);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
