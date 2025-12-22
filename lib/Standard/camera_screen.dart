import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:screenshot/screenshot.dart';
import '../standard_app_entry.dart';

enum CameraType { frontCamera, rearCamera }

class CameraScreen extends StatefulWidget {
  const CameraScreen(
      {this.callBack,
      this.showFrame = true,
      this.cameraType = CameraType.frontCamera,
      this.imageSizeShouldBeLessThan200kB = false,
      this.decreaseImageSizeByHalf = false,
      super.key});
  final Function(Uint8List)? callBack;
  final CameraType cameraType;
  final bool showFrame, imageSizeShouldBeLessThan200kB, decreaseImageSizeByHalf;
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  final _screenshotController = ScreenshotController();
  bool showLoading = true,
      showImagePreview = false,
      currentlyTakingScreenshot = false;
  Uint8List? savedImageBytes;
  bool showloaderwhiledone = false;
  int marginForImage = 15;
  @override
  void dispose() {
    _cameraController!.dispose();
    super.dispose();
  }

  @override
  void initState() {
    initializeCamera();
    super.initState();
    showloaderwhiledone = false;
  }

  initializeCamera() async {
    _cameraController = CameraController(
      widget.cameraType == CameraType.frontCamera ? cameras[1] : cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    setState(() {
      showLoading = false;
    });
  }

  showLoaderDialogwithName(BuildContext context, String message) {
    AlertDialog alert = AlertDialog(
      contentPadding: const EdgeInsets.all(15),
      content: Row(
        children: [
          const CircularProgressIndicator(
            color: Colors.black,
          ),
          Container(
              margin: const EdgeInsets.only(left: 25),
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              )),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  capturePhoto() async {
    var file = await _cameraController!.takePicture();
    savedImageBytes = File(file.path).readAsBytesSync();
    setState(() {
      showImagePreview = true;
    });
  }

  int? actualImageSize;
  done() async {
    setState(() {
      currentlyTakingScreenshot = true;
    });

    if (savedImageBytes == null) return;

    // Decode the image
    img.Image? originalImage = img.decodeImage(savedImageBytes!);
    if (originalImage == null) {
      log("Failed to decode image");
      return;
    }

    int width = originalImage.width;
    int height = originalImage.height;

    // Create a new image with alpha channel (transparent background)
    img.Image croppedImage = img.Image(width: width, height: height, numChannels: 4);
    img.fill(croppedImage, color: img.ColorRgba8(0, 0, 0, 0)); // Fully transparent

    // Center and radius for the oval (ellipse)
    double centerX = width / 2;
    double centerY = height / 2;
    double radiusX = width * 0.35;  // Horizontal radius (~70% of width)
    double radiusY = height * 0.45; // Vertical radius (~90% of height)

    // Apply oval mask
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double dx = (x - centerX) / radiusX;
        double dy = (y - centerY) / radiusY;
        if (dx * dx + dy * dy <= 1.0) {
          // Pixel is inside the oval → copy from original
          img.Pixel pixel = originalImage.getPixel(x, y);
          croppedImage.setPixel(x, y, pixel);
        }
        // Else: remains transparent
      }
    }

    // Optional: Resize to reduce file size further (e.g., max 512px width)
    // croppedImage = img.copyResize(croppedImage, width: 512);

    // Encode as PNG (preserves transparency)
    Uint8List finalBytes = Uint8List.fromList(img.encodePng(croppedImage));

    log("Final oval transparent image size: ${finalBytes.length ~/ 1000} kB");

    // Return the result
    if (widget.callBack != null) {
      widget.callBack!(finalBytes);
    }
    Navigator.pop(context, finalBytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            SafeArea(
                child: showLoading
                    ? Center(
                        child: LoadingAnimationWidget.newtonCradle(
                          color: Colors.white,
                          size: 80,
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (_, constratints) {
                                return GestureDetector(
                                  onDoubleTap: () {
                                    if (showImagePreview) return;
                                    capturePhoto();
                                  },
                                  child: Padding(
                                    padding:
                                        (widget.imageSizeShouldBeLessThan200kB) &&
                                                currentlyTakingScreenshot
                                            ? EdgeInsets.symmetric(
                                                vertical:
                                                    (constratints.maxHeight) /
                                                        marginForImage,
                                                horizontal:
                                                    (constratints.maxWidth) /
                                                        marginForImage,
                                              )
                                            : widget.decreaseImageSizeByHalf &&
                                                    currentlyTakingScreenshot
                                                ? EdgeInsets.symmetric(
                                                    vertical: (constratints
                                                            .maxHeight) /
                                                        10,
                                                    horizontal: (constratints
                                                            .maxWidth) /
                                                        10,
                                                  )
                                                : EdgeInsets.zero,
                                    child: Screenshot(
                                      controller: _screenshotController,
                                      child: Material(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            showImagePreview
                                                ? Transform(
                                                    alignment: Alignment.center,
                                                    transform: widget
                                                                .cameraType ==
                                                            CameraType
                                                                .frontCamera
                                                        ? Matrix4.rotationY(
                                                            math.pi)
                                                        : Matrix4.rotationX(0),
                                                    child: Image.memory(
                                                      savedImageBytes!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : CameraPreview(
                                                    _cameraController!),
                                            if (widget.cameraType ==
                                                    CameraType.frontCamera &&
                                                widget.showFrame)
                                              ColorFiltered(
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                  Colors.black,
                                                  BlendMode.srcOut,
                                                ), // This one will create the magic
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: Colors.black,
                                                        backgroundBlendMode:
                                                            BlendMode.dstOut,
                                                      ), // This one will handle background + difference out
                                                    ),
                                                    SizedBox.expand(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(18.0),
                                                        child: ClipOval(
                                                          child: Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (widget.showFrame &&
                              widget.cameraType == CameraType.frontCamera)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  showImagePreview
                                      ? "Please make sure that your face is inside the Frame"
                                      : "Please Keep Your Face Inside The Frame",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                              height: 56,
                              child: !showImagePreview
                                  ? Stack(
                                      children: [
                                        Row(
                                          children: [
                                            const Spacer(flex: 4),
                                            GestureDetector(
                                              onTap: Navigator.of(context).pop,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Icon(
                                                    Icons.clear,
                                                    color: Colors.white,
                                                  ),
                                                  Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  )
                                                ],
                                              ),
                                            ),
                                            const Spacer(
                                              flex: 1,
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: capturePhoto,
                                          child: const _ShutterButton(),
                                        ),
                                      ],
                                    )
                                  : SizedBox(
                                      height: 56,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                savedImageBytes = null;
                                                showImagePreview = false;
                                              });
                                            },
                                            child: Column(
                                              children: const [
                                                Icon(
                                                  Icons.refresh,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                                Text(
                                                  "Retake",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                )
                                              ],
                                            ),
                                          ),
                                          showloaderwhiledone == false
                                              ? GestureDetector(
                                                  onTap: () {
                                                    showloaderwhiledone = true;
                                                    setState(() {});

                                                    Future.delayed(
                                                        const Duration(
                                                            seconds: 2), () {
                                                      done();
                                                    });
                                                  },
                                                  child: Column(
                                                    children: const [
                                                      Icon(
                                                        Icons.done,
                                                        color: Colors.green,
                                                        size: 30,
                                                      ),
                                                      Text(
                                                        "Done",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.green),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              : const RefreshProgressIndicator(
                                                  color: Colors.green,
                                                ),
                                          GestureDetector(
                                            onTap: Navigator.of(context).pop,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.clear,
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                          const SizedBox(height: 10),
                        ],
                      )),
            if ((widget.imageSizeShouldBeLessThan200kB ||
                    widget.decreaseImageSizeByHalf) &&
                currentlyTakingScreenshot)
              SizedBox.expand(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xff072a99),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingAnimationWidget.threeRotatingDots(
                        color: Colors.white70,
                        size: 60,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("Please wait",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                      )
                    ],
                  ),
                ),
              )
          ],
        ));
  }

  //----------START Widget Functions-----------

  ColorFiltered ovalShape() => ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.black,
          BlendMode.srcOut,
        ), // This one will create the magic
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                backgroundBlendMode: BlendMode.dstOut,
              ), // This one will handle background + difference out
            ),
            SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: ClipOval(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  //----------END Widget Functions-----------
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class MapButton extends StatelessWidget {
  const MapButton(this.iconData, {this.onTap, super.key});
  final IconData iconData;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xff072a99),
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          color: Colors.white,
        ),
      ),
    );
  }
}
