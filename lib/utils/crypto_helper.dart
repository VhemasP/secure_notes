import 'package:encrypt/encrypt.dart' as encrypt_pkg;

class CryptoHelper {
  // Panjang kunci AES-256 membutuhkan 32 karakter (256 bit)
  // CATATAN: Untuk MVP/Eksperimen, kunci diletakkan di sini. 
  // Di aplikasi production, kunci harus diamankan di KeyStore/Keychain.
  static final String _keyString = 'KunciRahasiaSuperAman12345678901'; 
  
  // IV (Initialization Vector) membutuhkan 16 karakter (128 bit)
  static final String _ivString = 'VektorInisial123'; 

  // Inisialisasi Key dan IV
  static final _key = encrypt_pkg.Key.fromUtf8(_keyString);
  static final _iv = encrypt_pkg.IV.fromUtf8(_ivString);
  
  // Inisialisasi Encrypter dengan algoritma AES
  static final _encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key));

  /// Fungsi untuk mengubah Plaintext menjadi Ciphertext
  static String encryptData(String plainText) {
    // Proses enkripsi
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    // Mengembalikan hasil dalam format Base64 agar aman disimpan di SQLite
    return encrypted.base64; 
  }

  /// Fungsi untuk mengembalikan Ciphertext menjadi Plaintext
  static String decryptData(String base64CipherText) {
    // Membaca ciphertext dari format Base64
    final encrypted = encrypt_pkg.Encrypted.fromBase64(base64CipherText);
    // Proses dekripsi
    final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
    return decrypted;
  }
}