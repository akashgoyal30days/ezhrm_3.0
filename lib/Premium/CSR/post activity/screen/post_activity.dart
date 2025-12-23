import 'package:ezhrm/Premium/Configuration/premium_bottom_bar_ios.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../Authentication/User Information/user_details.dart';
import '../../../Authentication/User Information/user_session.dart';
import '../../../Configuration/ApiUrlConfig.dart';
import '../../../Dependency_Injection/dependency_injection.dart';
import '../../../SideMenuBar/screen/sidebar.dart';
import '../../../dashboard/location_service.dart';
import '../../../dashboard/screen/dashboard.dart';
import '../../../success_dialog.dart';
import '../bloc/post_csr_activity_bloc.dart';

class PostCsrActivityScreen extends StatefulWidget {
  const PostCsrActivityScreen({super.key});

  @override
  State<PostCsrActivityScreen> createState() => _PostCsrActivityScreenState();
}

class _PostCsrActivityScreenState extends State<PostCsrActivityScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      int fileSize = await imageFile.length(); // Get file size in bytes
      const int maxSizeInBytes = 2 * 1024 * 1024; // 2MB in bytes

      if (fileSize > maxSizeInBytes) {
        // Compress the image
        final compressedFile = await _compressImage(imageFile, maxSizeInBytes);
        if (compressedFile != null) {
          setState(() {
            _selectedImage = compressedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to compress image')),
          );
          return;
        }
      } else {
        setState(() {
          _selectedImage = imageFile;
        });
      }
    }
  }

  Future<File?> _compressImage(File imageFile, int maxSizeInBytes) async {
    try {
      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/compressed_${imageFile.path.split('/').last}';
      int quality = 85; // Start with 85% quality
      File? compressedFile;

      while (quality >= 10) {
        // Compress image
        XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
          imageFile.absolute.path,
          targetPath,
          quality: quality,
          minWidth: 1024, // Optional: Adjust resolution if needed
          minHeight: 1024,
        );

        if (compressedXFile == null) return null;

        compressedFile = File(compressedXFile.path);
        int compressedSize = await compressedFile.length();

        if (compressedSize <= maxSizeInBytes) {
          return compressedFile; // Return if size is within limit
        }

        // Reduce quality by 10% for the next iteration
        quality -= 10;
      }

      // If compression fails to get under 2MB
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to compress image below 2MB')),
      );
      return null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  void _submitActivity() {
    final description = _descriptionController.text.trim();

    if (description.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter description and image')),
      );
      return;
    }

    context.read<PostCsrActivityBloc>().add(
          PostCsrActivity(
            description: description,
            activity: _selectedImage!,
          ),
        );
  }

  void _showImageDialog(File imageFile) {
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

  Widget _buildImagePreviewCard(File imageFile) {
    final String fileName = imageFile.path.split('/').last;
    final int fileSize = imageFile.lengthSync();
    final String sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 40, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$sizeInMB MB',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_red_eye_outlined,
                color: Colors.blueAccent),
            onPressed: () => _showImageDialog(imageFile),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => setState(() => _selectedImage = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCsrActivityBloc, PostCsrActivityState>(
      listener: (context, state) {
        if (state is PostCsrActivitySuccess) {
          _descriptionController.clear();
          _selectedImage = null;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => SuccessDialog(
              title: "Success!",
              message: "CSR Activity submitted successfully.",
              buttonText: "Proceed",
              onPressed: () {},
            ),
          );
        } else if (state is PostCsrActivityError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          bottomNavigationBar: bottomBarIos(),
          appBar: AppBar(
            title: const Text("Post CSR Activity",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.black),
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
                    Scaffold.of(context).openDrawer(); // Safe call
                  },
                ),
              ),
            ],
          ),
          drawer: const CustomSidebar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Image.asset('assets/images/plant.png', width: 265, height: 152),
                const SizedBox(height: 24),
                const Text(
                  "Please provide the details below to post a CSR activity",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Description
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Description",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Share your description here",
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Image Upload Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Activity Image",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                  ),
                ),
                const SizedBox(height: 8),

                // Upload Box
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Upload File",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : _buildImagePreviewCard(_selectedImage!),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state is PostCsrActivityLoading
                        ? null
                        : _submitActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state is PostCsrActivityLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit CSR Activity",
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
