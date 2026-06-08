import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:obe_tracker/core/theme/app_theme.dart';
import '../providers/faculty_providers.dart';
import 'co_management_screen.dart';
import 'mapping_matrix_screen.dart';
import 'assessments_screen.dart';
import 'attainment_screen.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(facultyCoursesProvider);
    final course = coursesAsync.value?.where((c) => c.id == widget.courseId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/faculty/courses'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course?.name ?? 'Course', style: const TextStyle(fontSize: 16)),
            if (course != null)
              Text('${course.code} · ${course.session?['name'] ?? ''}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.track_changes_outlined, size: 18), text: 'Outcomes'),
            Tab(icon: Icon(Icons.grid_on_outlined, size: 18), text: 'CO-PO Map'),
            Tab(icon: Icon(Icons.assignment_outlined, size: 18), text: 'Assessments'),
            Tab(icon: Icon(Icons.bar_chart_outlined, size: 18), text: 'Attainment'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          CoManagementScreen(courseId: widget.courseId),
          MappingMatrixScreen(courseId: widget.courseId),
          AssessmentsScreen(courseId: widget.courseId),
          AttainmentScreen(courseId: widget.courseId),
        ],
      ),
    );
  }
}
