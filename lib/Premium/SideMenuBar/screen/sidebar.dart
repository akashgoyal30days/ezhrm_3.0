import 'package:ezhrm/Premium/Authentication/User%20Information/user_details.dart';

import '../../Configuration/ApiUrlConfig.dart';
import '../../Dependency_Injection/dependency_injection.dart';
import 'package:flutter/material.dart';
import '../../change password/screen/change_password.dart';

class CustomSidebar extends StatefulWidget {
  const CustomSidebar({super.key});

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  // Local state to hold user data
  String userName = '';
  String email = '';
  String? imagePath; // Can be null

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDetails = getIt<UserDetails>();
      final fetchedUserData = await userDetails.getUserDetails();

      setState(() {
        userName = fetchedUserData['userName'] ?? 'User';
        email = fetchedUserData['email'] ?? 'No email';
        imagePath = fetchedUserData['imageUrl'];
      });

      debugPrint(
          'Fetched user data: Name: $userName, Email: $email, ImagePath: $imagePath');
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() {
        userName = 'User';
        email = 'No email';
      });
    }
  }

  final apiUrlConfig = getIt<ApiUrlConfig>();
  // Track expanded/collapsed state for each section
  final Map<String, bool> _sectionExpansionState = {
    'Attendance': true,
    'CSR': true,
    'Documents': true,
    'Leave': true,
    'Fund': true,
    'Task Management': true,
  };

  // Helper to get correct image provider
  ImageProvider _getProfileImage() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final fullUrl = '${apiUrlConfig.baseUrl}$imagePath';
      return NetworkImage(fullUrl);
    } else {
      return const AssetImage('assets/images/user.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 200),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8EBFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: _getProfileImage(),
                          onBackgroundImageError: (_, __) {
                            // Fallback if network image fails
                            debugPrint('Failed to load profile image');
                          },
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Fixed Dashboard item
                  _navItem(
                    icon: Icons.home,
                    label: 'Dashboard',
                    context: context,
                  ),

                  // Dynamic sidebar items with expandable sections
                  for (var item in sidebarItems.where((item) =>
                      !(item['label'] == 'Dashboard' ||
                          item['label'] == 'Feedback' ||
                          item['label'] == 'Change Password' ||
                          item['label'] == 'Contact Us' ||
                          item['label'] == 'Check for updates'))) ...[
                    if (item['type'] == 'header')
                      _ExpandableSectionHeader(
                        label: item['label'],
                        isExpanded:
                            _sectionExpansionState[item['label']] ?? true,
                        onToggle: () {
                          setState(() {
                            _sectionExpansionState[item['label']] =
                                !(_sectionExpansionState[item['label']] ??
                                    true);
                          });
                        },
                      ),
                    if (item['type'] == 'color' &&
                        (_sectionExpansionState[
                                _getParentSection(item['label'])] ??
                            true))
                      _colorNavItem(item['label'], item['color'], context),
                  ],

                  const SizedBox(height: 50),
                ],
              ),
            ),

            // Fixed bottom nav items
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    _navItem(
                        icon: Icons.feedback_outlined,
                        label: 'Feedback',
                        context: context),
                    _navItem(
                        icon: Icons.lock_outline,
                        label: 'Change Password',
                        context: context),
                    _navItem(
                        icon: Icons.phone,
                        label: 'Contact Us',
                        context: context),
                    _navItem(
                        icon: Icons.settings,
                        label: 'Check for updates',
                        context: context),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get parent section for an item
  String _getParentSection(String label) {
    int currentIndex =
        sidebarItems.indexWhere((item) => item['label'] == label);
    for (int i = currentIndex; i >= 0; i--) {
      if (sidebarItems[i]['type'] == 'header') {
        return sidebarItems[i]['label'];
      }
    }
    return '';
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required BuildContext context,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.grey[700]),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        _handleNavigation(context, label);
      },
    );
  }

  Widget _colorNavItem(String label, Color color, BuildContext context) {
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15)),
      onTap: () {
        Navigator.pop(context);
        _handleNavigation(context, label);
      },
    );
  }
}

// Expandable Section Header Widget
class _ExpandableSectionHeader extends StatelessWidget {
  final String label;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ExpandableSectionHeader({
    required this.label,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

void _handleNavigation(BuildContext context, String label) {
  final Map<String, String> labelToRoute = {
    'Dashboard': '/dashboard',
    'Mark Attendance': '/mark-attendance',
    'Request Attendance': '/request-attendance',
    'Req Past Attendance': '/request-past-attendance',
    'Attendance History': '/attendance-history',
    'Post Activity': '/post-activity',
    'View Activity': '/view-csr-activity',
    'Upload Documents': '/upload-documents',
    'View Documents': '/view-document',
    'Policies': '/policies',
    'Face Recognition Images': '/face-recognition',
    'Apply Leave': '/apply-leave',
    'Leave Status': '/leave-status',
    'Leave Quota': '/leave-quota',
    'Holiday List': '/holiday-list',
    'Work From Home': '/work-from-home',
    'Comp-Off': '/show-comp-off',
    'Reimbursement': '/getReimbursement',
    'Advance Salary': '/advance-salary-screen',
    'Loan': '/show-loan',
    'Salary Slip': '/salary-slip',
    'To do List': '/to-do',
    'Assigned Work': '/assigned-work',
    'Work Reporting': '/work-reporting',
    'Feedback': '/feedback',
    'Contact Us': '/contact-us',
    'View Status': '/view-csr-activity-status',
    'Policies': '/policy'
  };

  if (label == 'Change Password') {
    showChangePasswordDialog(context);
    return;
  }

  if (labelToRoute.containsKey(label)) {
    Navigator.pushNamed(context, labelToRoute[label]!);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No route defined for "$label"')),
    );
  }
}

// Sidebar data model
final List<Map<String, dynamic>> sidebarItems = [
  {
    'type': 'nav',
    'label': 'Dashboard',
    'icon': Icons.home,
  },
  {
    'type': 'header',
    'label': 'Attendance',
  },
  {
    'type': 'color',
    'label': 'Mark Attendance',
    'color': Colors.teal,
  },
  {
    'type': 'color',
    'label': 'Request Attendance',
    'color': Colors.deepPurple,
  },
  {
    'type': 'color',
    'label': 'Req Past Attendance',
    'color': Colors.blue,
  },
  {
    'type': 'color',
    'label': 'Attendance History',
    'color': Colors.purple,
  },
  {
    'type': 'header',
    'label': 'Leave',
  },
  {
    'type': 'color',
    'label': 'Apply Leave',
    'color': Colors.deepPurple,
  },
  {
    'type': 'color',
    'label': 'Leave Status',
    'color': Colors.purple,
  },
  {
    'type': 'color',
    'label': 'Leave Quota',
    'color': Colors.teal,
  },
  {
    'type': 'color',
    'label': 'Holiday List',
    'color': Colors.deepPurple,
  },
  {
    'type': 'color',
    'label': 'Work From Home',
    'color': Colors.purple,
  },
  {
    'type': 'color',
    'label': 'Comp-Off',
    'color': Colors.teal,
  },
  {
    'type': 'header',
    'label': 'Pay Roll',
  },
  {
    'type': 'color',
    'label': 'Reimbursement',
    'color': Colors.deepPurple,
  },
  {
    'type': 'color',
    'label': 'Advance Salary',
    'color': Colors.purple,
  },
  {
    'type': 'color',
    'label': 'Loan',
    'color': Colors.teal,
  },
  {
    'type': 'color',
    'label': 'Salary Slip',
    'color': Colors.deepPurple,
  },
  {
    'type': 'header',
    'label': 'CSR',
  },
  {
    'type': 'color',
    'label': 'Post Activity',
    'color': Colors.teal,
  },
  {
    'type': 'color',
    'label': 'View Activity',
    'color': Colors.deepPurple,
  },
  {
    'type': 'color',
    'label': 'View Status',
    'color': Colors.deepPurple,
  },
  {
    'type': 'header',
    'label': 'Documents',
  },
  {
    'type': 'color',
    'label': 'Upload Documents',
    'color': Colors.teal,
  },
  {
    'type': 'color',
    'label': 'View Documents',
    'color': Colors.deepPurple,
  },
  {
    'type': 'color',
    'label': 'Policies',
    'color': Colors.purple,
  },
  {
    'type': 'color',
    'label': 'Face Recognition Images',
    'color': Colors.teal,
  },
  {
    'type': 'header',
    'label': 'Task Management',
  },
  {
    'type': 'color',
    'label': 'To do List',
    'color': Colors.purple,
  },
  {
    'type': 'color',
    'label': 'Assigned Work',
    'color': Colors.teal,
  },
  {
    'type': 'color',
    'label': 'Work Reporting',
    'color': Colors.deepPurple,
  },
  {
    'type': 'nav',
    'label': 'Feedback',
    'icon': Icons.feedback_outlined,
  },
  {
    'type': 'nav',
    'label': 'Change Password',
    'icon': Icons.lock_outline,
  },
  {
    'type': 'nav',
    'label': 'Contact Us',
    'icon': Icons.phone,
  },
  {
    'type': 'nav',
    'label': 'Check for updates',
    'icon': Icons.settings,
  },
];
