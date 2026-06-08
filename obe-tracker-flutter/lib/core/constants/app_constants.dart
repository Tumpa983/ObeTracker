class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'http://localhost:3000/api/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // OBE
  static const Map<String, String> correlationLabels = {
    'WEAK': '1 – Weak',
    'MODERATE': '2 – Moderate',
    'STRONG': '3 – Strong',
  };

  static const Map<String, String> attainmentLevelLabels = {
    'L0': 'Not Attained',
    'L1': 'Partially Attained',
    'L2': 'Moderately Attained',
    'L3': 'Fully Attained',
  };

  static const Map<String, String> bloomDomainLabels = {
    'COGNITIVE': 'Cognitive (C)',
    'AFFECTIVE': 'Affective (A)',
    'PSYCHOMOTOR': 'Psychomotor (P)',
  };

  static const Map<String, String> profileTypeLabels = {
    'FUNDAMENTAL': 'Fundamental',
    'SOCIAL': 'Social',
    'THINKING': 'Thinking',
    'PERSONAL': 'Personal',
  };

  static const List<String> assessmentTypes = [
    'QUIZ', 'ASSIGNMENT', 'MID_TERM', 'FINAL',
    'LAB', 'PROJECT', 'PRESENTATION', 'OTHER',
  ];
}
