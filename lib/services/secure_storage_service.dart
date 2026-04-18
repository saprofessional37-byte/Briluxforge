// lib/services/secure_storage_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

/// The ONLY class that touches flutter_secure_storage.
/// No other file in the codebase may import flutter_secure_storage directly.
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: _androidOptions,
        );

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const LinuxOptions _linuxOptions = LinuxOptions();

  final FlutterSecureStorage _storage;

  Future<void> storeKey(String provider, String key) async {
    await _storage.write(key: 'api_key_$provider', value: key);
  }

  Future<String?> readKey(String provider) async {
    return _storage.read(key: 'api_key_$provider');
  }

  Future<void> deleteKey(String provider) async {
    await _storage.delete(key: 'api_key_$provider');
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

@riverpod
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService();
}
