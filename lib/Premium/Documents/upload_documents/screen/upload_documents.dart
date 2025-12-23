import 'dart:io';
import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
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
import '../../../success_dialog.dart';
import '../../Get Document Type/bloc/get_document_type_bloc.dart';
import '../../Get Document Type/modal/document_type_modal.dart';
import '../bloc/upload_documents_bloc.dart';

class UploadDocumentScreen extends StatelessWidget {
  const UploadDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UploadDocumentsBloc>(
          create: (_) => getIt<UploadDocumentsBloc>(),
        ),
        BlocProvider<GetDocumentTypeBloc>(
          create: (_) => getIt<GetDocumentTypeBloc>()..add(FetchDocumentType()),
        ),
      ],
      child: const _UploadDocumentScreenContent(),
    );
  }
}

class _UploadDocumentScreenContent extends StatefulWidget {
  const _UploadDocumentScreenContent();

  @override
  State<_UploadDocumentScreenContent> createState() =>
      _UploadDocumentScreenContentState();
}

class _UploadDocumentScreenContentState
    extends State<_UploadDocumentScreenContent> {
  DocumentTypeModel? selectedDocumentType;
  File? selectedFile;
  String? selectedFileExtension;

  void _showImageDialog(File imageFile) {
    // Prevent preview for non-image files
    final extension = selectedFileExtension?.toLowerCase();
    if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview is not available for this file type.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Show image preview dialog
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(imageFile, fit: BoxFit.contain),
        ),
      ),
    );
  }

  // initState is no longer needed here as the Bloc is initialized in the `build` method of the parent
  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    // All BlocListeners remain the same
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listener: (context, state) {
            if (state is SessionExpiredState || state is UserNotFoundState) {
              // Clear credentials
              getIt<UserSession>().clearUserCredentials();
              getIt<UserDetails>().clearUserDetails();

              // Navigate to login
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                  backgroundColor: Colors.red,
                ),
              );

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
                  (route) => false,
                );
              });
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully.'),
                  backgroundColor: Color(0xFF416CAF),
                ),
              );

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
                  (route) => false,
                );
              });
            } else if (state is LogoutFailure) {
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
        BlocListener<UploadDocumentsBloc, UploadDocumentsState>(
          listener: (context, state) {
            if (state is UploadDocumentSuccess) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => SuccessDialog(
                  title: 'Success',
                  message: 'Your document has been uploaded successfully.',
                  buttonText: 'Proceed ',
                  onPressed: () {},
                ),
              ); // Navigate or reset as needed
            } else if (state is UploadDocumentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        bottomNavigationBar: bottomBarIos(),
        appBar: AppBar(
          title: const Text('Upload Document',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black)),
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
        body: BlocBuilder<UploadDocumentsBloc, UploadDocumentsState>(
          builder: (context, state) {
            // Stack allows showing a loading indicator over the form
            return Stack(
              children: [
                // The main form content
                _buildForm(context),
                // Loading overlay shown during upload
                if (state is UploadDocumentLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    // Use MediaQuery to make layout responsive
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      // Use symmetric padding for better responsiveness
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ **RESPONSIVE FIX**: Image width is now relative to screen size.
          Image.asset(
            'assets/images/document.png',
            width: screenWidth * 0.5, // 50% of screen width
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          const Text(
            'Select a document type and upload your file',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Document Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(height: 8),

          // ✅ **UI FIX**: Handles empty and error states for the dropdown gracefully.
          BlocBuilder<GetDocumentTypeBloc, GetDocumentTypeState>(
            builder: (context, state) {
              if (state is GetDocumentTypeLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // This handles both API failure and success with an empty list.
              if (state is GetDocumentTypeFailure ||
                  (state is GetDocumentTypeSuccess &&
                      state.documentType.isEmpty)) {
                return DropdownButtonFormField<DocumentTypeModel>(
                  hint: const Text('None available'),
                  // `onChanged: null` disables the field.
                  onChanged: null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                  items: const [],
                );
              }

              // This is the successful state with data.
              if (state is GetDocumentTypeSuccess) {
                return DropdownButtonFormField<DocumentTypeModel>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 15.0),
                  ),
                  initialValue: selectedDocumentType,
                  hint: const Text('Select Document Type'),
                  isExpanded: true,
                  items: state.documentType
                      .map((type) => DropdownMenuItem<DocumentTypeModel>(
                            value: type,
                            child: Text(type.documentName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDocumentType = value;
                    });
                  },
                );
              }

              return const SizedBox.shrink(); // Fallback
            },
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Document File',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(height: 8),

          // File picker UI - structure is already quite responsive
          if (selectedFile == null)
            GestureDetector(
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: [
                    'jpg',
                    'jpeg',
                    'png',
                    'pdf',
                    'doc',
                    'docx'
                  ],
                );

                if (result != null && result.files.single.path != null) {
                  setState(() {
                    selectedFile = File(result.files.single.path!);
                    selectedFileExtension = result.files.single.extension;
                  });
                }
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_outlined,
                        size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tap to upload a file',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            // This widget for showing the selected file is already responsive due to `Expanded`.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedFileExtension?.toLowerCase() == 'pdf'
                        ? Icons.picture_as_pdf
                        : (selectedFileExtension?.toLowerCase() == 'doc' ||
                                selectedFileExtension?.toLowerCase() == 'docx')
                            ? Icons.description
                            : Icons.image,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedFile!.path.split('/').last,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${(selectedFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined,
                        color: Colors.blueAccent),
                    onPressed: () => _showImageDialog(selectedFile!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () {
                      setState(() {
                        selectedFile = null;
                        selectedFileExtension = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 30),

          // ✅ **RESPONSIVE FIX**: Button now takes full width for a modern look.
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (selectedDocumentType == null || selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        backgroundColor: Colors.red,
                        content:
                            Text('Please select a document type and a file.')),
                  );
                  return;
                }

                String generatedDocumentNumber =
                    'DOC-${DateTime.now().millisecondsSinceEpoch}';

                context.read<UploadDocumentsBloc>().add(
                      UploadDocument(
                        document_type_id:
                            selectedDocumentType!.documentTypeId.toString(),
                        document_number: generatedDocumentNumber,
                        verification_status: 'Pending',
                        image: selectedFile,
                      ),
                    );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white, // Text color
              ),
              child:
                  const Text('Upload Document', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
