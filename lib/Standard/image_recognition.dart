import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:ezhrm/Standard/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Premium/Attendance/mark attendance/screen/face_recognition_attendance.dart';
import 'home.dart';

enum CameraMode { checkIn, faceRecognition }

class ImageRecognitionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final CameraMode mode;
  const ImageRecognitionScreen({
    super.key,
    required this.cameras,
    this.mode = CameraMode.checkIn,
  });

  @override
  State<ImageRecognitionScreen> createState() => _ImageRecognitionScreenState();
}

class _ImageRecognitionScreenState extends State<ImageRecognitionScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _modelLoaded = false;
  bool _isProcessing = false;
  late Future<void> _initializeCameraFuture;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      minFaceSize: 0.1, // Detect smaller faces
      performanceMode:
      FaceDetectorMode.accurate, // Use accurate mode for better detection
    ),
  );

  List<Face> _faces = [];
  bool _isDetecting = false;
  int _frameCount = 0;
  static const int _skipFrames =
  3; // Reduced skip frames for more frequent detection
  List<double>? faceEmbedding;
  Position? _currentPosition;
  final FaceRecognitionService _faceService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    _initializeCameraFuture = _initializeCamera();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      await _faceService.loadModel();
      _modelLoaded = true;
      print("Model loaded in screen.");

      final camera = widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => widget.cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset
            .high, // Use higher resolution for better face detection
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;

      await _controller!.startImageStream((CameraImage image) async {
        if (_isDetecting || _frameCount % _skipFrames != 0) {
          _frameCount++;
          return;
        }
        _isDetecting = true;
        _frameCount++;

        try {
          // Use a simpler approach for image conversion
          final inputImage = _convertCameraImageToInputImageSimple(image);
          final faces = await _faceDetector.processImage(inputImage);

          // Debug logging
          print("Face detection - Found ${faces.length} faces");

          if (mounted) {
            setState(() {
              _faces = faces;
            });
          }
        } catch (e, stackTrace) {
          print("Error in face detection stream: $e");
          print("Stack trace: $stackTrace");
        } finally {
          _isDetecting = false;
        }
      });

      if (mounted) setState(() {});
    } catch (e, stackTrace) {
      print("Error initializing camera: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error initializing camera: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  InputImage _convertCameraImageToInputImageSimple(CameraImage image) {
    // For Android, try different approaches based on image format
    if (image.format.group == ImageFormatGroup.yuv420) {
      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _getRotationCorrection(),
        format: InputImageFormat.yuv420,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: inputImageMetadata,
      );
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _getRotationCorrection(),
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: inputImageMetadata,
      );
    } else {
      // Fallback - convert to NV21
      return _convertToNV21(image);
    }
  }

  InputImageRotation _getRotationCorrection() {
    final sensorOrientation = _controller!.description.sensorOrientation;
    final isFrontCamera =
        _controller!.description.lensDirection == CameraLensDirection.front;

    // Simplified rotation logic
    if (isFrontCamera) {
      switch (sensorOrientation) {
        case 90:
          return InputImageRotation.rotation270deg;
        case 180:
          return InputImageRotation.rotation180deg;
        case 270:
          return InputImageRotation.rotation90deg;
        default:
          return InputImageRotation.rotation0deg;
      }
    } else {
      switch (sensorOrientation) {
        case 90:
          return InputImageRotation.rotation90deg;
        case 180:
          return InputImageRotation.rotation180deg;
        case 270:
          return InputImageRotation.rotation270deg;
        default:
          return InputImageRotation.rotation0deg;
      }
    }
  }

  InputImage _convertToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final int ySize = yBuffer.length;
    final int uvSize = uBuffer.length;

    final nv21 = Uint8List(ySize + uvSize * 2);

    // Copy Y channel
    nv21.setRange(0, ySize, yBuffer);

    // Interleave U and V channels
    int uvPixelCount = 0;
    for (int i = 0; i < uvSize; i++) {
      nv21[ySize + uvPixelCount] = vBuffer[i];
      nv21[ySize + uvPixelCount + 1] = uBuffer[i];
      uvPixelCount += 2;
    }

    final inputImageMetadata = InputImageMetadata(
      size: Size(width.toDouble(), height.toDouble()),
      rotation: _getRotationCorrection(),
      format: InputImageFormat.nv21,
      bytesPerRow: yPlane.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: inputImageMetadata,
    );
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _controller!.stopImageStream();
      final XFile imageFile = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showMessage(
            "No face detected. Please position your face in the frame.", false);
        if (mounted && _controller != null) {
          _initializeCamera();
        }
        return;
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        _showMessage("Failed to process image. Please try again.", false);
        if (mounted && _controller != null) {
          _initializeCamera();
        }
        return;
      }

      final face = faces.first;
      final rect = face.boundingBox;

      final x = rect.left.clamp(0, image.width).toInt();
      final y = rect.top.clamp(0, image.height).toInt();
      final width = rect.width.clamp(0, image.width - x).toInt();
      final height = rect.height.clamp(0, image.height - y).toInt();

      final croppedImage =
      img.copyCrop(image, x: x, y: y, width: width, height: height);

      try {
        final embedding = _faceService.getFaceEmbedding(croppedImage);
        setState(() {
          faceEmbedding = embedding;
        });
      } catch (e) {
        print("Error generating face embedding: $e");
        _showMessage("Error processing face data. Please try again.", false);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final croppedFile = await File(
          '${tempDir.path}/cropped_face_${DateTime.now().millisecondsSinceEpoch}.jpg')
          .writeAsBytes(img.encodeJpg(croppedImage));

      if (widget.mode == CameraMode.faceRecognition) {
        if (mounted) {
          Navigator.pop(context, {
            'image': croppedFile,
            'vector': faceEmbedding,
          });
        }
      } else {
        await _sendVectorToServer(faceEmbedding!);
      }
    } catch (e) {
      print("Error capturing image: $e");
      _showMessage("Error capturing image. Please try again.", false);
      if (mounted && _controller != null) {
        _initializeCamera();
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
        isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector.close();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _sendVectorToServer(List<double> vector) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('uid');
    final imageApiKey = prefs.getString('api_key');

    final uid = userId;
    final apiKey = imageApiKey;

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    };

    // final apiUrlConfig = getIt<ApiUrlConfig>();
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final body = jsonEncode({
      'user_id': uid,
      'match_type': 'verify',
      'vector': vector.join(','),
      'threshold': 0.4
    });

    final url = Uri.parse(imageVerifyApi);
    final response = await http.post(url, headers: headers, body: body);
    final decodedResponse = jsonDecode(response.body);
    debugPrint('Send vector server response is $decodedResponse');

    if (response.statusCode == 200) {
      if (mounted) {
        final int faceRateValue =
        (decodedResponse['match_percentage'] ?? 0.0).round();

        if(mounted){
          Navigator.pop(context , {
            'faceRate': faceRateValue,
            'sendRequest' : false,
          });
        }
      }
    }
    else {
      // _showMessage(
      //     decodedResponse['message']?.toString() ??
      //         'Authentication failed. Please try again.',
      //     false);
      // if (mounted) Navigator.of(context).pop(false);
      debugPrint('Authentication failed. ${decodedResponse['message']?.toString()}');
      String message = decodedResponse['message']?.toString() ?? '';
      bool hasNoRegisteredVector =
      message.toLowerCase().contains('no registered face vectors');
      bool selectedSendRequest = await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              hasNoRegisteredVector
              ? "Images are not uploaded or approved yet."
                  : "Face not matched",
              style: const TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                style: ButtonStyle(
                    foregroundColor:
                    WidgetStateProperty.all(const Color(0xff072a99))),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ButtonStyle(
                    foregroundColor:
                    WidgetStateProperty.all(const Color(0xff072a99))),
                child: const Text("Send Request"),
              ),
            ],
          )) ??
          false;
      if (!selectedSendRequest) return;
      if(mounted){
        Navigator.pop(context , {
          'sendRequest': true,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCheckIn = widget.mode == CameraMode.checkIn;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context); // go back to previous screen
        return false; // prevent default system pop (since we handled it)
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: FutureBuilder<void>(
          future: _initializeCameraFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _controller != null) {
              return Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // Camera Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CameraPreview(_controller!),
                  ),

                  // Gradient Overlays
                  _buildGradientOverlay(),

                  // Face Detection Overlay
                  CustomPaint(
                    painter: EnhancedFaceBoxPainter(
                      faces: _faces,
                      imageSize: _controller!.value.previewSize ?? Size.zero,
                      isFrontCamera: _controller!.description.lensDirection ==
                          CameraLensDirection.front,
                      scanAnimation: _scanAnimation,
                    ),
                  ),
                  // Top Header
                  _buildTopHeader(screenSize, isCheckIn),

                  // Center Guide Frame
                  _buildCenterGuideFrame(screenSize),

                  // Instructions
                  _buildInstructions(screenSize),

                  // Bottom Controls
                  _buildBottomControls(screenSize),
                ],
              );
            } else {
              return _buildLoadingScreen();
            }
          },
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
          stops: const [0.0, 0.25, 0.75, 1.0],
        ),
      ),
    );
  }

  Widget _buildTopHeader(Size screenSize, bool isCheckIn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // IconButton(
        //   onPressed: () => Navigator.of(context).pop(),
        //   icon: Container(
        //     padding: const EdgeInsets.all(8),
        //     decoration: BoxDecoration(
        //       color: Colors.black.withOpacity(0.5),
        //       shape: BoxShape.circle,
        //     ),
        //     child: const Icon(
        //       Icons.arrow_back,
        //       color: Colors.white,
        //       size: 24,
        //     ),
        //   ),
        // ),
        // SizedBox(width: 20),

        Column(
          children: [
            SizedBox(height: 35),
            Text(
              'Face Recognition',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Face Authentication',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCenterGuideFrame(Size screenSize) {
    final frameSize = screenSize.width * 0.7;

    return Positioned(
      top: screenSize.height * 0.25,
      left: (screenSize.width - frameSize) / 2,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: frameSize,
            height: frameSize * 1.1,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withOpacity(0.8),
                width: 3,
              ),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.blue.withOpacity(0.3),
              //     blurRadius: 20,
              //     spreadRadius: 5,
              //   ),
              // ],
            ),
            child: Stack(
              children: [
                // Corner markers
                ...List.generate(
                    4, (index) => _buildCornerMarker(index, frameSize)),
                // Center content
                // Center(
                //   child: Column(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Icon(
                //         Icons.camera_alt,
                //         color: Colors.white.withOpacity(0.7),
                //         size: 60,
                //       ),
                //       const SizedBox(height: 16),
                //       Text(
                //         'Position yourself\nin the frame',
                //         textAlign: TextAlign.center,
                //         style: GoogleFonts.poppins(
                //           color: Colors.white.withOpacity(0.8),
                //           fontSize: 16,
                //           fontWeight: FontWeight.w500,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCornerMarker(int index, double frameSize) {
    final positions = [
      const Alignment(-1, -1), // Top-left
      const Alignment(1, -1), // Top-right
      const Alignment(-1, 1), // Bottom-left
      const Alignment(1, 1), // Bottom-right
    ];

    return Align(
      alignment: positions[index],
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.all(8),
        child: CustomPaint(
          painter: CornerMarkerPainter(index),
        ),
      ),
    );
  }

  Widget _buildInstructions(Size screenSize) {
    return Positioned(
      bottom: screenSize.height * 0.25,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instructions',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '• Look directly at the camera\n• Stay still until capture completes',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(Size screenSize) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Capture button
          GestureDetector(
            onTap: !_isProcessing ? _captureImage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !_isProcessing
                    ? const LinearGradient(
                  colors: [Colors.blue, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.grey.shade600, Colors.grey.shade700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (!_isProcessing ? Colors.blue : Colors.grey)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              )
                  : const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _isProcessing ? 'Processing...' : 'Tap to capture',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing Camera...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we prepare the camera',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedFaceBoxPainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final bool isFrontCamera;
  final Animation<double> scanAnimation;

  EnhancedFaceBoxPainter({
    required this.faces,
    required this.imageSize,
    required this.isFrontCamera,
    required this.scanAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (final face in faces) {
      final rect = face.boundingBox;
      final scaleX = size.width / imageSize.height;
      final scaleY = size.height / imageSize.width;

      final scaledRect = Rect.fromLTRB(
        isFrontCamera ? size.width - rect.right * scaleX : rect.left * scaleX,
        rect.top * scaleY,
        isFrontCamera ? size.width - rect.left * scaleX : rect.right * scaleX,
        rect.bottom * scaleY,
      );

      // Draw filled background
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
        fillPaint,
      );

      // Draw border
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
        paint,
      );

      // Draw corner indicators
      final cornerLength = 20.0;
      final cornerPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      // Top-left corner
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.top + cornerLength),
        Offset(scaledRect.left, scaledRect.top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.top),
        Offset(scaledRect.left + cornerLength, scaledRect.top),
        cornerPaint,
      );

      // Top-right corner
      canvas.drawLine(
        Offset(scaledRect.right - cornerLength, scaledRect.top),
        Offset(scaledRect.right, scaledRect.top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.right, scaledRect.top),
        Offset(scaledRect.right, scaledRect.top + cornerLength),
        cornerPaint,
      );

      // Bottom-left corner
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.bottom - cornerLength),
        Offset(scaledRect.left, scaledRect.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.bottom),
        Offset(scaledRect.left + cornerLength, scaledRect.bottom),
        cornerPaint,
      );

      // Bottom-right corner
      canvas.drawLine(
        Offset(scaledRect.right - cornerLength, scaledRect.bottom),
        Offset(scaledRect.right, scaledRect.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.right, scaledRect.bottom),
        Offset(scaledRect.right, scaledRect.bottom - cornerLength),
        cornerPaint,
      );

      // Draw scanning line animation
      final scanLinePaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final scanY = scaledRect.top + (scaledRect.height * scanAnimation.value);

      canvas.drawLine(
        Offset(scaledRect.left, scanY),
        Offset(scaledRect.right, scanY),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedFaceBoxPainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.isFrontCamera != isFrontCamera ||
        oldDelegate.scanAnimation != scanAnimation;
  }
}

class CornerMarkerPainter extends CustomPainter {
  final int cornerIndex;

  CornerMarkerPainter(this.cornerIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final lineLength = size.width * 0.6;

    switch (cornerIndex) {
      case 0: // Top-left
        canvas.drawLine(
          Offset(0, lineLength),
          const Offset(0, 0),
          paint,
        );
        canvas.drawLine(
          const Offset(0, 0),
          Offset(lineLength, 0),
          paint,
        );
        break;
      case 1: // Top-right
        canvas.drawLine(
          Offset(size.width - lineLength, 0),
          Offset(size.width, 0),
          paint,
        );
        canvas.drawLine(
          Offset(size.width, 0),
          Offset(size.width, lineLength),
          paint,
        );
        break;
      case 2: // Bottom-left
        canvas.drawLine(
          Offset(0, size.height - lineLength),
          Offset(0, size.height),
          paint,
        );
        canvas.drawLine(
          Offset(0, size.height),
          Offset(lineLength, size.height),
          paint,
        );
        break;
      case 3: // Bottom-right
        canvas.drawLine(
          Offset(size.width - lineLength, size.height),
          Offset(size.width, size.height),
          paint,
        );
        canvas.drawLine(
          Offset(size.width, size.height),
          Offset(size.width, size.height - lineLength),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}