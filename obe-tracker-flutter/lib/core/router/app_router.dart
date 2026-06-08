import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obe_tracker/features/auth/providers/auth_provider.dart';
import 'package:obe_tracker/features/auth/screens/login_screen.dart';
import 'package:obe_tracker/features/auth/screens/forgot_password_screen.dart';
import 'package:obe_tracker/features/admin/screens/admin_dashboard_screen.dart';
import 'package:obe_tracker/features/admin/screens/admin_structure_screen.dart';
import 'package:obe_tracker/features/admin/screens/admin_courses_screen.dart';
import 'package:obe_tracker/features/admin/screens/admin_users_screen.dart';
import 'package:obe_tracker/features/admin/screens/admin_outcomes_screen.dart';
import 'package:obe_tracker/features/faculty/screens/faculty_dashboard_screen.dart';
import 'package:obe_tracker/features/faculty/screens/course_detail_screen.dart';
import 'package:obe_tracker/features/faculty/screens/marks_entry_screen.dart';
import 'package:obe_tracker/features/faculty/screens/faculty_reports_screen.dart';
import 'package:obe_tracker/features/student/screens/student_dashboard_screen.dart';
import 'package:obe_tracker/features/student/screens/student_course_screen.dart';
import 'package:obe_tracker/features/student/screens/student_attainment_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isOnAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/forgot-password');
      if (!isAuth && !isOnAuth) return '/login';
      if (isAuth && isOnAuth) {
        final role = authState.user!.role.toLowerCase();
        return '/$role/dashboard';
      }
      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ── Admin ─────────────────────────────────────────────
      GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/structure', builder: (_, __) => const AdminStructureScreen()),
      GoRoute(path: '/admin/courses', builder: (_, __) => const AdminCoursesScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/outcomes', builder: (_, __) => const AdminOutcomesScreen()),

      // ── Faculty ───────────────────────────────────────────
      GoRoute(path: '/faculty/dashboard', builder: (_, __) => const FacultyDashboardScreen()),
      GoRoute(path: '/faculty/courses', builder: (_, __) => const FacultyDashboardScreen()),
      GoRoute(
        path: '/faculty/courses/:courseId',
        builder: (_, state) =>
            CourseDetailScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/faculty/courses/:courseId/assessments/:assessmentId/marks',
        builder: (_, state) => MarksEntryScreen(
          courseId: state.pathParameters['courseId']!,
          assessmentId: state.pathParameters['assessmentId']!,
        ),
      ),
      GoRoute(path: '/faculty/reports', builder: (_, __) => const FacultyReportsScreen()),

      // ── Student ───────────────────────────────────────────
      GoRoute(path: '/student/dashboard', builder: (_, __) => const StudentDashboardScreen()),
      GoRoute(path: '/student/courses', builder: (_, __) => const StudentDashboardScreen()),
      GoRoute(
        path: '/student/courses/:courseId',
        builder: (_, state) =>
            StudentCourseScreen(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(path: '/student/attainment', builder: (_, __) => const StudentAttainmentScreen()),
    ],
  );
});
