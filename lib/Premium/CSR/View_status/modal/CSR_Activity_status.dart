class Activity {
  final int timelineId;
  final String activityImage;
  final String description;
  final String? status;
  final DateTime createdAt;
  final Employee employee;
  final dynamic approver; // Can be null or another Employee-like object

  Activity({
    required this.timelineId,
    required this.activityImage,
    required this.description,
    this.status,
    required this.createdAt,
    required this.employee,
    this.approver,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      timelineId: json['timeline_id'] ?? 0,
      activityImage: json['activity'] ?? '',
      description: json['description'] ?? '',
      status: json['status'],
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      employee: Employee.fromJson(json['employee'] ?? {}),
      approver:
          json['approver'] != null ? Employee.fromJson(json['approver']) : null,
    );
  }
}

class Employee {
  final int employeeId;
  final String? employeeCode;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? gender;
  final String? dateOfBirth;
  final String? imagePath;

  Employee({
    required this.employeeId,
    this.employeeCode,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.gender,
    this.dateOfBirth,
    this.imagePath,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeId: json['employee_id'] ?? 0,
      employeeCode: json['employee_code'],
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      imagePath: json['image_path'],
    );
  }
}
