class AdvanceSalaryCardModal {
  final int advanceSalaryId;
  final int advanceAmount;
  final String status;
  final int month;
  final int year;

  AdvanceSalaryCardModal({
    required this.advanceSalaryId,
    required this.status,
    required this.advanceAmount,
    required this.month,
    required this.year,
  });

  factory AdvanceSalaryCardModal.fromJson(Map<String, dynamic> json) {
    return AdvanceSalaryCardModal(
      advanceSalaryId: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      advanceAmount: json['advance_amount'] == null
          ? 0
          : int.tryParse(json['advance_amount'].toString().split(".").first) ??
              0,
      status: json['status']?.toString() ?? "Pending",
      month: json['month'] == null
          ? DateTime.now().month
          : int.tryParse(json['month'].toString()) ?? DateTime.now().month,
      year: json['year'] == null
          ? DateTime.now().year
          : int.tryParse(json['year'].toString()) ?? DateTime.now().year,
    );
  }
}
