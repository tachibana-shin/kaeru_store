
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaeru_store/encrypt.dart';

void main() {
  group('encryption tests', () {
    const password = 'test_password';
    const salt = 'test_salt';
    const plainText = {'message': 'hello world'};

    test('deriveKey generates a key of the correct length', () {
      final key = deriveKey(password, salt, length: 32);
      expect(key, isA<Uint8List>());
      expect(key.length, 32);
    });

    test('encrypt and decrypt with password', () async {
      final encrypted = await encryptWithPassword(plainText, password, salt);
      final decrypted = await decryptWithPassword(encrypted, password, salt);
      expect(decrypted, equals(plainText));
    });

    test('decryption with wrong password fails', () async {
      final encrypted = await encryptWithPassword(plainText, password, salt);
      expect(
        () async => await decryptWithPassword(encrypted, 'wrong_password', salt),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('encryption/decryption with empty password', () async {
      final encrypted = await encryptWithPassword(plainText, '', salt);
      final decrypted = await decryptWithPassword(encrypted, '', salt);
      expect(decrypted, equals(plainText));
    });

    test('encrypt and decrypt with different data types', () async {
      const testData = [
        'a simple string',
        12345,
        3.14159,
        true,
        ['list', 'of', 'strings'],
        {'key': 'value', 'nested': {'a': 1}},
      ];

      for (final data in testData) {
        final encrypted = await encryptWithPassword(data, password, salt);
        final decrypted = await decryptWithPassword(encrypted, password, salt);
        expect(decrypted, equals(data));
      }
    }, timeout: Timeout(Duration(minutes: 2)));
  });
}
