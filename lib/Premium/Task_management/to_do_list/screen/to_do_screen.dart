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
import '../bloc/to_do_list_bloc.dart';
import 'package:intl/intl.dart';

class ToDoListScreen extends StatefulWidget {
  const ToDoListScreen({super.key});

  @override
  State<ToDoListScreen> createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically fetch To Do List when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<ToDoListBloc>().add(FetchToDoList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: bottomBarIos(),
      appBar: AppBar(
        title: const Text('To Do List',
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
      body: const ToDoListBody(),
      drawer: const CustomSidebar(),
    );
  }
}

class ToDoListBody extends StatelessWidget {
  const ToDoListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ToDoListBloc, ToDoListState>(
      bloc: getIt<ToDoListBloc>(),
      builder: (context, state) {
        if (state is ToDoListLoading || state is UpdateToDoListLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is ToDoListSuccess) {
          if (state.toDoListData.isEmpty) {
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
            itemCount: state.toDoListData.length,
            itemBuilder: (context, index) {
              final task = state.toDoListData[index];
              return ToDoTaskCard(task: task);
            },
          );
        }

        if (state is ToDoListFailure || state is UpdateToDoListFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  state is ToDoListFailure
                      ? state.errorMessage
                      : (state as UpdateToDoListFailure).errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => getIt<ToDoListBloc>().add(FetchToDoList()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const Center(child: Text('No tasks available'));
      },
    );
  }
}

class ToDoTaskCard extends StatefulWidget {
  final Map<String, dynamic> task;

  const ToDoTaskCard({super.key, required this.task});

  @override
  State<ToDoTaskCard> createState() => _ToDoTaskCardState();
}

class _ToDoTaskCardState extends State<ToDoTaskCard> {
  String? _selectedStatus;
  bool _showDropdown = false;
  final GlobalKey _dropdownKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task['status']?.toString() ?? 'Pending';
  }

  void _showStatusDropdown() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(
        position.dx + renderBox.size.width - 120, // Right aligned
        position.dy + 50, // Below the icon
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'Pending',
          child: Row(
            children: [
              Text(_selectedStatus == 'Pending' ? 'Pending' : 'Pending',
                  style: TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.normal)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'Complete',
          child: Row(
            children: [
              Text(_selectedStatus == 'Complete' ? 'Complete' : 'Complete',
                  style: TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.normal)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _updateTaskStatus(value);
      }
    });
  }

  void _hideStatusDropdown() {
    setState(() {
      _showDropdown = false;
    });
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy').format(dateTime);
    } catch (e) {
      return 'No Date';
    }
  }

  void _updateTaskStatus(String newStatus) {
    setState(() {
      _selectedStatus = newStatus;
      _showDropdown = false;
    });

    final taskId =
        widget.task['id']?.toString() ?? widget.task['task_id']?.toString();

    if (taskId != null) {
      getIt<ToDoListBloc>().add(
        UpdateToDoTask(status: newStatus, taskId: taskId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskName = widget.task['task']?.toString() ?? 'No Task Name';
    final deadline = widget.task['deadline']?.toString() ?? 'No Deadline';
    final createdAtRaw =
        widget.task['created_at']?.toString() ?? '2025-01-01T00:00:00.000000Z';
    final formattedDate = _formatDate(createdAtRaw);
    final formatDeadline = _formatDate(deadline);
    final isPending = _selectedStatus?.toLowerCase() == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white, // Explicit white color
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side - Task Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deadline: $formatDeadline',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: $formattedDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Side - Status & Dropdown
            Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Update Image Icon
                    GestureDetector(
                      onTap: _showStatusDropdown,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset('assets/images/edit_icon.png'),
                        ),
                      ),
                    ),
                    const SizedBox(
                        height: 16), // Increased space between icon and status
                    // Status Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            isPending ? const Color(0xFFFFA500) : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _selectedStatus ?? 'Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
