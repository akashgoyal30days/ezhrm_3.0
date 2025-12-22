import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../bloc/week_off_bloc.dart';

class WeekOffScreen extends StatelessWidget {
  final UserSession userSession;
  final UserDetails userDetails;

  const WeekOffScreen(
      {required this.userSession, required this.userDetails, super.key});

  Future<void> _navigateBackToDashboard(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF416CAF)),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pop(); // Dismiss loading dialog
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userSession: getIt<UserSession>(),
          userDetails: getIt<UserDetails>(),
          apiUrlConfig: getIt<ApiUrlConfig>(),
          locationService: getIt<LocationService>(),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _navigateBackToDashboard(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
            onPressed: () => _navigateBackToDashboard(context),
          ),
          title: Text(
            'Week Off Schedule',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF416CAF),
          elevation: 0,
        ),
        body: WeekOffContent(
          userSession: userSession,
          userDetails: userDetails,
        ),
      ),
    );
  }
}

class WeekOffContent extends StatelessWidget {
  final UserSession userSession;
  final UserDetails userDetails;

  const WeekOffContent(
      {required this.userSession, required this.userDetails, super.key});

  Future<void> _refreshData(BuildContext context) async {
    BlocProvider.of<WeekOffBloc>(context).add(GetWeekOff());
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(context),
      child: BlocBuilder<WeekOffBloc, WeekOffState>(
        builder: (context, state) {
          if (state is WeekOffLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF416CAF)),
              ),
            );
          } else if (state is WeekOffSuccess) {
            final weekOffData = state.weekOffData;
            if (weekOffData.isEmpty) {
              return _buildEmptyState();
            }
            return _buildWeekOffList(weekOffData);
          } else if (state is WeekOffFailure) {
            if (state.errorMessage.contains('token is expired') ||
                state.errorMessage.contains('invalid token')) {
              print('navigating back to login screen from the week off screen');
              userSession.clearUserCredentials();
              userDetails.clearUserDetails();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        'Token expired! Login again',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                ),
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      userSession: getIt<UserSession>(),
                      userDetails: getIt<UserDetails>(),
                      apiUrlConfig: getIt<ApiUrlConfig>(),
                    ),
                  ),
                  (route) => false,
                );
              });
              return const Center(child: CircularProgressIndicator());
            } else {
              return _buildErrorState(state.errorMessage, context);
            }
          }
          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Loading week off schedule...',
            style: GoogleFonts.poppins(fontSize: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              Text(
                'No week off days scheduled.',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage, BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  BlocProvider.of<WeekOffBloc>(context).add(GetWeekOff());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF416CAF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekOffList(List<Map<String, dynamic>> weekOffData) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: weekOffData.length,
      itemBuilder: (context, index) {
        final weekOff = weekOffData[index];
        final List<dynamic> weekList =
            weekOff['days_of_week'] as List<dynamic>? ?? ['Unknown Days'];
        final reason = weekOff['reason'] as String? ?? 'Week Off';

        // Convert the list of days to a readable string
        final formattedDays =
            weekList.isNotEmpty ? weekList.join(', ') : 'No Days Specified';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading:
                const Icon(Icons.event, color: Color(0xFF416CAF), size: 32),
            title: Text(
              formattedDays,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              reason,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        );
      },
    );
  }
}
