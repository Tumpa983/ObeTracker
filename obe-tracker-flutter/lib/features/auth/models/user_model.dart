class UserModel {
  final String id;
  final String email;
  final String role;
  final String firstName;
  final String lastName;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'],
        role: json['role'],
        firstName: json['firstName'],
        lastName: json['lastName'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'firstName': firstName,
        'lastName': lastName,
      };
}
