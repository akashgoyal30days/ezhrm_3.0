import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../../Attendance/mark attendance/screen/face_recognition_attendance.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../Get Permissions/bloc/get_permission_bloc.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../../../camera_screen.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../../../success_dialog.dart';
import '../../upload_image_status/bloc/upload_image_status_bloc.dart';
import '../bloc/upload_images_bloc.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  File? _image1, _image2, _image3;
  List<double>? _imageVector1, _imageVector2, _imageVector3;
  List<String> existingImageUrls = [];
  bool isFaceRecognitionEnabled = false;
  final FaceRecognitionService _faceService = FaceRecognitionService();
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _faceService.loadModel().then((_) {
      if (mounted) {
        setState(() {
          _modelLoaded = true;
        });
        print("✅ Model loaded in screen.");
      }
    }).catchError((e) {
      if (mounted) {
        _showMessageDialog(
            context, 'Error', 'Failed to load face recognition model: $e');
      }
    });
    // Fetch initial data
    getIt<UploadImageStatusBloc>().add(UploadImageStatus());
    getIt<GetPermissionBloc>().add(GetPermission());
  }

  void _showMessageDialog(BuildContext context, String title, String message,
      {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(
              title == 'Error'
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: title == 'Error' ? Colors.red : const Color(0xFF416CAF),
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: title == 'Error' ? Colors.red : const Color(0xFF416CAF),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF416CAF),
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    // The isFaceRecognitionEnabled check has been removed.
    if (!_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Face recognition model is still loading, please wait."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final cameras = await availableCameras();
    final userSession = getIt<UserSession>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          userSession: userSession,
          mode: CameraMode.faceRecognition,
          cameras: cameras,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic> && mounted) {
      final File imageFile = result['image'];
      final List<double> vector = result['vector'];

      setState(() {
        switch (index) {
          case 1:
            _image1 = imageFile;
            _imageVector1 = vector;
            break;
          case 2:
            _image2 = imageFile;
            _imageVector2 = vector;
            break;
          case 3:
            _image3 = imageFile;
            _imageVector3 = vector;
            break;
        }
      });
    }
  }

  Widget _buildImageBox({
    required int index,
    required File? image,
    required String? existingImageUrl,
    required double width,
    required double height,
  }) {
    final apiUrlConfig = getIt<ApiUrlConfig>();
    final imageUrl = existingImageUrl != null
        ? '${apiUrlConfig.baseUrl}$existingImageUrl'
        : null;

    return GestureDetector(
      // The onTap is now always active.
      onTap: () {
        if (isFaceRecognitionEnabled) {
          _pickImage(index);
        } else {
          _showMessageDialog(
            context,
            'Permission Denied',
            'Face upload for recognition permission is not provided',
          );
        }
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image != null
              ? Image.file(image, fit: BoxFit.cover)
              : (imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress ==
                              null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, color: Colors.grey),
                    )
                  : const Center(
                      child: Icon(Icons.camera_alt_outlined,
                          size: 32, color: Colors.grey),
                    )),
        ),
      ),
    );
  }

  void _submitImages() {
    // The isFaceRecognitionEnabled check has been removed.
    if (_image1 == null || _image2 == null || _image3 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add all 3 images to submit.")),
      );
      return;
    }
    if (_imageVector1 == null ||
        _imageVector2 == null ||
        _imageVector3 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Face data could not be generated. Please capture the images again.")),
      );
      return;
    }
    context.read<UploadImagesBloc>().add(
          UploadImages(
            image1: _image1!,
            image2: _image2!,
            image3: _image3!,
            imageVector1: _imageVector1!,
            imageVector2: _imageVector2!,
            imageVector3: _imageVector3!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ **RESPONSIVE FIX**: Calculate box sizes based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 24.0;
    final spacing = 16.0;
    final boxWidth =
        (screenWidth - (horizontalPadding * 2) - (spacing * 2)) / 3;
    final boxHeight = boxWidth * 1.9; // Maintain a good aspect ratio

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add more Images",
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<UploadImagesBloc, UploadImagesState>(
            listener: (context, state) {
              if (state is UploadImagesSuccess) {
                // Clear local state on success
                setState(() {
                  _image1 = _image2 = _image3 = null;
                  _imageVector1 = _imageVector2 = _imageVector3 = null;
                });
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => SuccessDialog(
                    message: 'Your images have been successfully uploaded.',
                    buttonText: 'Done',
                    onPressed: () {},
                    title: '',
                  ),
                );
              } else if (state is UploadImagesFailure) {
                _showMessageDialog(
                    context, "Upload Failed", state.errorMessage);
              }
            },
          ),
          BlocListener<UploadImageStatusBloc, UploadImageStatusState>(
            listener: (context, state) {
              if (state is UploadImageStatusSuccess) {
                setState(() {
                  existingImageUrls = state.statusData
                      .map<String>((e) => e['image_path'] ?? '')
                      .where((path) => path.isNotEmpty)
                      .toList();
                });
              }
            },
          ),
          BlocListener<GetPermissionBloc, GetPermissionState>(
            listener: (context, state) {
              if (state is GetPermissionSuccess) {
                setState(() {
                  // The variable is set, but no longer used for conditional logic.
                  isFaceRecognitionEnabled =
                      state.permissions['is_face_recognition'] == 1;
                });
              } else if (state is GetPermissionFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.errorMessage),
                      backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
        // ✅ **RESPONSIVE FIX**: Wrap content in a SingleChildScrollView
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Text(
                  // The text is now static.
                  "Add all 3 images to continue",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2F3036),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              // The if-condition that wrapped this Padding has been removed.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildImageBox(
                          index: 1,
                          image: _image1,
                          existingImageUrl: existingImageUrls.isNotEmpty
                              ? existingImageUrls[0]
                              : null,
                          width: boxWidth,
                          height: boxHeight,
                        ),
                        _buildImageBox(
                          index: 2,
                          image: _image2,
                          existingImageUrl: existingImageUrls.length > 1
                              ? existingImageUrls[1]
                              : null,
                          width: boxWidth,
                          height: boxHeight,
                        ),
                        _buildImageBox(
                          index: 3,
                          image: _image3,
                          existingImageUrl: existingImageUrls.length > 2
                              ? existingImageUrls[2]
                              : null,
                          width: boxWidth,
                          height: boxHeight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          backgroundColor:
                              Colors.transparent, // Important for gradient
                        ),
                        onPressed: context.watch<UploadImagesBloc>().state
                                is UploadImagesLoading
                            ? null
                            : _submitImages,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2D9CDB), Color(0xFF0059B2)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: context.watch<UploadImagesBloc>().state
                                    is UploadImagesLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Submit",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
