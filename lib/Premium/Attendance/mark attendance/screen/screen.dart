// import 'dart:convert';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:ezhrm/Authentication/User%20Information/user_session.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
// import 'Attendance/mark attendance/bloc/mark_attendance_bloc.dart';
// import 'Attendance/mark attendance/screen/check_out.dart';
// import 'Attendance/mark attendance/screen/new_face_recognition.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'Configuration/ApiUrlConfig.dart';
// import 'Dependency_Injection/dependency_injection.dart';
//
// enum CameraMode { checkIn, faceRecognition }
//
// class CameraScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;
//   final UserSession userSession;
//   final CameraMode mode;
//   const CameraScreen({super.key,required this.userSession, required this.cameras, this.mode = CameraMode.checkIn,});
//
//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   bool _modelLoaded = false;
//   late Future<void> _initializeCameraFuture;
//   final FaceDetector _faceDetector = FaceDetector(
//     options: FaceDetectorOptions(
//       enableContours: false,
//       enableLandmarks: false,
//       enableClassification: false,
//       performanceMode: FaceDetectorMode.fast, // Use fast mode for real-time
//     ),
//   );
//   List<Face> _faces = [];
//   bool _isDetecting = false;
//   int _frameCount = 0;
//   static const int _skipFrames = 5;
//   List<double>? faceEmbedding;
//   Position? _currentPosition;
//   final FaceRecognitionService _faceService = FaceRecognitionService();
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCameraFuture = _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     try {
//       await _faceService.loadModel();
//       _modelLoaded = true;
//       print("Model loaded in screen.");
//       final camera = widget.cameras.firstWhere(
//             (camera) => camera.lensDirection == CameraLensDirection.front,
//         orElse: () => widget.cameras.first,
//       );
//       _controller = CameraController(
//         camera,
//         ResolutionPreset.medium, // Use low resolution for testing
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.yuv420,
//       );
//       await _controller!.initialize();
//       if (!mounted) return;
//
//       await _controller!.startImageStream((CameraImage image) async {
//         if (_isDetecting || _frameCount % _skipFrames != 0) {
//           _frameCount++;
//           return;
//         }
//         _isDetecting = true;
//         _frameCount++;
//
//         try {
//           final inputImage = await compute(_convertCameraImageToInputImage, {
//             'image': image,
//             'sensorOrientation': _controller!.description.sensorOrientation,
//             'isFrontCamera':
//             _controller!.description.lensDirection == CameraLensDirection.front,
//           });
//           final faces = await _faceDetector.processImage(inputImage);
//           if (mounted) {
//             setState(() {
//               _faces = faces;
//               print("Detected ${faces.length} face(s)");
//             });
//           }
//         } catch (e, stackTrace) {
//           print("Error in face detection stream: $e");
//           print("Stack trace: $stackTrace");
//         } finally {
//           _isDetecting = false;
//         }
//       });
//
//       if (mounted) setState(() {});
//     } catch (e, stackTrace) {
//       print("Error initializing camera: $e");
//       print("Stack trace: $stackTrace");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error initializing camera: $e")),
//       );
//     }
//   }
//
//   static InputImage _convertCameraImageToInputImage(Map<String, dynamic> params) {
//     final CameraImage image = params['image'] as CameraImage;
//     final int sensorOrientation = params['sensorOrientation'] as int;
//     final bool isFrontCamera = params['isFrontCamera'] as bool;
//
//     // Convert YUV_420_888 to NV21 byte array
//     final int width = image.width;
//     final int height = image.height;
//     final int yRowStride = image.planes[0].bytesPerRow;
//     final int uvRowStride = image.planes[1].bytesPerRow;
//     final int uvPixelStride = image.planes[1].bytesPerPixel!;
//
//     final Uint8List nv21Bytes = Uint8List(width * height * 3 ~/ 2);
//
//     // Copy Y plane
//     int offset = 0;
//     for (int i = 0; i < height; i++) {
//       nv21Bytes.setRange(
//         offset,
//         offset + width,
//         image.planes[0].bytes,
//         i * yRowStride,
//       );
//       offset += width;
//     }
//
//     // Interleave V and U data (NV21 format = Y + VU)
//     final int uvHeight = height ~/ 2;
//     for (int i = 0; i < uvHeight; i++) {
//       for (int j = 0; j < width ~/ 2; j++) {
//         final int uIndex = i * uvRowStride + j * uvPixelStride;
//         final int vIndex = i * uvRowStride + j * uvPixelStride;
//
//         nv21Bytes[offset++] = image.planes[2].bytes[vIndex]; // V
//         nv21Bytes[offset++] = image.planes[1].bytes[uIndex]; // U
//       }
//     }
//
//     // Create InputImage
//     final inputImageMetadata = InputImageMetadata(
//       size: Size(width.toDouble(), height.toDouble()),
//       rotation: _cameraRotationToInputImageRotation(sensorOrientation, isFrontCamera),
//       format: InputImageFormat.nv21,
//       bytesPerRow: yRowStride,
//     );
//
//     return InputImage.fromBytes(
//       bytes: nv21Bytes,
//       metadata: inputImageMetadata,
//     );
//   }
//
//   static InputImageRotation _cameraRotationToInputImageRotation(
//       int sensorOrientation, bool isFrontCamera) {
//     switch (sensorOrientation) {
//       case 0:
//         return isFrontCamera
//             ? InputImageRotation.rotation270deg
//             : InputImageRotation.rotation90deg;
//       case 90:
//         return InputImageRotation.rotation0deg;
//       case 180:
//         return isFrontCamera
//             ? InputImageRotation.rotation90deg
//             : InputImageRotation.rotation270deg;
//       case 270:
//         return InputImageRotation.rotation180deg;
//       default:
//         return InputImageRotation.rotation0deg;
//     }
//   }
//
//   Future<void> _captureImage() async {
//     if (_controller == null || !_controller!.value.isInitialized) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Camera not initialized.")),
//       );
//       return;
//     }
//
//     try {
//       await _controller!.stopImageStream();
//       final XFile imageFile = await _controller!.takePicture();
//       final inputImage = InputImage.fromFilePath(imageFile.path);
//       final faces = await _faceDetector.processImage(inputImage);
//
//       if (faces.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No face detected in captured image.")),
//         );
//         if (mounted && _controller != null) {
//           _initializeCamera();
//         }
//         return;
//       }
//
//       // Load the image for cropping
//       final bytes = await imageFile.readAsBytes();
//       final image = img.decodeImage(bytes);
//       if (image == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to decode image.")),
//         );
//         if (mounted && _controller != null) {
//           _initializeCamera();
//         }
//         return;
//       }
//
//       // Get the first face's bounding box
//       final face = faces.first;
//       final rect = face.boundingBox;
//
//       // Adjust coordinates for cropping
//       final x = rect.left.clamp(0, image.width).toInt();
//       final y = rect.top.clamp(0, image.height).toInt();
//       final width = rect.width.clamp(0, image.width - x).toInt();
//       final height = rect.height.clamp(0, image.height - y).toInt();
//
//       // Crop the image
//       final croppedImage = img.copyCrop(image, x: x, y: y, width: width, height: height);
//
//       // Generate face embedding
//       try {
//         final embedding = _faceService.getFaceEmbedding(croppedImage);
//         setState(() {
//           faceEmbedding = embedding;
//         });
//         print("Face embedding vectors: $embedding");
//         print("Embedding length: ${embedding.length}");
//       }
//       catch (e, stackTrace) {
//         print("Error generating face embedding: $e");
//         print("Stack trace: $stackTrace");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error generating face embedding: $e")),
//         );
//       }
//
//       // Save the cropped image
//       final tempDir = await getTemporaryDirectory();
//       final croppedFile = await File('${tempDir.path}/cropped_face_${DateTime.now().millisecondsSinceEpoch}.jpg')
//           .writeAsBytes(img.encodeJpg(croppedImage));
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Cropped face saved to ${croppedFile.path}")),
//       );
//
//       if (widget.mode == CameraMode.faceRecognition) {
//         if (mounted) {
//           Navigator.pop(context, {
//             'image': croppedFile,
//             'vector': faceEmbedding,
//           });
//         }
//       }
//       else {
//         await _sendVectorToServer(faceEmbedding!);
//       }
//     } catch (e, stackTrace) {
//       print("Error capturing image: $e");
//       print("Stack trace: $stackTrace");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error capturing image: $e")),
//       );
//       if (mounted && _controller != null) {
//         _initializeCamera();
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _controller?.stopImageStream();
//     _controller?.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }
//
//   Future<void> _sendVectorToServer(List<double> vector) async {
//
//     final uid = await widget.userSession.uid;
//     final apiKey = await widget.userSession.apiKey;
//     print('[INFO] Using api key: $apiKey');
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $apiKey'
//     };
//
//     final apiUrlConfig = getIt<ApiUrlConfig>();
//     _currentPosition = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//
//     print('headers: $headers');
//
//     final body = jsonEncode({
//       'user_id': uid,
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
//             style: const TextStyle(color: Colors.white),
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//       if (mounted) {
//         getIt<MarkAttendanceBloc>().add(
//           MarkAttendance(
//             latitude: _currentPosition!.latitude.toString(),
//             longitude: _currentPosition!.longitude.toString(),
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
//             style: const TextStyle(color: Colors.white),
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
//     final screenWidth = MediaQuery.of(context).size.width;
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: FutureBuilder<void>(
//         future: _initializeCameraFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done && _controller != null) {
//             return Stack(
//               fit: StackFit.expand,
//               children: [
//                 CameraPreview(_controller!),
//                 CustomPaint(
//                   painter: FaceBoxPainter(
//                     faces: _faces,
//                     imageSize: _controller!.value.previewSize ?? Size.zero,
//                     isFrontCamera:
//                     _controller!.description.lensDirection == CameraLensDirection.front,
//                   ),
//                 ),
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Padding(
//                     padding: EdgeInsets.all(screenWidth * 0.08),
//                     child: FloatingActionButton(
//                       backgroundColor: const Color(0xFF0D986A),
//                       onPressed: _captureImage,
//                       child: const Icon(Icons.camera_alt, size: 30),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }
//
// class FaceBoxPainter extends CustomPainter {
//   final List<Face> faces;
//   final Size imageSize;
//   final bool isFrontCamera;
//
//   FaceBoxPainter({required this.faces, required this.imageSize, required this.isFrontCamera});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.green
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0;
//
//     for (final face in faces) {
//       final rect = face.boundingBox;
//       final scaleX = size.width / imageSize.height;
//       final scaleY = size.height / imageSize.width;
//
//       final scaledRect = Rect.fromLTRB(
//         isFrontCamera ? size.width - rect.right * scaleX : rect.left * scaleX,
//         rect.top * scaleY,
//         isFrontCamera ? size.width - rect.left * scaleX : rect.right * scaleX,
//         rect.bottom * scaleY,
//       );
//
//       canvas.drawRect(scaledRect, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant FaceBoxPainter oldDelegate) {
//     return oldDelegate.faces != faces ||
//         oldDelegate.imageSize != imageSize ||
//         oldDelegate.isFrontCamera != isFrontCamera;
//   }
// }
