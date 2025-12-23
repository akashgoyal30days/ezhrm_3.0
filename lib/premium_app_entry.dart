
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'Premium/Authentication/User Information/user_details.dart';
import 'Premium/Authentication/User Information/user_session.dart';
import 'Premium/Configuration/ApiUrlConfig.dart';
import 'Premium/Dependency_Injection/dependency_injection.dart';
import 'Premium/dashboard/location_service.dart';
import 'Premium/splash_screen.dart';

class NewAppEntry extends StatefulWidget {
  const NewAppEntry({super.key});

  @override
  State<NewAppEntry> createState() => _NewAppEntryState();
}

class _NewAppEntryState extends State<NewAppEntry> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNewApp();
  }

  Future<void> _initializeNewApp() async {

    if (!getIt.isRegistered<ApiUrlConfig>()) {
      print('Registering dependencies...');
      setupDependencies(); // This now has a guard inside
    } else {
      print('Dependencies already registered — skipping');
    }

    final prefs = await SharedPreferences.getInstance();
    bool isWorkmanagerInitialized =
        prefs.getBool('workmanager_initialized') ?? false;

    if (!isWorkmanagerInitialized) {
      print('Initializing Workmanager (New App)');
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      await prefs.setBool('workmanager_initialized', true);
    } else {
      print('Workmanager already initialized');
    }

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return SplashScreen(
      userDetails: getIt<UserDetails>(),
      userSession: getIt<UserSession>(),
    ); // Your full new app with MultiBlocProvider
  }
}

class DebugRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      debugPrint('didPush → ${route.settings.name} | ${route.runtimeType}');
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      debugPrint('didPop → ${route.settings.name}');
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      debugPrint('didReplace → ${newRoute.settings.name}');
    }
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    super.didStartUserGesture(route, previousRoute);
    if (route is PageRoute) {
      debugPrint('didStartUserGesture → ${route.settings.name}');
    }
  }
}
