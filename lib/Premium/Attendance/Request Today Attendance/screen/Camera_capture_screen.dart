import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CustomCameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CustomCameraScreen({super.key, required this.camera});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false, // Audio is not needed for a photo
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Camera Preview fills the screen
                Positioned.fill(
                  child: CameraPreview(_controller),
                ),

                // Semi-transparent overlay with a circular cutout
                const CircularCameraOverlay(),

                // Close button ('X')
                Positioned(
                  top: 50,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 30.0),
                    onPressed: () {
                      // Pop the screen without returning an image path
                      Navigator.of(context).pop();
                    },
                  ),
                ),

                // Prompt text at the top
                const Positioned(
                  top: 100,
                  left: 20,
                  right: 20,
                  child: Text(
                    'Please keep your face inside the frame.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),

                // Capture button and text at the bottom
                Positioned(
                  bottom: 50,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          try {
                            // Ensure the camera is initialized
                            await _initializeControllerFuture;

                            // Take the picture
                            final image = await _controller.takePicture();

                            // If the picture was taken, pop the screen and return its path
                            if (!mounted) return;
                            Navigator.of(context).pop(image.path);
                          } catch (e) {
                            // If an error occurs, log it
                            print('Error taking picture: $e');
                          }
                        },
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Click to capture',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          // While waiting, show a loading indicator.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// This widget creates the overlay effect. No changes are needed here.
class CircularCameraOverlay extends StatelessWidget {
  final double overlayRadius;
  const CircularCameraOverlay({super.key, this.overlayRadius = 150});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CircularOverlayPainter(overlayRadius),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class _CircularOverlayPainter extends CustomPainter {
  final double overlayRadius;
  _CircularOverlayPainter(this.overlayRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = Colors.black.withOpacity(0.7);

    // This creates a path for the entire screen
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // This creates a path for the circular hole
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: overlayRadius));

    // Combine the two paths to create the cutout effect
    final cutoutPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      circlePath,
    );

    canvas.drawPath(cutoutPath, paint);

    // Optionally draw a border around the cutout
    final borderPaint = Paint()
      ..color = Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, overlayRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
