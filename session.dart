import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Who is logged in. The token is kept in the phone's secure storage.
class Session extends ChangeNotifier {
  static const FlutterSecureStorage _store = FlutterSecureStorage();

  String? token;
  Map<String, dynamic>? user;

  String get role => (user?['role'] as String?) ?? '';
  bool get loggedIn => token != null && user != null;

  Future<void> load() async {
    token = await _store.read(key: 'token');
    final raw = await _store.read(key: 'user');
    user = raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
    if (token == null) user = null;
    notifyListeners();
  }

  Future<void> save(String newToken, Map<String, dynamic> newUser) async {
    token = newToken;
    user = newUser;
    await _store.write(key: 'token', value: newToken);
    await _store.write(key: 'user', value: jsonEncode(newUser));
    notifyListeners();
  }

  Future<void> clear() async {
    token = null;
    user = null;
    await _store.delete(key: 'token');
    await _store.delete(key: 'user');
    notifyListeners();
  }
}

final Session session = Session();
