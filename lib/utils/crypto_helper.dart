import 'dart:convert';
import 'dart:typed_data';
import 'dart:isolate'; // TAMBAHAN: Untuk memproses data berat di belakang layar
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart';

class CryptoHelper {
  static encrypt_pkg.Key? _key;
  static encrypt_pkg.Encrypter? _encrypter;
  static final encrypt_pkg.IV _iv = encrypt_pkg.IV.fromUtf8('VektorInisial123');

  static void setMasterPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    _key = encrypt_pkg.Key(Uint8List.fromList(digest.bytes));
    _encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!));
  }

  static void clearKey() {
    _key = null;
    _encrypter = null;
  }

  // --- FUNGSI ENKRIPSI ASINKRON (ANTI-LAG) ---
  static Future<String> encryptDataAsync(String plainText) async {
    if (_key == null) throw Exception("Master Password belum diatur!");

    // Ekstrak byte kunci untuk dikirim ke Isolate (Isolate tidak berbagi memori)
    final keyBytes = _key!.bytes;
    final ivBytes = _iv.bytes;

    // Melempar tugas berat ke CPU core yang menganggur
    return await Isolate.run(() {
      final isolatedKey = encrypt_pkg.Key(keyBytes);
      final isolatedIv = encrypt_pkg.IV(ivBytes);
      final isolatedEncrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(isolatedKey));

      final encrypted = isolatedEncrypter.encrypt(plainText, iv: isolatedIv);
      return encrypted.base64;
    });
  }

  // --- FUNGSI DEKRIPSI ASINKRON (ANTI-LAG) ---
  static Future<String> decryptDataAsync(String base64CipherText) async {
    if (_key == null) throw Exception("Master Password belum diatur!");

    final keyBytes = _key!.bytes;
    final ivBytes = _iv.bytes;

    return await Isolate.run(() {
      final isolatedKey = encrypt_pkg.Key(keyBytes);
      final isolatedIv = encrypt_pkg.IV(ivBytes);
      final isolatedEncrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(isolatedKey));

      final encrypted = encrypt_pkg.Encrypted.fromBase64(base64CipherText);
      return isolatedEncrypter.decrypt(encrypted, iv: isolatedIv);
    });
  }
}