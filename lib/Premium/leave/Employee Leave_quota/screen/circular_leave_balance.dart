import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CircularLeaveBalance extends StatelessWidget {
  final num balance;
  final num total;

  const CircularLeaveBalance(
      {super.key, required this.balance, required this.total});

  @override
  Widget build(BuildContext context) {
    double percent;
    if (total <= 0) {
      percent = 0.0;
    } else {
      percent = (balance / total).clamp(0.0, 1.0);
    }

    // 1. Wrap with a Container to create the circular background.
    return Container(
      width: 180,
      height: 180,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: CircularPercentIndicator(
        radius: 90,
        lineWidth: 12,
        animation: true,
        percent: percent,
        circularStrokeCap: CircularStrokeCap.round,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              balance.toString(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              'Leave Balance',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.white.withOpacity(0.3),
        progressColor: Colors.white,
        backgroundWidth: 8,
        fillColor: Colors.transparent,
      ),
    );
  }
}
