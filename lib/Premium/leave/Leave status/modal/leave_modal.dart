class LeaveQuota {
  final int quotaid;
  final String leaveTypeName;

  LeaveQuota({required this.quotaid, required this.leaveTypeName});

  factory LeaveQuota.fromJson(Map<String, dynamic> json) {
    return LeaveQuota(
      quotaid: parseQuotaId(json['leave_quota_id']),
      leaveTypeName: json['leave_type_name']?.toString() ?? 'Unknown Leave',
    );
  }

  static int parseQuotaId(dynamic id) {
    if (id == null) return -1;
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? -1;
    return -1; // fallback for invalid types
  }
}
