class Department {
  final String id;
  final String name;
  final String code;
  final bool isActive;

  const Department({required this.id, required this.name, required this.code, required this.isActive});

  factory Department.fromJson(Map<String, dynamic> j) => Department(
        id: j['id'], name: j['name'], code: j['code'], isActive: j['isActive'] ?? true);
}

class Program {
  final String id;
  final String departmentId;
  final String name;
  final String code;

  const Program({required this.id, required this.departmentId, required this.name, required this.code});

  factory Program.fromJson(Map<String, dynamic> j) => Program(
        id: j['id'], departmentId: j['departmentId'], name: j['name'], code: j['code']);
}

class AcademicSession {
  final String id;
  final String name;
  final String status;
  final String startDate;

  const AcademicSession({required this.id, required this.name, required this.status, required this.startDate});

  factory AcademicSession.fromJson(Map<String, dynamic> j) => AcademicSession(
        id: j['id'], name: j['name'], status: j['status'], startDate: j['startDate'] ?? '');
}

class Course {
  final String id;
  final String name;
  final String code;
  final String programId;
  final String sessionId;
  final int creditHours;
  final Map<String, dynamic>? program;
  final Map<String, dynamic>? session;
  final List<Map<String, dynamic>> assignments;

  const Course({
    required this.id, required this.name, required this.code,
    required this.programId, required this.sessionId, required this.creditHours,
    this.program, this.session, this.assignments = const [],
  });

  /// IDs of currently assigned faculty
  List<String> get assignedFacultyIds => assignments
      .map((a) => a['faculty']?['id'] as String?)
      .whereType<String>()
      .toList();

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'], name: j['name'], code: j['code'],
        programId: j['programId'], sessionId: j['sessionId'],
        creditHours: j['creditHours'] ?? 3,
        program: j['program'], session: j['session'],
        assignments: List<Map<String, dynamic>>.from(j['assignments'] ?? []));
}

class AppUser {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;
  final bool isActive;
  final String? institutionalId;
  final String? lastLoginAt;

  const AppUser({
    required this.id, required this.email, required this.role,
    required this.firstName, required this.lastName, required this.isActive,
    this.institutionalId, this.lastLoginAt,
  });

  String get fullName => '$firstName $lastName';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'], email: j['email'], role: j['role'],
        firstName: j['firstName'], lastName: j['lastName'],
        isActive: j['isActive'] ?? true,
        institutionalId: j['institutionalId'],
        lastLoginAt: j['lastLoginAt']);
}

class ProgramOutcome {
  final String id;
  final String programId;
  final String code;
  final String title;
  final String? description;

  const ProgramOutcome({
    required this.id, required this.programId, required this.code,
    required this.title, this.description,
  });

  factory ProgramOutcome.fromJson(Map<String, dynamic> j) => ProgramOutcome(
        id: j['id'], programId: j['programId'], code: j['code'],
        title: j['title'], description: j['description']);
}

class DashboardStats {
  final int deptCount;
  final int programCount;
  final int courseCount;
  final int userCount;

  const DashboardStats({
    required this.deptCount, required this.programCount,
    required this.courseCount, required this.userCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        deptCount: j['deptCount'], programCount: j['programCount'],
        courseCount: j['courseCount'], userCount: j['userCount']);
}
