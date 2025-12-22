import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

import 'constants.dart';

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key});

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  bool _locationAlways = false;
  bool _batteryOk = false;
  bool _gpsEnabled = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkAll();
  }

  Future<void> checkAll() async {
    setState(() => loading = true);
    // Location (Always)
    var locationStatus = await Permission.locationAlways.status;
    // Battery Optimization
    bool batteryOk = true;
    if (Platform.isAndroid) {
      batteryOk = await Permission.ignoreBatteryOptimizations.isGranted;
    }
    // GPS
    bool gpsEnabled = await Geolocator.isLocationServiceEnabled();

    setState(() {
      _locationAlways = locationStatus.isGranted;
      _batteryOk = batteryOk;
      _gpsEnabled = gpsEnabled;
      loading = false;
    });
  }

  Future<void> requestLocationAlways() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    var alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted) {
      alwaysStatus = await Permission.locationAlways.request();
    }
    alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Permission Required"),
          content: Text(
            "Please allow 'Location - All the time' permission in app settings for background tracking.",
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: Text("Open Settings"),
              onPressed: () async {
                Navigator.pop(ctx);
                await openAppSettings();
              },
            ),
          ],
        ),
      );
    }
    await checkAll();
  }

  Future<void> requestBatteryOptimization() async {
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
      await checkAll();
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
    await checkAll();
  }

  Widget buildCard({
    required String title,
    required String subtitle,
    required bool ok,
    required VoidCallback onFix,
    required IconData icon,
    String fixLabel = "Fix",
  }) {
    final themeColor = themecolor;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 5,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ok ? themeColor : Colors.redAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: ok
            ? Icon(Icons.check_circle, color: themeColor, size: 30)
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onFix,
                child: Text(fixLabel),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = themecolor;
    return Scaffold(
      backgroundColor: Color(0xfff4f8fc),
      appBar: AppBar(
        title: Text('Location Tracking Setup'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 25),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  buildCard(
                    title: "Location Permission (Always)",
                    subtitle:
                        "App must have 'Allow All the time' location permission.",
                    ok: _locationAlways,
                    onFix: () => requestLocationAlways(),
                    icon: Icons.location_on,
                  ),
                  buildCard(
                    title: "Battery Optimization",
                    subtitle:
                        "Turn off battery optimization for this app (required for background updates).",
                    ok: _batteryOk,
                    onFix: () => requestBatteryOptimization(),
                    icon: Icons.battery_charging_full,
                  ),
                  buildCard(
                    title: "GPS Enabled",
                    subtitle: "Device Location (GPS) must be enabled.",
                    ok: _gpsEnabled,
                    onFix: () => openLocationSettings(),
                    icon: Icons.gps_fixed,
                    fixLabel: "Open Settings",
                  ),
                  SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text("Re-Check All"),
                    onPressed: checkAll,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18))),
                  ),
                  SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "All items must be green for reliable background location tracking.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
