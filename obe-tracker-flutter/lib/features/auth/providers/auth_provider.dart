import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/api/api_result.dart';
import 'package:obe_tracker/core/constants/app_constants.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool clearUser = false}) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _client = ApiClient();
  final _storage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (token != null && userJson != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userJson));
        state = AuthState(user: user);
      } catch (_) {
        await _storage.deleteAll();
      }
    }
  }

  Future<ApiResult<UserModel>> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _client.post('/auth/login', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      final data = response.data['data'];
      final user = UserModel.fromJson(data['user']);
      await _client.saveToken(data['token']);
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));
      state = AuthState(user: user);
      return ApiResult.success(user);
    } catch (e) {
      final msg = parseApiError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return ApiResult.failure(msg);
    }
  }

  Future<ApiResult<void>> forgotPassword(String email) async {
    try {
      await _client.post('/auth/forgot-password',
          data: {'email': email.trim().toLowerCase()});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  Future<ApiResult<void>> resetPassword(
      String email, String otp, String newPassword) async {
    try {
      await _client.post('/auth/reset-password', data: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      });
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {}
    await _client.clearToken();
    await _storage.delete(key: AppConstants.userKey);
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
