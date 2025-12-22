import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Dependency_Injection/dependency_injection.dart';
import '../bloc/leave_status_bloc.dart';
import '../modal/leave_card_model.dart';

class LeaveCard extends StatelessWidget {
  final LeaveCardModel leave;
  // final VoidCallback onCancel;
  final VoidCallback onDeleteSuccess; // Callback for parent widget
  const LeaveCard(
      {super.key, required this.leave, required this.onDeleteSuccess});

  @override
  Widget build(BuildContext context) {
    int isPending = 2;
    if (leave.status == "Pending") {
      isPending = 1;
    } else {
      isPending = 0;
    }
    debugPrint("ispending :$isPending");
    final Color statusColor = leave.status == "Approved"
        ? Colors.green
        : leave.status == "Pending"
            ? Color(0xFFD76E71)
            : Colors.orange;

    final Color statusBgColor = statusColor.withOpacity(0.1);

    // String shortDate = leave.date.length > 10 ? leave.date.substring(0, 10) : leave.date;
    DateTime shortDate = DateTime.parse(leave.startDate);
    String monthName = DateFormat('MMMM').format(shortDate);
    double shortdays = leave.totalDays;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Expanded(
                child: Text(
                  leave.leaveTypeName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  overflow:
                      TextOverflow.ellipsis, // 👈 ensures text doesn't overflow
                  maxLines: 1, // 👈 keeps it in one line
                ),
              ),
              const SizedBox(
                  width: 12), // 👈 small space between text and status
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  leave.status,
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
              Text(
                shortdays >= 1
                    ? "${shortdays.toInt()} ${shortdays.toInt() == 1 ? "Day" : "Days"}"
                    : "${shortdays.toStringAsFixed(1)} Day",
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.circle, size: 6, color: Colors.grey),
              const SizedBox(width: 6),
              Text("$monthName ${shortDate.day}, ${shortDate.year} ",
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
              const SizedBox(width: 16),
            ],
          ),

          const SizedBox(height: 12),

          /// Reason
          const Text("Reason:",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            leave.reason,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),

          if (isPending == 0) SizedBox(),
          if (isPending == 1)
            Divider(
              color: Colors.grey,
              thickness: 1, // Line thickness
              height: 10, // Space above and below the line
            ),
          if (isPending == 1)
            TextButton(
              onPressed: () =>
                  _showDeleteConfirmation(context, leave.leaveApplicationId),
              child: const Text(
                "Cancel Request",
                style: TextStyle(
                  color: Color(0xFFD76E71),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int leaveApplicationId) {
    leaveApplicationId = leave.leaveApplicationId;
    debugPrint("leaveAppid : $leaveApplicationId");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content:
            const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              getIt<DeleteBloc>()
                  .add(DeleteItem(leaveApplicationId: leaveApplicationId));
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Color(0xFFD76E71)),
            ),
          ),
        ],
      ),
    );
  }
}
