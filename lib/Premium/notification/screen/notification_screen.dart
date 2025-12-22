import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../Authentication/User Information/user_details.dart';
import '../../Authentication/User Information/user_session.dart';
import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import '../../Fetch Notification/fetch_notification_bloc.dart';
import '../../SideMenuBar/screen/sidebar.dart';
import '../../dashboard/location_service.dart';
import '../../dashboard/screen/dashboard.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _searchQuery = "";

  @override
  void initState() {
    getIt<FetchNotificationBloc>().add(GetNotifications());
    super.initState();
  }

  Future<void> _onRefresh() async {
    // Trigger the GetNotifications event to refresh notifications
    getIt<FetchNotificationBloc>().add(GetNotifications());
    // Wait for the bloc to process the event (optional, depending on your use case)
    await Future.delayed(
        const Duration(milliseconds: 1000)); // Simulate network delay
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () {
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
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: const CustomSidebar(),
      body: BlocBuilder<FetchNotificationBloc, FetchNotificationState>(
        builder: (context, state) {
          if (state is FetchNotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is FetchNotificationFailure) {
            return Center(child: Text(state.errorMessage));
          } else if (state is FetchNotificationSuccess) {
            final List<dynamic> allNotifications = state.notifications;

            // 🔍 Apply search filter
            final filtered = allNotifications.where((n) {
              final subject =
                  (n['subject'] ?? 'Notification').toString().toLowerCase();
              final message = (n['message'] ?? '').toString().toLowerCase();
              return subject.contains(_searchQuery.toLowerCase()) ||
                  message.contains(_searchQuery.toLowerCase());
            }).toList();

            final now = DateTime.now();
            final today = filtered.where((n) {
              final dt = DateTime.tryParse(n['created_at'] ?? "");
              return dt != null &&
                  dt.year == now.year &&
                  dt.month == now.month &&
                  dt.day == now.day;
            }).toList();

            final yesterday = filtered.where((n) {
              final dt = DateTime.tryParse(n['created_at'] ?? "");
              final y = now.subtract(const Duration(days: 1));
              return dt != null &&
                  dt.year == y.year &&
                  dt.month == y.month &&
                  dt.day == y.day;
            }).toList();

            final others = filtered.where((n) {
              final dt = DateTime.tryParse(n['created_at'] ?? "");
              if (dt == null) return false;
              final y = now.subtract(const Duration(days: 1));
              return !(dt.year == now.year &&
                      dt.month == now.month &&
                      dt.day == now.day) &&
                  !(dt.year == y.year &&
                      dt.month == y.month &&
                      dt.day == y.day);
            }).toList();

            return Column(
              children: [
                // 🔍 Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search notifications',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh, // Bind the refresh callback
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (today.isNotEmpty) ...[
                          const Text(
                            "Today",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...today.map((n) => _buildNotificationTile(n)),
                          const SizedBox(height: 16),
                        ],
                        if (yesterday.isNotEmpty) ...[
                          const Text(
                            "Yesterday",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...yesterday.map((n) => _buildNotificationTile(n)),
                          const SizedBox(height: 16),
                        ],
                        if (others.isNotEmpty) ...[
                          const Text(
                            "All Notifications",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...others.map((n) => _buildNotificationTile(n)),
                        ],
                        if (filtered.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text("No Notification Found"),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> n) {
    final subjectRaw = n['subject'];
    final subject = (subjectRaw == null || subjectRaw.toString().trim().isEmpty)
        ? 'Notification'
        : subjectRaw.toString();

    final message = (n['message'] ?? '').toString();
    print('Notification subject: $subject');

    final date = DateTime.tryParse(n['created_at'] ?? "");
    final formatted = date != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal())
        : '';

    return ListTile(
      leading: Image.asset(
        'assets/images/ezhrm_logo.png', // 👈 put your mipmap image here
        width: 32,
        height: 32,
      ),
      title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 4),
          Text(formatted,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
