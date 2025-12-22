import 'package:flutter/material.dart';

class HolidayModel {
  final String title;
  final List<String> dates; // Changed from String date to List<String> dates
  final Color color;

  HolidayModel({
    required this.title,
    required this.dates,
    required this.color,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      title: json['holiday_name'] ?? '',
      dates: (json['holiday_date'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [], // Handle list
      color: Colors.red,
    );
  }
}
