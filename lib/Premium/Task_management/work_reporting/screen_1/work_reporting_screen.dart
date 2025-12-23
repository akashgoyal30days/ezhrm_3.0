import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../bloc/work_reporting_bloc.dart';

class WorkReportingScreen extends StatefulWidget {
  const WorkReportingScreen({super.key});

  @override
  State<WorkReportingScreen> createState() => _WorkReportingScreenState();
}

class _WorkReportingScreenState extends State<WorkReportingScreen> {
  final List<TextEditingController> _todayCompleteWorkControllers = [];
  final List<TextEditingController> _nextDayPlanningControllers = [];

  bool _isInitialized = false;
  int? _currentTaskId; // keep track of which task's data we're showing

  @override
  void dispose() {
    for (var controller in _todayCompleteWorkControllers) {
      controller.dispose();
    }
    for (var controller in _nextDayPlanningControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Function to add a new controller for Today Completed Work
  void _addTodayCompleteWorkField() {
    setState(() {
      _todayCompleteWorkControllers.add(TextEditingController());
      print(
          'Added new Today Completed Work field. Total: ${_todayCompleteWorkControllers.length}');
    });
  }

  // Function to add a new controller for Next Day Planning
  void _addNextDayPlanningField() {
    setState(() {
      _nextDayPlanningControllers.add(TextEditingController());
      print(
          'Added new Next Day Planning field. Total: ${_nextDayPlanningControllers.length}');
    });
  }

  // Helper to initialize controllers from fetched data
  void _initializeControllers({
    required List<String> todayComplete,
    required List<String> nextDayPlanning,
    required int? taskId,
  }) {
    // Dispose any existing controllers first (important if re-initializing)
    for (final c in _todayCompleteWorkControllers) {
      c.dispose();
    }
    for (final c in _nextDayPlanningControllers) {
      c.dispose();
    }
    _todayCompleteWorkControllers.clear();
    _nextDayPlanningControllers.clear();

    for (var work in todayComplete) {
      _todayCompleteWorkControllers.add(TextEditingController(text: work));
    }
    if (_todayCompleteWorkControllers.isEmpty) {
      _todayCompleteWorkControllers.add(TextEditingController());
    }

    for (var plan in nextDayPlanning) {
      _nextDayPlanningControllers.add(TextEditingController(text: plan));
    }
    if (_nextDayPlanningControllers.isEmpty) {
      _nextDayPlanningControllers.add(TextEditingController());
    }

    _isInitialized = true;
    _currentTaskId = taskId;
  }

  // Card builder for read-only data (Today Plan)
  Widget _buildDataCard(
      {required List<String> data, required String emptyText}) {
    return Card(
      color: const Color(0xFFE9F3FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.isEmpty
              ? [
                  Text(emptyText,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: Colors.black))
                ]
              : data.map((item) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F3FC),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.normal),
                    ),
                  );
                }).toList(),
        ),
      ),
    );
  }

// Card builder for editable data (Today Complete Work / Next Day Plan)
  Widget _buildInputCard(
      List<TextEditingController> controllers, String hintText) {
    return Column(
      children: controllers
          .map((controller) => Card(
                color: const Color(0xFFE9F3FC),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.normal),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

// Circle badge for count
  Widget _buildCountBadge(int count, Color borderColor, Color bgColor) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: bgColor, width: 2),
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: bottomBarIos(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Work Reporting',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 30),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(
                        userSession: getIt<UserSession>(),
                        userDetails: getIt<UserDetails>(),
                        apiUrlConfig: getIt<ApiUrlConfig>(),
                        locationService: getIt<LocationService>(),
                      )),
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
      body: BlocConsumer<WorkReportingBloc, WorkReportingState>(
        listener: (context, state) {
          if (state is WorkReportingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          } else if (state is UpdateWorkReportingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Work reporting updated successfully'),
                  backgroundColor: Colors.green),
            );
          } else if (state is UpdateWorkReportingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        builder: (context, state) {
          if (state is WorkReportingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WorkReportingSuccess) {
            if (state.workReporting.isEmpty) {
              Text(
                'No task assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              );
            }
            // Grab the data from state but only initialize controllers when needed.
            final workReporting =
                state.workReporting.isNotEmpty ? state.workReporting[0] : {};
            final todayPlan = (workReporting['todayplan'] as List<dynamic>?)
                    ?.cast<String>() ??
                [];
            final todayCompleteWork =
                (workReporting['todaycompletework'] as List<dynamic>?)
                        ?.cast<String>() ??
                    [];
            final nextDayPlanning =
                (workReporting['nextdayplanning'] as List<dynamic>?)
                        ?.cast<String>() ??
                    [];
            final taskId = workReporting['id'] as int?;

            // Initialize only if not initialized yet OR if the task id changed (new data)
            if (!_isInitialized || _currentTaskId != taskId) {
              _initializeControllers(
                todayComplete: todayCompleteWork,
                nextDayPlanning: nextDayPlanning,
                taskId: taskId,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌟 Today Plan Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Plan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Poppins',
                          color: Color(0xFF5030E5),
                        ),
                      ),
                      SizedBox(width: 15),
                      _buildCountBadge(
                          todayPlan.length,
                          const Color(0xFF5030E5),
                          Color(0xFF5030E5).withOpacity(0.2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildDataCard(
                    data: todayPlan,
                    emptyText: 'No plans for today',
                  ),

                  const SizedBox(height: 20),

                  // ✅ Today Completed Work Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Today Completed Work',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Poppins',
                          color: Color(0xFF62B460),
                        ),
                      ),
                      SizedBox(width: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCountBadge(
                              _todayCompleteWorkControllers
                                  .where((c) => c.text.trim().isNotEmpty)
                                  .length,
                              const Color(0xFF62B460),
                              const Color(0x3362B460)),
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xFF62B460)),
                            onPressed: _addTodayCompleteWorkField,
                            tooltip: 'Add new completed work',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInputCard(_todayCompleteWorkControllers, ''),

                  const SizedBox(height: 20),

                  // ☀️ Next Day Planning Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Next Day Planning',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Poppins',
                          color: Color(0xFFFFA500),
                        ),
                      ),
                      SizedBox(width: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCountBadge(
                              _nextDayPlanningControllers
                                  .where((c) => c.text.trim().isNotEmpty)
                                  .length,
                              const Color(0xFFFFA500),
                              const Color(0x33FFA500)),
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Color(0xFFFFA500)),
                            onPressed: _addNextDayPlanningField,
                            tooltip: 'Add new plan',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInputCard(_nextDayPlanningControllers, ''),

                  const SizedBox(height: 30),

                  // 🔘 Update Button
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF095DA9),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_currentTaskId != null) {
                          getIt<WorkReportingBloc>().add(
                            UpdateWorkReporting(
                              taskId: _currentTaskId,
                              todayplan: todayPlan,
                              todaycompletework: _todayCompleteWorkControllers
                                  .map((c) => c.text)
                                  .toList(),
                              nextdayplanning: _nextDayPlanningControllers
                                  .map((c) => c.text)
                                  .toList(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('No task ID available for update')),
                          );
                        }
                      },
                      child: const Text(
                        'Update Work Reporting',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Please fetch work reporting data'));
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Trigger fetch work reporting when screen loads
    getIt<WorkReportingBloc>().add(GetWorkReporting());
  }
}
