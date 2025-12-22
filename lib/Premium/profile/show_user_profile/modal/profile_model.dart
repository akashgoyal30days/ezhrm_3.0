class ProfileModel {
  final String name;
  final String email;
  final String employeeId;
  final String designation;
  final String start_time;
  final String end_time;
  final String phone_number;
  final String reporting_to;
  final String joinDate;
  final String dob;
  final String? profileImageUrl;
  final String alternate_phone_number;

  ProfileModel({
    required this.name,
    required this.email,
    required this.designation,
    required this.start_time,
    required this.end_time,
    required this.employeeId,
    required this.phone_number,
    required this.reporting_to,
    required this.joinDate,
    required this.dob,
    this.profileImageUrl,
    required this.alternate_phone_number,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // Safely access nested objects
    final latestHistory = json['latest_history'] as Map<String, dynamic>? ?? {};
    final designationData =
        latestHistory['designation'] as Map<String, dynamic>? ?? {};
    final shiftData = latestHistory['shift'] as Map<String, dynamic>? ?? {};
    final reportData = latestHistory['report'] as Map<String, dynamic>? ?? {};

    String firstName = json['first_name']?.toString() ?? 'N/A';
    String lastName = json['last_name']?.toString() ?? 'N/A';

    // Concatenate names, handling cases where one or both might be 'N/A'
    String fullName;
    if (firstName != 'N/A' && lastName != 'N/A') {
      fullName = '$firstName $lastName';
    } else if (firstName != 'N/A') {
      fullName = firstName;
    } else if (lastName != 'N/A') {
      fullName = lastName;
    } else {
      fullName = 'N/A';
    }

    return ProfileModel(
      name: fullName,
      email: json['email']?.toString() ?? 'N/A',
      designation: designationData['designation_name']?.toString() ?? 'N/A',
      start_time: shiftData['start_time']?.toString() ?? 'N/A',
      end_time: shiftData['end_time']?.toString() ?? 'N/A',
      employeeId: json['employee_code']?.toString() ?? 'N/A',
      phone_number: json['mobile_number']?.toString() ?? 'N/A',
      reporting_to: reportData['first_name']?.toString() ?? 'N/A',
      joinDate: json['joining_date']?.toString() ?? 'N/A',
      dob: json['date_of_birth']?.toString() ?? 'N/A',
      profileImageUrl: json['image_path']?.toString(),
      alternate_phone_number:
          json['emergency_contact_number']?.toString() ?? 'N/A',
    );
  }
}
