import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../exam/data/models/exam_result_model.dart';
import '../models/user_model.dart';

class AccountApiService {
  static const _tokenKey = 'exam_assistant_access_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;
  final StreamController<UserModel?> _authChanges =
      StreamController<UserModel?>.broadcast(sync: true);

  String? _accessToken;
  UserModel? _currentUser;
  Future<void>? _restoreFuture;

  AccountApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  UserModel? get currentUser => _currentUser;

  Stream<UserModel?> get authStateChanges async* {
    await _restoreSession();
    yield _currentUser;
    yield* _authChanges.stream;
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return _authenticate('/v1/auth/login', email: email, password: password);
  }

  Future<UserModel> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    return _authenticate(
      '/v1/auth/register',
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
  }

  Future<UserModel> _authenticate(
    String path, {
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    final response = _object(
      await _request(
        'POST',
        path,
        body: {
          'email': email.trim(),
          'password': password,
          if (name != null) 'name': name.trim(),
          if (phone != null) 'phone': phone.trim(),
        },
        authenticated: false,
      ),
    );
    final token = response['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('The API did not return an access token.');
    }

    final userData = response['user'];
    if (userData is! Map) {
      throw const FormatException('The API did not return an account.');
    }
    final user = UserModel.fromJson(Map<String, dynamic>.from(userData));
    await _storage.write(key: _tokenKey, value: token);
    _accessToken = token;
    _currentUser = user;
    _authChanges.add(user);
    return user;
  }

  Future<void> _restoreSession() {
    return _restoreFuture ??= _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    _accessToken = await _storage.read(key: _tokenKey);
    if (_accessToken == null || _accessToken!.isEmpty) return;

    try {
      _currentUser = await getProfile();
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      await _clearSession();
    }
  }

  Future<void> signOut() async {
    final token = await _getAccessToken();
    await _clearSession();
    if (token != null) {
      await _request(
        'POST',
        '/v1/auth/logout',
        authenticated: true,
        tokenOverride: token,
      );
    }
  }

  Future<UserModel> createTestUser() async {
    final response = await _request(
      'POST',
      '/v1/debug/test-user',
      body: const {},
      authenticated: false,
    );
    return UserModel.fromJson(_object(response));
  }

  Future<UserModel> getProfile() async {
    final response = await _request('GET', '/v1/users/me');
    return UserModel.fromJson(_object(response));
  }

  Future<UserModel> updateProfile({
    required String name,
    required String phone,
  }) async {
    final response = await _request(
      'PUT',
      '/v1/users/me',
      body: {'name': name, 'phone': phone},
    );
    final user = UserModel.fromJson(_object(response));
    _currentUser = user;
    _authChanges.add(user);
    return user;
  }

  Future<List<UserModel>> getLeaderboard() async {
    final response = await _request('GET', '/v1/users/leaderboard');
    if (response is! List) {
      throw const FormatException('Expected a leaderboard list response.');
    }
    return response
        .map(
          (item) => UserModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<List<ExamResultModel>> getExamResults() async {
    final response = await _request('GET', '/v1/users/me/results');
    if (response is! List) {
      throw const FormatException('Expected an exam history list response.');
    }
    return response
        .map(
          (item) =>
              ExamResultModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  /// Returns the server's graded result (score, rank, and whether answers
  /// may be revealed yet) as raw JSON.
  Future<Map<String, dynamic>> submitExamResult({
    required String examId,
    required Map<String, String> answers,
    Map<String, int>? timeSpentMs,
  }) async {
    final response = await _request(
      'POST',
      '/v1/exams/${Uri.encodeComponent(examId)}/results',
      body: {
        'answers': answers,
        if (timeSpentMs != null && timeSpentMs.isNotEmpty)
          'timeSpentMs': timeSpentMs,
      },
    );
    return _object(response);
  }

  Future<dynamic> getApiJson(String path, {Map<String, String>? query}) async {
    return _request('GET', path, query: query);
  }

  Future<dynamic> postApiJson(String path, Map<String, dynamic> body) async {
    return _request('POST', path, body: body);
  }

  Future<dynamic> putApiJson(String path, Map<String, dynamic> body) async {
    return _request('PUT', path, body: body);
  }

  Future<dynamic> deleteApiJson(String path) async {
    return _request('DELETE', path);
  }

  Future<String?> _getAccessToken() async {
    _accessToken ??= await _storage.read(key: _tokenKey);
    return _accessToken;
  }

  Future<void> _clearSession() async {
    try {
      await _storage.delete(key: _tokenKey);
    } finally {
      _accessToken = null;
      _currentUser = null;
      _authChanges.add(null);
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
    String? tokenOverride,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated) {
      final token = tokenOverride ?? await _getAccessToken();
      if (token == null || token.isEmpty) {
        throw StateError('Sign in to access your account.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final baseUrl = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    if (body != null) headers['Content-Type'] = 'application/json';
    final encodedBody = body == null ? null : jsonEncode(body);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encodedBody),
      'PUT' => await _client.put(uri, headers: headers, body: encodedBody),
      'DELETE' => await _client.delete(uri, headers: headers),
      _ => throw ArgumentError.value(
        method,
        'method',
        'Unsupported HTTP method',
      ),
    };

    if (response.statusCode == 204 || response.body.isEmpty) return null;

    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw const FormatException('The API returned invalid JSON.');
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map && payload['error'] is String
          ? payload['error'] as String
          : 'API request failed (${response.statusCode}).';
      if (response.statusCode == 401 &&
          authenticated &&
          tokenOverride == null) {
        await _clearSession();
      }
      throw ApiException(response.statusCode, message);
    }
    return payload;
  }

  Map<String, dynamic> _object(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Expected an API object response.');
    }
    return Map<String, dynamic>.from(json);
  }

  Future<void> dispose() async {
    await _authChanges.close();
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
