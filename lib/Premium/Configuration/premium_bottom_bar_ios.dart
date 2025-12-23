import 'dart:io';

import 'package:ezhrm/Premium/Authentication/User%20Information/user_details.dart';
import 'package:ezhrm/Premium/Authentication/User%20Information/user_session.dart';
import 'package:ezhrm/Premium/Configuration/ApiUrlConfig.dart';
import 'package:ezhrm/Premium/dashboard/location_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Dependency_Injection/dependency_injection.dart';
import '../dashboard/screen/dashboard.dart';

class bottomBarIos extends StatefulWidget {
  const bottomBarIos({super.key});

  @override
  State<bottomBarIos> createState() => _bottomBarIosState();
}

class _bottomBarIosState extends State<bottomBarIos> {
  final userSession = getIt<UserSession>();
  final userDetails = getIt<UserDetails>();
  final apiUrlConfig = getIt<ApiUrlConfig>();
  final locationService = getIt<LocationService>();
  @override
  void initState() {
    super.initState();
  }

  opendrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo,
            Colors.blue.shade600,
          ],
        ),
        // gradient: const LinearGradient(
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        //   colors: [
        //     Colors.black,
        //     Colors.indigo,
        //   ],
        // ),
      ),
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            width: 55,
          ),
          GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: ((context) =>
                        HomeScreen(
                            userSession: userSession,
                          userDetails: userDetails,
                          apiUrlConfig: apiUrlConfig,
                          locationService: locationService))));
              },
              child: const Icon(
                Icons.home,
                color: Colors.white,
              )),
          const SizedBox(
            width: 55,
          ),
          GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              )),
        ],
      ),
    )
        : const SizedBox();
  }
}