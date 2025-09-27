import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';

/// Derives an AES key from a [password] and [salt] using the PBKDF2 algorithm.
///
/// This function uses PBKDF2 with HMAC-SHA256 to generate a key of [length]
/// (default is 32 bytes) from the user's password. The number of [iterations]
/// (default is 100000) is used to strengthen the security.
Uint8List deriveKey(
  String password,
  String salt, {
  int length = 32,
  int iterations = 100000,
}) {
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  derivator.init(Pbkdf2Parameters(utf8.encode(salt), iterations, length));
  return derivator.process(utf8.encode(password));
}

/// Encrypts the [plainText] with the given [password] and [salt] using AES-CBC.
///
/// The input data is converted to JSON and then encrypted.
/// A random 16-byte IV (Initialization Vector) is generated and prepended
/// to the encrypted data.
///
/// If the [password] is empty, the data is returned as UTF-8 encoded JSON
/// without any actual encryption.
///
/// The encryption process is run in a separate Isolate to avoid blocking the
/// main thread.
Future<Uint8List> encryptWithPassword(
  dynamic plainText,
  String password,
  String salt,
) async {
  return Isolate.run(() {
    if (password.isEmpty) return utf8.encode(jsonEncode(plainText));

    final key = encrypt.Key(deriveKey(password, salt));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(jsonEncode(plainText), iv: iv);
    return Uint8List.fromList(iv.bytes + encrypted.bytes);
  });
}

/// Decrypts the [data] using the provided [password] and [salt].
///
/// This function assumes that the first 16 bytes of [data] are the IV,
/// and the rest is the AES-CBC encrypted payload.
///
/// If the [password] is empty, the data is assumed to be UTF-8 encoded JSON
/// and is decoded directly.
///
/// The decryption process is run in a separate Isolate.
Future<dynamic> decryptWithPassword(
  Uint8List data,
  String password,
  String salt,
) async {
  return Isolate.run(() {
    if (password.isEmpty) return jsonDecode(utf8.decode(data));

    final iv = encrypt.IV(data.sublist(0, 16));
    final cipherBytes = data.sublist(16);

    final key = encrypt.Key(deriveKey(password, salt));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final decrypted = encrypter.decrypt(encrypt.Encrypted(cipherBytes), iv: iv);
    return jsonDecode(decrypted);
  });
}
