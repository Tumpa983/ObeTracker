import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:obe_tracker/core/api/api_client.dart';
import 'package:obe_tracker/core/api/api_result.dart';
import '../models/faculty_models.dart';
import 'package:obe_tracker/features/admin/models/admin_models.dart';

final _client = ApiClient();

// Faculty's assigned courses (reusing admin course model)
final facultyCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final res = await _client.get('/faculty/courses');
  return (res.data['data'] as List).map((j) => Course.fromJson(j)).toList();
});

// Course Outcomes
final courseOutcomesProvider =
    FutureProvider.family<List<CourseOutcome>, String>((ref, courseId) async {
  final res = await _client.get('/faculty/courses/$courseId/outcomes');
  return (res.data['data'] as List).map((j) => CourseOutcome.fromJson(j)).toList();
});

// CO-PO Mapping Matrix
final mappingProvider =
    FutureProvider.family<MappingMatrix, String>((ref, courseId) async {
  final res = await _client.get('/faculty/courses/$courseId/mapping');
  return MappingMatrix.fromJson(res.data['data']);
});

// Assessments
final assessmentsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, courseId) async {
  final res = await _client.get('/faculty/courses/$courseId/assessments');
  return res.data['data'];
});

// Marks
final marksProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, assessmentId) async {
  final res = await _client.get('/faculty/assessments/$assessmentId/marks');
  return List<Map<String, dynamic>>.from(res.data['data']);
});

// Attainment
final courseAttainmentProvider =
    FutureProvider.family<AttainmentData, String>((ref, courseId) async {
  final res = await _client.get('/faculty/courses/$courseId/attainment');
  return AttainmentData.fromJson(res.data['data']);
});

class FacultyActions {
  static Future<ApiResult<void>> createCO(
      String courseId, Map<String, dynamic> data) async {
    try {
      await _client.post('/faculty/courses/$courseId/outcomes', data: data);
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> deleteCO(String courseId, String coId) async {
    try {
      await _client.delete('/faculty/courses/$courseId/outcomes/$coId');
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> saveMapping(
      String courseId, List<Map<String, dynamic>> mappings) async {
    try {
      final res = await _client.post('/faculty/courses/$courseId/mapping',
          data: {'mappings': mappings});
      return ApiResult.success(res.data['data']);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> createAssessment(
      String courseId, Map<String, dynamic> data) async {
    try {
      await _client.post('/faculty/courses/$courseId/assessments', data: data);
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }

  static Future<ApiResult<void>> saveMarks(
      String assessmentId, List<Map<String, dynamic>> marks) async {
    try {
      await _client.post('/faculty/assessments/$assessmentId/marks',
          data: {'marks': marks});
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(parseApiError(e));
    }
  }
}
