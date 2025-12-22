import 'package:flutter/material.dart';

class HolidayCard extends StatelessWidget {
  final String title;
  final String date;
  final Color backgroundColor;
  final Color textColor;

  const HolidayCard({
    super.key,
    required this.title,
    required this.date,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    print("date:$date");
    return Container(
      // The fixed height and SingleChildScrollView are removed to allow for dynamic height
      margin: const EdgeInsets.only(top: 4.0), // Adjust margin as needed
      padding: const EdgeInsets.all(20), // Increased padding for better spacing
      decoration: BoxDecoration(
        color: backgroundColor, // Use the passed background color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min, // Make column take minimum vertical space
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: textColor, // Use the passed text color
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12), // Adjusted spacing
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87, // Slightly softer black
            ),
          ),
        ],
      ),
    );
  }
}
