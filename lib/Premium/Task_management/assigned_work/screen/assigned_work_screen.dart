import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../bloc/assigned_work_bloc.dart';
import '../modal/assigned_work_modal.dart';

class AssignWorkScreen extends StatefulWidget {
  const AssignWorkScreen({super.key});

  @override
  State<AssignWorkScreen> createState() => _AssignWorkScreenState();
}

class _AssignWorkScreenState extends State<AssignWorkScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<AssignedWorkBloc>().add(AssignedWork());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomBarIos(),
      appBar: AppBar(
        title: const Text('Assigned Work',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            )),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
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
              icon: const Icon(Icons.menu),
              color: Colors.black,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      body: const AssignWorkBody(),
      drawer: const CustomSidebar(),
    );
  }
}

class AssignWorkBody extends StatelessWidget {
  const AssignWorkBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssignedWorkBloc, AssignedWorkState>(
      bloc: getIt<AssignedWorkBloc>(),
      builder: (context, state) {
        if (state is AssignedWorkLoading ||
            state is UpdateAssignedWorkLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AssignedWorkSuccess) {
          if (state.assignedWork.isEmpty) {
            return const Center(
              child: Text(
                'No task assigned',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.assignedWork.length,
            itemBuilder: (context, index) {
              final task = state.assignedWork[index];
              return AssignWorkTaskCard(task: task);
            },
          );
        }

        if (state is AssignedWorkFailure ||
            state is UpdateAssignedWorkFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  state is AssignedWorkFailure
                      ? state.errorMessage
                      : (state as UpdateAssignedWorkFailure).errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      getIt<AssignedWorkBloc>().add(AssignedWork()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('No assigned work available'));
      },
    );
  }
}

class AssignWorkTaskCard extends StatefulWidget {
  final AssignedTask task;

  const AssignWorkTaskCard({super.key, required this.task});

  @override
  State<AssignWorkTaskCard> createState() => _AssignWorkTaskCardState();
}

class _AssignWorkTaskCardState extends State<AssignWorkTaskCard> {
  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return 'No Date';
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/question.png', width: 60, height: 60),
              const SizedBox(height: 16),
              const Text(
                'Do you want to change the status of this work to Completed?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('No',
                        style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showSuccessDialog();
                      getIt<AssignedWorkBloc>().add(
                        UpdateAssignedWork(workId: widget.task.id.toString()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1F86E3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Yes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/success.png'),
              const SizedBox(height: 16),
              const Text(
                'Assigned Work updated successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('OK',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.task.customer?.companyName ?? 'N/A';
    final taskName = widget.task.task ?? 'No Task';
    final contactNumber = widget.task.customer?.contactNumber ?? 'N/A';
    final assignedBy = widget.task.employee?.firstName ?? 'N/A';
    final createdAtRaw = widget.task.createdAt ?? '2025-01-01T00:00:00.000000Z';
    final status = widget.task.status ?? 'Pending';
    final formattedDate = _formatDate(createdAtRaw);
    final isPending = status.toLowerCase() == 'pending';
    final isCompleted = status.toLowerCase() == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Row 1: Customer + Task
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('Customer', customerName),
                    _buildInfoItem('Task', taskName),
                  ],
                ),
                const SizedBox(height: 10),

                // 🔹 Row 2: Contact + Assigned By
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('Contact', contactNumber),
                    _buildInfoItem('Assigned By', assignedBy),
                  ],
                ),
                const SizedBox(height: 10),

                // 🔹 Row 3: Date + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('Date', formattedDate),
                    if (isCompleted)
                      _buildInfoItem('Status', 'Completed')
                    else
                      _buildInfoItem('Status', 'Not Completed'),
                  ],
                ),
              ],
            ),
          ),

          // 🔹 Top-right Update Icon
          if (!isCompleted)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _showConfirmationDialog,
                child: Image.asset(
                  'assets/images/edit_icon.png', // <-- your asset image
                  width: 28,
                  height: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isPending, bool isCompleted) {
    Color bgColor;
    if (isCompleted) {
      bgColor = Colors.green;
    } else if (isPending) {
      bgColor = const Color(0xFFFFA500);
    } else {
      bgColor = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
