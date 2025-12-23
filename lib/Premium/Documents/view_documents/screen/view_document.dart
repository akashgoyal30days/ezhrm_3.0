import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart'; // Flutter material design components
import 'package:flutter_bloc/flutter_bloc.dart'; // BLoC for state management
import 'package:dio/dio.dart'; // HTTP client for downloading files
import 'package:open_file/open_file.dart'; // Open files in native apps
import 'package:path_provider/path_provider.dart'; // Access device storage directories
import 'dart:io';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Authentication/bloc/auth_bloc.dart';
import '../../../Authentication/screen/login_screen.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SessionHandling/session_bloc.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../bloc/view_doucments_bloc.dart';

// Define the ViewDocumentScreen widget as a StatefulWidget
class ViewDocumentScreen extends StatefulWidget {
  const ViewDocumentScreen({super.key}); // Constructor with optional key

  @override
  State<ViewDocumentScreen> createState() =>
      _ViewDocumentScreenState(); // Create state
}

// State class for ViewDocumentScreen
class _ViewDocumentScreenState extends State<ViewDocumentScreen> {
  final apiUrlConfig = getIt<ApiUrlConfig>();
  // Initialize state, fetching documents when the screen loads
  @override
  void initState() {
    super.initState();
    // Trigger FetchEmployeeDocument event to load documents
    context.read<ViewDocumentsBloc>().add(FetchEmployeeDocument());
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    // Use MultiBlocListener to listen to multiple BLoC states
    return MultiBlocListener(
      listeners: [
        // Listen for session-related states (expired or user not found)
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              // Clear user credentials and details
              getIt<UserSession>().clearUserCredentials();
              getIt<UserDetails>().clearUserDetails();

              // Show session expired message
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );

              // Navigate to LoginScreen after a 2-second delay
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      userSession: getIt<UserSession>(),
                      userDetails: getIt<UserDetails>(),
                      apiUrlConfig: getIt<ApiUrlConfig>(),
                    ),
                  ),
                  (route) => false, // Remove all previous routes
                );
              });
            }
          },
        ),
        // Listen for authentication-related states (logout success or failure)
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              // Show logout success message
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully.'),
                  backgroundColor: Color(0xFF416CAF),
                ),
              );

              // Navigate to LoginScreen after a 2-second delay
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      userSession: getIt<UserSession>(),
                      userDetails: getIt<UserDetails>(),
                      apiUrlConfig: getIt<ApiUrlConfig>(),
                    ),
                  ),
                  (route) => false, // Remove all previous routes
                );
              });
            } else if (state is LogoutFailure) {
              // Show logout failure message
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error logging out.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      // Build the Scaffold widget
      child: Scaffold(
        bottomNavigationBar: bottomBarIos(),
        backgroundColor: const Color(0xFFF9F9F9), // Light gray background
        appBar: AppBar(
          elevation: 0, // No shadow
          backgroundColor: Colors.white, // White app bar
          leading: IconButton(
            icon: const Icon(Icons.chevron_left,
                color: Colors.black), // Back arrow
            onPressed: () {
              // Navigate back to HomeScreen, clearing the navigation stack
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
          title: const Text(
            'View Document',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true, // Center the title
          actions: [
            // Menu button to open the drawer
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ],
        ),
        drawer: const CustomSidebar(), // Sidebar drawer
        body: BlocBuilder<ViewDocumentsBloc, ViewDocumentsState>(
          builder: (context, state) {
            // Handle different states of ViewDocumentsBloc
            if (state is FetchEmployeeDocumentLoading) {
              // Show loading indicator
              return const Center(child: CircularProgressIndicator());
            } else if (state is FetchEmployeeDocumentError) {
              // Show error message
              return Center(child: Text(state.error));
            } else if (state is FetchEmployeeDocumentSuccess) {
              final documents = state.employeeDocuments;
              if (documents.isEmpty) {
                // Show message if no documents are found
                return const Center(child: Text("No documents found."));
              }

              // Build a list of documents
              return ListView.builder(
                padding: const EdgeInsets.all(16), // Padding around the list
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  final name =
                      doc['document_name'] ?? 'Unknown'; // Document name
                  final size = doc['file_size'] ?? 'N/A'; // File size
                  final type =
                      (doc['file_type'] ?? 'image').toLowerCase(); // File type
                  final String? documentPath =
                      doc['document_path']; // File path
                  final String fileUrl = documentPath != null
                      ? '${apiUrlConfig.baseUrl}$documentPath'
                      : ''; // Full URL
                  final String safeFileName =
                      _getSafeFileName(name, type); // Safe file name

                  // Build each document item
                  return Container(
                    margin: const EdgeInsets.only(
                        bottom: 16), // Margin between items
                    padding:
                        const EdgeInsets.all(12), // Padding inside container
                    decoration: BoxDecoration(
                      color: Colors.white, // White background
                      borderRadius:
                          BorderRadius.circular(16), // Rounded corners
                    ),
                    child: Row(
                      children: [
                        _buildFileIcon(type), // File type icon
                        const SizedBox(width: 12), // Spacer
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600, // Bold text
                                ),
                              ),
                              const SizedBox(height: 4), // Spacer
                              Text(
                                size,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey, // Gray text
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // View button
                            _iconButton(
                              Icons.remove_red_eye,
                              Colors.blue.shade100,
                              Colors.blue,
                              () {
                                _launchURL(fileUrl, safeFileName, type);
                              },
                            ),
                            const SizedBox(width: 8), // Spacer
                            // Download button
                            _iconButton(
                              Icons.download,
                              Colors.green.shade100,
                              Colors.green,
                              () {
                                _downloadFile(fileUrl, safeFileName);
                              },
                            ),
                            const SizedBox(width: 8), // Spacer
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              // Default empty state
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }

  // Build icon button for view/download actions
  Widget _iconButton(
      IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: bgColor, // Background color
        child: Icon(icon, color: iconColor, size: 16), // Icon
      ),
    );
  }

  // Build file icon based on file type
  Widget _buildFileIcon(String type) {
    return Image.asset(
      type == 'pdf'
          ? 'assets/images/pdficon.png'
          : type == 'doc' || type == 'docx'
              ? 'assets/images/docicon.png'
              : 'assets/images/jpgicon.png',
      height: 32,
      width: 32,
    );
  }

  // Download and open file in native viewer (for view button)
  Future<void> _launchURL(String url, String fileName, String fileType) async {
    // Check if URL is empty
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File URL is missing.')),
      );
      return;
    }

    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      // Download file using Dio
      await Dio().download(url, filePath);

      // Open file using open_file
      final result = await OpenFile.open(filePath);

      // Check if file opened successfully
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open the file')),
          );
        }
      }
    } catch (e) {
      // Handle errors (e.g., download failure, file not supported)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file')),
        );
      }
    }
  }

  // Download file to persistent storage (for download button)
  Future<void> _downloadFile(String url, String fileName) async {
    // Check if URL is empty
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File URL is missing.')),
      );
      return;
    }

    try {
      // Get Downloads directory or fallback to app's documents directory
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (downloadDir != null && !await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Construct file path
      final filePath = '${downloadDir?.path}/$fileName';

      // Download file using Dio
      await Dio().download(url, filePath);

      // Show success message
      if (mounted) {
        debugPrint('Downloaded Path is $filePath');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File successfully downloaded to $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle errors (e.g., download failure, permission issues)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error downloading file'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // Generate safe file name with appropriate extension
  String _getSafeFileName(String fileName, String fileType) {
    String extension = fileType.toLowerCase();
    // Map file types to extensions
    if (extension == 'image') {
      extension = 'jpg'; // Default to jpg for images
    } else if (extension == 'doc' || extension == 'docx') {
      extension = 'docx'; // Use docx for documents
    } else if (extension == 'pdf') {
      extension = 'pdf'; // Use pdf for PDF files
    }
    // Clean file name and append extension
    return '${fileName.replaceAll(RegExp(r'[^\w\d.]'), '_')}.$extension';
  }
}
