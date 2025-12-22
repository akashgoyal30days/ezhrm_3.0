// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:ezhrm/main.dart';
// import 'package:ezhrm/Attendance/mark%20attendance/screen/check_out.dart';
// import 'package:ezhrm/Authentication/User%20Information/user_session.dart';
// import 'package:ezhrm/Dependency_Injection/dependency_injection.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
// import 'Attendance/mark attendance/bloc/mark_attendance_bloc.dart';
// import 'Attendance/mark attendance/screen/face_recognition.dart';
// import 'Configuration/ApiUrlConfig.dart';
//
// enum CameraType { frontCamera, rearCamera }
//
// class CameraScreen extends StatefulWidget {
//   final UserSession userSession;
//   final Function(Uint8List)? callBack;
//   final CameraType cameraType;
//   final bool showFrame;
//   final bool imageSizeShouldBeLessThan200kB;
//   final bool decreaseImageSizeByHalf;
//   final bool returnVector;
//
//   const CameraScreen({
//     super.key,
//     required this.userSession,
//     this.callBack,
//     this.cameraType = CameraType.frontCamera,
//     this.showFrame = true,
//     this.imageSizeShouldBeLessThan200kB = false,
//     this.decreaseImageSizeByHalf = false,
//     this.returnVector = false,
//   });
//
//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> {
//   final LatLng _currentPosition = const LatLng(28.6904, 76.9789);
//   bool _isLoading = false;
//   bool _modelLoaded = false;
//   bool showImagePreview = false;
//   int marginForImage = 15;
//   int? actualImageSize;
//   Uint8List? savedImageBytes;
//   File? savedImageFile; // New variable to store the File object
//   List<double>? faceEmbedding;
//   final FaceRecognitionService _faceService = FaceRecognitionService();
//   late List<CameraDescription> _cameras;
//   CameraController? _controller;
//   late double _ovalWidth;
//   late double _ovalHeight;
//   double? _cameraAspectRatio;
//   Future<void>? _initializeCameraFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCameraFuture = _initialize();
//   }
//
//   Future<void> _initialize() async {
//     try {
//       await _faceService.loadModel();
//       _modelLoaded = true;
//       print("Model loaded in screen.");
//
//       _cameras = await availableCameras();
//       final camera = widget.cameraType == CameraType.frontCamera
//           ? _cameras.firstWhere(
//             (desc) => desc.lensDirection == CameraLensDirection.front,
//         orElse: () => _cameras.first,
//       )
//           : _cameras.firstWhere(
//             (desc) => desc.lensDirection == CameraLensDirection.back,
//         orElse: () => _cameras.first,
//       );
//       _controller = CameraController(camera, ResolutionPreset.max, enableAudio: false);
//       await _controller!.initialize();
//       if (mounted) {
//         _cameraAspectRatio = _controller!.value.aspectRatio;
//         setState(() {});
//       }
//     } catch (e) {
//       print("Error initializing camera: $e");
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     _ovalWidth = screenWidth * 0.65;
//     _ovalHeight = screenHeight * 0.78;
//     print('Oval dimensions: width=$_ovalWidth, height=$_ovalHeight');
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   void _showPopup(String message) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Verification Failed'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<img.Image?> _cropImageToOval(Uint8List bytes) async {
//     img.Image? originalImage = img.decodeImage(bytes);
//     if (originalImage == null) return null;
//
//     if (widget.cameraType == CameraType.frontCamera) {
//       originalImage = img.flipHorizontal(originalImage);
//     }
//
//     final imageWidth = originalImage.width;
//     final imageHeight = originalImage.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     final ovalWidthInImage = (_ovalWidth / screenWidth) * imageWidth;
//     final ovalHeightInImage = (_ovalHeight / screenHeight) * imageHeight;
//     final centerX = imageWidth / 2;
//     final centerY = imageHeight / 2;
//
//     final croppedImage = img.Image(
//       width: ovalWidthInImage.toInt(),
//       height: ovalHeightInImage.toInt(),
//     );
//
//     for (int y = 0; y < croppedImage.height; y++) {
//       for (int x = 0; x < croppedImage.width; x++) {
//         final srcX = centerX + (x - croppedImage.width / 2) * (ovalWidthInImage / croppedImage.width);
//         final srcY = centerY + (y - croppedImage.height / 2) * (ovalHeightInImage / croppedImage.height);
//
//         final dx = (x - croppedImage.width / 2) / (ovalWidthInImage / 2);
//         final dy = (y - croppedImage.height / 2) / (ovalHeightInImage / 2);
//         if (dx * dx + dy * dy <= 1) {
//           final pixel = originalImage.getPixelSafe(srcX.toInt(), srcY.toInt());
//           croppedImage.setPixel(x, y, pixel);
//         } else {
//           croppedImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
//         }
//       }
//     }
//
//     final tempDir = await getTemporaryDirectory();
//     final filePath = '${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final file = File(filePath);
//     await file.writeAsBytes(img.encodeJpg(croppedImage));
//     print('Cropped image saved at: $filePath');
//
//     // Store the File object
//     savedImageFile = file;
//
//     return croppedImage;
//   }
//
//   Future<void> _captureAndUpload() async {
//     if (_controller == null || !_controller!.value.isInitialized || _isLoading) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       final XFile image = await _controller!.takePicture();
//       final originalBytes = await File(image.path).readAsBytes();
//       print('CameraScreen: saved image path is ${image.path}');
//
//       final croppedImage = await _cropImageToOval(originalBytes);
//       if (croppedImage == null) {
//         throw Exception("Failed to crop image");
//       }
//       savedImageBytes = Uint8List.fromList(img.encodeJpg(croppedImage));
//       print('Cropped image size: ${savedImageBytes!.length / 1000}kB');
//
//       if (widget.returnVector) {
//         faceEmbedding = _faceService.getFaceEmbedding(croppedImage);
//         if (faceEmbedding!.isEmpty) {
//           throw Exception("No face detected in the image");
//         }
//         print("Generated Embedding: ${faceEmbedding!.take(10).toList()}...");
//       }
//
//       setState(() {
//         _isLoading = false;
//         showImagePreview = true;
//       });
//     } catch (e) {
//       print('Error capturing or cropping picture: $e');
//       _showPopup("Something went wrong. Please try again.");
//       setState(() {
//         _isLoading = false;
//         showImagePreview = false;
//       });
//     }
//   }
//
//   Future<void> _processAndUpload(Uint8List bytes) async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     actualImageSize ??= bytes.length;
//     print("Image size is ${bytes.length / 1000}kB");
//
//     while (widget.imageSizeShouldBeLessThan200kB && bytes.length / 1000 >= 250) {
//       print("Decreasing image size");
//       final img.Image? image = img.decodeImage(bytes);
//       if (image == null) break;
//
//       final newWidth = (image.width * 0.9).toInt();
//       final newHeight = (image.height * 0.9).toInt();
//       final resizedImage = img.copyResize(image, width: newWidth, height: newHeight);
//       bytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
//       print("New image size is ${bytes.length / 1000}kB");
//     }
//
//     try {
//       if (widget.returnVector) {
//         if (faceEmbedding == null) {
//           final img.Image? decodedImage = img.decodeImage(bytes);
//           if (decodedImage == null) {
//             throw Exception("Failed to decode image");
//           }
//           faceEmbedding = _faceService.getFaceEmbedding(decodedImage);
//           if (faceEmbedding!.isEmpty) {
//             throw Exception("No face detected in the image");
//           }
//         }
//         if (savedImageFile == null) {
//           throw Exception("Image file not found");
//         }
//         Navigator.of(context).pop({
//           'image': savedImageFile, // Return the actual File object
//           'vector': faceEmbedding, // Return raw List<double>
//         });
//       } else {
//         List<double> embedding = _faceService.getFaceEmbedding(img.decodeImage(bytes)!);
//         print("Generated Embedding (Vector): ${embedding.take(10).toList()}...");
//         await _sendVectorToServer(embedding);
//         if (widget.callBack != null) widget.callBack!(bytes);
//       }
//     } catch (e) {
//       print('Error processing/uploading picture: $e');
//       _showPopup("Something went wrong. Please try again.");
//       if (mounted) Navigator.of(context).pop();
//     } finally {
//       setState(() {
//         _isLoading = false;
//         showImagePreview = false;
//         savedImageBytes = null;
//         savedImageFile = null; // Clear the file
//         faceEmbedding = null;
//       });
//     }
//   }
//
//   Future<void> _sendVectorToServer(List<double> vector) async {
//     final apiKey = await widget.userSession.apiKey;
//     final userId = await widget.userSession.uid;
//     print('[INFO] Using cId: $apiKey');
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $apiKey'
//     };
//
//     final apiUrlConfig = getIt<ApiUrlConfig>();
//
//     print('headers: $headers');
//
//     final body = jsonEncode({
//       'user_id': userId,
//       'match_type': 'verify',
//       'vector': vector.join(','),
//       'threshold': 0.4
//     });
//
//     final url = Uri.parse(apiUrlConfig.faceVerifyApi);
//
//     final response = await http.post(url, headers: headers, body: body);
//     final decodedResponse = jsonDecode(response.body);
//
//     print('[RESPONSE] Status code: ${response.statusCode}');
//     print('[RESPONSE] Body: $decodedResponse');
//
//     if (response.statusCode == 200) {
//       print('Vector sent successfully');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             decodedResponse['message']?.toString() ?? 'Image uploaded successfully',
//             style: GoogleFonts.poppins(color: Colors.white),
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//       if (mounted) {
//         getIt<MarkAttendanceBloc>().add(
//           MarkAttendance(
//             latitude: _currentPosition.latitude.toString(),
//             longitude: _currentPosition.longitude.toString(),
//           ),
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(
//             builder: (context) => CheckOutScreen(userSession: getIt<UserSession>()),
//           ),
//               (route) => false,
//         );
//       }
//     } else {
//       print('[ERROR] Failed to upload image');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             decodedResponse['message']?.toString() ?? 'Failed to upload image',
//             style: GoogleFonts.poppins(color: Colors.white),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       if (mounted) Navigator.of(context).pop(false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: _initializeCameraFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting || _controller == null || !_controller!.value.isInitialized) {
//           return const Scaffold(
//             backgroundColor: Colors.black,
//             body: Center(
//               child: CircularProgressIndicator(color: Colors.white),
//             ),
//           );
//         }
//
//         if (snapshot.connectionState == ConnectionState.done && _controller != null) {
//           return Scaffold(
//             backgroundColor: Colors.black,
//             body: Stack(
//               fit: StackFit.expand,
//               children: [
//                 SafeArea(
//                   child: Column(
//                     children: [
//                       Expanded(
//                         child: LayoutBuilder(
//                           builder: (_, constraints) {
//                             final screenWidth = constraints.maxWidth;
//                             final screenHeight = constraints.maxHeight;
//                             print('LayoutBuilder constraints: width=$screenWidth, height=$screenHeight');
//                             return GestureDetector(
//                               onDoubleTap: () {
//                                 if (showImagePreview) return;
//                                 _captureAndUpload();
//                               },
//                               child: Center(
//                                 child: Stack(
//                                   fit: StackFit.expand,
//                                   children: [
//                                     if (!showImagePreview)
//                                       CameraPreview(_controller!)
//                                     else
//                                       Image.memory(
//                                         savedImageBytes!,
//                                         fit: BoxFit.contain,
//                                       ),
//                                     if (!showImagePreview && widget.showFrame && widget.cameraType == CameraType.frontCamera)
//                                       CustomPaint(
//                                         painter: _OverlayPainter(
//                                           ovalWidth: _ovalWidth,
//                                           ovalHeight: _ovalHeight,
//                                         ),
//                                         size: Size(screenWidth, screenHeight),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       if (!showImagePreview && widget.showFrame && widget.cameraType == CameraType.frontCamera)
//                         const Padding(
//                           padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
//                           child: Text(
//                             'Please keep your face inside\nthe frame.',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(color: Colors.white, fontSize: 16),
//                           ),
//                         ),
//                       SizedBox(
//                         height: 56,
//                         child: showImagePreview
//                             ? Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   showImagePreview = false;
//                                   savedImageBytes = null;
//                                   savedImageFile = null;
//                                   faceEmbedding = null;
//                                 });
//                               },
//                               child: Column(
//                                 children: const [
//                                   Icon(Icons.refresh, color: Colors.white, size: 30),
//                                   Text(
//                                     "Retake",
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             _isLoading
//                                 ? const CircularProgressIndicator(color: Colors.green)
//                                 : GestureDetector(
//                               onTap: () => _processAndUpload(savedImageBytes!),
//                               child: Column(
//                                 children: const [
//                                   Icon(Icons.done, color: Colors.green, size: 30),
//                                   Text(
//                                     "Done",
//                                     style: TextStyle(color: Colors.green),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             GestureDetector(
//                               onTap: () => Navigator.of(context).pop(),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: const [
//                                   Icon(Icons.clear, color: Colors.white),
//                                   Text(
//                                     "Cancel",
//                                     style: TextStyle(color: Colors.white),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         )
//                             : Stack(
//                           children: [
//                             Row(
//                               children: [
//                                 const Expanded(flex: 4, child: SizedBox()),
//                                 GestureDetector(
//                                   onTap: () => Navigator.of(context).pop(),
//                                   child: Column(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: const [
//                                       Icon(Icons.clear, color: Colors.white),
//                                       Text(
//                                         "Cancel",
//                                         style: TextStyle(color: Colors.white),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 const Expanded(flex: 1, child: SizedBox()),
//                               ],
//                             ),
//                             GestureDetector(
//                               onTap: _captureAndUpload,
//                               child: const _ShutterButton(),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                     ],
//                   ),
//                 ),
//                 if (_isLoading)
//                   Container(
//                     color: Colors.black54,
//                     child: const Center(
//                       child: CircularProgressIndicator(color: Colors.white),
//                     ),
//                   ),
//               ],
//             ),
//           );
//         }
//
//         return const Scaffold(
//           backgroundColor: Colors.black,
//           body: Center(
//             child: Text(
//               'Error initializing camera',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _OverlayPainter extends CustomPainter {
//   final double ovalWidth;
//   final double ovalHeight;
//
//   _OverlayPainter({required this.ovalWidth, required this.ovalHeight});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.black;
//
//     canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
//     canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
//
//     final clearPaint = Paint()..blendMode = BlendMode.clear;
//
//     final ovalRect = Rect.fromCenter(
//       center: Offset(size.width / 2, size.height / 2),
//       width: ovalWidth,
//       height: ovalHeight,
//     );
//
//     canvas.drawOval(ovalRect, clearPaint);
//     canvas.restore();
//
//     final borderPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;
//
//     canvas.drawOval(ovalRect, borderPaint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
//
// class _ShutterButton extends StatelessWidget {
//   const _ShutterButton({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 56,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         shape: BoxShape.circle,
//       ),
//       child: Container(
//         margin: const EdgeInsets.all(4),
//         decoration: BoxDecoration(
//           border: Border.all(color: Colors.black),
//           color: Colors.white,
//           shape: BoxShape.circle,
//         ),
//         child: const SizedBox.expand(),
//       ),
//     );
//   }
// }
