class CourseOutcome {
  final String id;
  final String courseId;
  final String code;
  final String title;
  final String? description;
  final String? bloomDomain;
  final int? bloomLevel;
  final String? profileType;
  final String? profileCode;

  const CourseOutcome({
    required this.id, required this.courseId, required this.code, required this.title,
    this.description, this.bloomDomain, this.bloomLevel, this.profileType, this.profileCode,
  });

  factory CourseOutcome.fromJson(Map<String, dynamic> j) => CourseOutcome(
    id: j['id'], courseId: j['courseId'], code: j['code'], title: j['title'],
    description: j['description'], bloomDomain: j['bloomDomain'],
    bloomLevel: j['bloomLevel'], profileType: j['profileType'], profileCode: j['profileCode'],
  );
}

class MappingMatrix {
  final List<CourseOutcome> courseOutcomes;
  final List<Map<String, dynamic>> programOutcomes;
  final List<Map<String, dynamic>> mappings;

  const MappingMatrix({required this.courseOutcomes, required this.programOutcomes, required this.mappings});

  String? getCorrelation(String coId, String poId) {
    final mapping = mappings.where(
      (m) => m['courseOutcomeId'] == coId && m['programOutcomeId'] == poId
    ).firstOrNull;
    return mapping?['correlation'];
  }

  factory MappingMatrix.fromJson(Map<String, dynamic> j) => MappingMatrix(
    courseOutcomes: (j['courseOutcomes'] as List).map((e) => CourseOutcome.fromJson(e)).toList(),
    programOutcomes: List<Map<String, dynamic>>.from(j['programOutcomes']),
    mappings: List<Map<String, dynamic>>.from(j['mappings']),
  );
}

class Assessment {
  final String id;
  final String courseId;
  final String type;
  final String title;
  final double totalMarks;
  final double weight;
  final List<Map<String, dynamic>> assessmentCOs;

  const Assessment({
    required this.id, required this.courseId, required this.type,
    required this.title, required this.totalMarks, required this.weight,
    required this.assessmentCOs,
  });

  factory Assessment.fromJson(Map<String, dynamic> j) => Assessment(
    id: j['id'], courseId: j['courseId'], type: j['type'], title: j['title'],
    totalMarks: (j['totalMarks'] as num).toDouble(),
    weight: (j['weight'] as num).toDouble(),
    assessmentCOs: List<Map<String, dynamic>>.from(j['assessmentCOs'] ?? []),
  );
}

class AttainmentData {
  final List<Map<String, dynamic>> coAttainments;
  final List<Map<String, dynamic>> poAttainments;

  const AttainmentData({required this.coAttainments, required this.poAttainments});

  factory AttainmentData.fromJson(Map<String, dynamic> j) => AttainmentData(
    coAttainments: List<Map<String, dynamic>>.from(j['coAttainments']),
    poAttainments: List<Map<String, dynamic>>.from(j['poAttainments']),
  );
}
