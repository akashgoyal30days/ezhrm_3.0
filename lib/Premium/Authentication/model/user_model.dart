class AppUser {
  final String id;
  final String token;
  final String name;
  final String email;
  final String imageUrl;
  final int gpsLocation;
  final int faceRecognition;
  final int autoAttendance;
  final int requestAttendance;

  AppUser({
    required this.id,
    required this.token,
    this.name = '',
    this.imageUrl = '',
    this.email = '',
    this.gpsLocation = 0,
    this.faceRecognition = 0,
    this.autoAttendance = 0,
    this.requestAttendance = 0,
  });

  /// Parse from login API response (auth only)
  factory AppUser.fromLoginResponse(Map<String, dynamic> json) {
    final userJson = json['data']['user'] ?? {};
    return AppUser(
      id: (userJson['employee_id'] ?? '')
          .toString(), // Ensure string, handle null
      token: json['data']['token'] ?? '',
    );
  }

  factory AppUser.fromGoogleResponse(Map<String, dynamic> json) {
    final userJson = json['user'] ?? {};
    return AppUser(
      id: (userJson['employee_id'] ?? '')
          .toString(), // Ensure string, handle null
      token: json['token'] ?? '',
    );
  }

  /// Update name & image after profile API
  AppUser copyWithProfile(Map<String, dynamic> profileJson) {
    return copyWith(
      name:
          '${profileJson['first_name'] ?? ''} ${profileJson['middle_name'] ?? ''} ${profileJson['last_name'] ?? ''}'
              .trim(),
      imageUrl: profileJson['image_path'] ?? '',
      email: profileJson['email'],
    );
  }

  /// Update permissions after permission API
  AppUser copyWithPermissions(Map<String, dynamic> permissionJson) {
    return copyWith(
      gpsLocation:
          int.tryParse(permissionJson['is_gps_location'].toString()) ?? 0,
      faceRecognition:
          int.tryParse(permissionJson['is_face_recognition'].toString()) ?? 0,
      autoAttendance:
          int.tryParse(permissionJson['is_auto_attendance'].toString()) ?? 0,
      requestAttendance:
          int.tryParse(permissionJson['is_req_attendance'].toString()) ?? 0,
    );
  }

  /// Deserialize from local storage
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      token: json['token'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      gpsLocation: int.tryParse(json['gpsLocation'].toString()) ?? 0,
      faceRecognition: int.tryParse(json['faceRecognition'].toString()) ?? 0,
      autoAttendance: int.tryParse(json['autoAttendance'].toString()) ?? 0,
      requestAttendance:
          int.tryParse(json['requestAttendance'].toString()) ?? 0,
    );
  }

  /// General copyWith
  AppUser copyWith({
    String? id,
    String? token,
    int? roleId,
    String? name,
    String? email,
    String? imageUrl,
    int? gpsLocation,
    int? faceRecognition,
    int? autoAttendance,
    int? requestAttendance,
  }) {
    return AppUser(
      id: id ?? this.id,
      token: token ?? this.token,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      gpsLocation: gpsLocation ?? this.gpsLocation,
      faceRecognition: faceRecognition ?? this.faceRecognition,
      autoAttendance: autoAttendance ?? this.autoAttendance,
      requestAttendance: requestAttendance ?? this.requestAttendance,
    );
  }
}
