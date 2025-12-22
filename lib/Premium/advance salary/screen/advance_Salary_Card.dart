import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:intl/intl.dart';
import '../modal/advance_salary_card_modal.dart';

class AdvanceSalaryCard extends StatelessWidget {
  final AdvanceSalaryCardModal salary;
  const AdvanceSalaryCard({super.key, required this.salary});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status
    final Color statusColor;
    switch (salary.status.toLowerCase()) {
      case "approved":
        statusColor = Colors.green;
        break;
      case "pending":
        statusColor = const Color(0xFFD76E71);
        break;
      default:
        statusColor = Colors.orange;
    }

    final Color statusBgColor = statusColor.withOpacity(0.1);
    final String monthName =
        DateFormat.MMMM().format(DateTime(0, salary.month));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title + Status Row
          Row(
            children: [
              // Using Expanded ensures the title takes available space and prevents overflow
              Expanded(
                child: Text(
                  "Advance Salary Request",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              // Status chip will not cause overflow as it has intrinsic size
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  salary.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// From date & Days
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Colors.black54),
              const SizedBox(width: 8),
              // Using Flexible to allow text to wrap if needed on very small screens
              Flexible(
                child: Text(
                  "$monthName ${salary.year}",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Dash(
            direction: Axis.horizontal,
            dashLength: 6,
            dashColor: Colors.grey,
          ),

          const SizedBox(height: 12),

          /// Reason
          // This large text will wrap automatically if it doesn't fit
          Text("₹ ${salary.advanceAmount}",
              style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF0F3E6B),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
