import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/api/api_result.dart';
import '../models/admin_models.dart';

final _client = ApiClient();

// ── Dashboard ─────────────────────────────────────────────────
final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final res = await _client.get('/admin/dashboard');
  return DashboardStats.fromJson(res.data['data']);
});

// ── Departments ───────────────────────────────────────────────
final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  final res = await _client.get('/admin/departments');
  return (res.data['data'] as List).map((j) => Department.fromJson(j)).toList();
});

// ── Programs ──────────────────────────────────────────────────
final programsProvider = FutureProvider<List<Program>>((ref) async {
  final res = await _client.get('/admin/programs');
  return (res.data['data'] as List).map((j) => Program.fromJson(j)).toList();
});

// ── Sessions ──────────────────────────────────────────────────
final sessionsProvider = FutureProvider<List<AcademicSession>>((ref) async {
  final res = await _client.get('/admin/sessions');
  return (res.data['data'] as List).map((j) => AcademicSession.fromJson(j)).toList();
});

// ── Courses ───────────────────────────────────────────────────
final coursesProvider = FutureProvider.family<List<Course>, Map<String, String>?>(
    (ref, filters) async {
  final res = await _client.get('/admin/courses', queryParameters: filters);
  return (res.data['data'] as List).map((j) => Course.fromJson(j)).toList();
});

// ── Users ─────────────────────────────────────────────────────
final usersProvider = FutureProvider.family<List<AppUser>, Map<String, String>?>(
    (ref, filters) async {
  final res = await _client.get('/admin/users', queryParameters: filters);
  return (res.data['data'] as List).map((j) => AppUser.fromJson(j)).toList();
});

// ── Program Outcomes ──────────────────────────────────────────
final programOutcomesProvider =
    FutureProvider.family<List<ProgramOutcome>, String>((ref, programId) async {
  final res = await _client.get('/admin/programs/$programId/outcomes');
  return (res.data['data'] as List).map((j) => ProgramOutcome.fromJson(j)).toList();
});

// ── Thresholds ────────────────────────────────────────────────
final thresholdsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await _client.get('/admin/thresholds');
  return res.data['data'] as Map<String, dynamic>;
});

// ── Admin Actions ─────────────────────────────────────────────
class AdminActions {
  static Future<ApiResult<void>> createDepartment(String name, String code) async {
    try {
      await _client.post('/admin/departments', data: {'name': name, 'code': code});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> createProgram(
      String departmentId, String name, String code) async {
    try {
      await _client.post('/admin/programs',
          data: {'departmentId': departmentId, 'name': name, 'code': code});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> createSession(
      String name, String startDate) async {
    try {
      await _client.post('/admin/sessions',
          data: {'name': name, 'startDate': startDate});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> createCourse(
      String programId, String sessionId, String name, String code, int creditHours) async {
    try {
      await _client.post('/admin/courses', data: {
        'programId': programId, 'sessionId': sessionId,
        'name': name, 'code': code, 'creditHours': creditHours,
      });
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> deleteCourse(String courseId) async {
    try {
      await _client.delete('/admin/courses/$courseId');
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> createUser(Map<String, dynamic> data) async {
    try {
      await _client.post('/admin/users', data: data);
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> createProgramOutcome(
      String programId, String code, String title, String? description) async {
    try {
      await _client.post('/admin/programs/$programId/outcomes',
          data: {'code': code, 'title': title, 'description': description});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> updateProgramOutcome(
      String id, String code, String title, String? description) async {
    try {
      await _client.put('/admin/outcomes/$id',
          data: {'code': code, 'title': title, 'description': description});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> deleteProgramOutcome(String id) async {
    try {
      await _client.delete('/admin/outcomes/$id');
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> assignFaculty(
      String courseId, List<String> facultyIds) async {
    try {
      await _client.put('/admin/courses/$courseId/faculty',
          data: {'facultyIds': facultyIds});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> updateUserStatus(
      String userId, bool isActive) async {
    try {
      await _client.put('/admin/users/$userId', data: {'isActive': isActive});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> upsertThresholds(
      double l3Min, double l2Min, double l1Min) async {
    try {
      await _client.put('/admin/thresholds',
          data: {'l3Min': l3Min, 'l2Min': l2Min, 'l1Min': l1Min});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }
}
