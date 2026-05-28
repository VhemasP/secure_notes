import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart'; // Untuk SHA-256 hashing

class CryptoHelper {
  // Variabel kunci sekarang bersifat dinamis dan kosong saat aplikasi pertama dibuka
  static encrypt_pkg.Key? _key;
  static encrypt_pkg.Encrypter? _encrypter;

  // IV (Initialization Vector) kita biarkan statis untuk kemudahan MVP.
  // Di sistem yang sangat ketat (production), IV biasanya di-generate secara acak per catatan.
  static final encrypt_pkg.IV _iv = encrypt_pkg.IV.fromUtf8('VektorInisial123');

  /// Mengolah Password User menjadi Kunci AES-256 (32 Bytes)
  static void setMasterPassword(String password) {
    // Menggunakan SHA-256 untuk memoles password menjadi tepat 32 byte (256 bit)
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);

    // Memasukkan hasil hash ke dalam Key AES
    _key = encrypt_pkg.Key(Uint8List.fromList(digest.bytes));

    // Inisialisasi ulang mesin Encrypter dengan kunci yang baru
    _encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!));
  }

  /// Menghapus kunci dari memori (Berguna untuk fitur Logout/Kunci Ulang)
  static void clearKey() {
    _key = null;
    _encrypter = null;
  }

  /// Fungsi Enkripsi (Hanya bisa berjalan jika Master Password sudah diinput)
  static String encryptData(String plainText) {
    if (_encrypter == null) throw Exception("Master Password belum diatur!");

    final encrypted = _encrypter!.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Fungsi Dekripsi (Hanya bisa berjalan jika Master Password sudah diinput)
  static String decryptData(String base64CipherText) {
    if (_encrypter == null) throw Exception("Master Password belum diatur!");

    final encrypted = encrypt_pkg.Encrypted.fromBase64(base64CipherText);
    return _encrypter!.decrypt(encrypted, iv: _iv);
  }
}