class UserProfile {
  final int employeeId;
  final String employeeCode;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String gender;
  final String? email;
  final String? mobileNumber;
  final String? currentAddress;
  final String? pincode;
  final String employmentType;
  final String employmentStatus;
  final String? imagePath;
  final String? joiningDate;
  final String role;
  final String department;
  final String? managerName;
  final String? checkInTime;
  final String? checkOutTime;

  UserProfile({
    required this.employeeId,
    required this.employeeCode,
    required this.firstName,
    this.middleName,
    this.lastName,
    required this.gender,
    this.email,
    this.mobileNumber,
    this.currentAddress,
    this.pincode,
    required this.employmentType,
    required this.employmentStatus,
    this.imagePath,
    this.joiningDate,
    required this.role,
    required this.department,
    this.managerName,
    this.checkInTime,
    this.checkOutTime,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    print('Parsing UserProfile: $json');
    final firstName = json['first_name'];
    print('First Name in JSON: $firstName');

    String? nullableString(dynamic value) {
      if (value == null) return null;
      if (value is String && value.isEmpty) return null;
      return value.toString();
    }

    return UserProfile(
      employeeId: json['employee_id'] ?? 0,
      employeeCode: json['employee_code'] ?? '',
      firstName: nullableString(json['first_name']),
      middleName: nullableString(json['middle_name']),
      lastName: nullableString(json['last_name']),
      gender: json['gender'] ?? '',
      email: nullableString(json['email']),
      mobileNumber: nullableString(json['mobile_number']),
      currentAddress: nullableString(json['current_address']),
      pincode: nullableString(json['pincode']),
      employmentType: json['employment_type'] ?? '',
      employmentStatus: json['employment_status'] ?? '',
      imagePath: nullableString(json['image_path']),
      joiningDate: nullableString(json['joining_date']),
      role: (json['latest_history']?['designation']?['designation_name'])
              ?.toString() ??
          '',
      department: (json['latest_history']?['department']?['department_name'])
              ?.toString() ??
          '',
      managerName:
          (json['latest_history']?['report']?['first_name'])?.toString(),
    );
  }
}
