import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'camera_screen.dart';
import 'constants.dart';
import 'image_recognition.dart';
import 'services/shared_preferences_singleton.dart';

class UploadImagesScreen extends StatefulWidget {
  const UploadImagesScreen({super.key});

  @override
  State<UploadImagesScreen> createState() => _UploadImagesScreenState();
}

class _UploadImagesScreenState extends State<UploadImagesScreen> {
  // Keeping default longitude and latitude of 30Days Technology Office
  bool showLoadingSpinnerOnTop = true,
      showLoadingOverlay = false,
      showTodaysRecords = false,
      imageRequired = true,
      locationRequired = true,
      markAttendanceWithoutLocationAndImage = false,
      ableToSendRequest = true;
  double latitude = 28.6894989, longitude = 76.9533923;
  List<dynamic> imageBytes = [null, null, null];
  List<List<double>?> faceVectors = [null, null, null];

  @override
  void initState() {
    super.initState();
  }

  //------------------ START IMAGE FUNCTIONS---------------------------

  getImage(Uint8List imageBytes) {
    imageBytes = imageBytes;
  }

  addImage(int index) async {
    List<CameraDescription> localCameras;
    try {
      localCameras = await availableCameras();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera access denied")),
      );
      return;
    }

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ImageRecognitionScreen(
          cameras: localCameras, // From standard_app_entry.dart or wherever initialized
          mode: CameraMode.faceRecognition,
        ),
      ),
    );
    if (result != null) {
      File croppedFile = result['image'] as File;
      List<double> vector = result['vector'] as List<double>;

      Uint8List bytes = await croppedFile.readAsBytes();

      log("Captured image size: ${bytes.length ~/ 1000} kB");
      log("Vector length: ${vector.length}");

      setState(() {
        imageBytes[index] = bytes;
        faceVectors[index] = vector;
      });
    }
  }

  //-------------------END IMAGE FUNCTIONS---------------------------

  submitImages() async {
    debugPrint('submitImages() called');

    bool uploadedAllImages =
        imageBytes[0] != null && imageBytes[1] != null && imageBytes[2] != null;
    debugPrint('Uploaded all images: $uploadedAllImages');

    if (!uploadedAllImages) {
      debugPrint('❌ One or more images are null. Aborting upload.');
      return;
    }

    setState(() {
      showLoadingOverlay = true;
    });
    var uri = "$customurl/controller/process/app/face_recog.php";
    debugPrint('Request URL: $uri');

    var bodydata = {
      'uid': SharedPreferencesInstance.getString('uid'),
      'cid': SharedPreferencesInstance.getString('comp_id'),
      'type': 'upload_face_img',
      'files': [
        base64.encode(imageBytes[0]),
        base64.encode(imageBytes[1]),
        base64.encode(imageBytes[2]),
      ],
      'vectors':[
        faceVectors[0]!.map((e) => e.toString()).join(','), // Convert List<double> → comma-separated string
        faceVectors[1]!.map((e) => e.toString()).join(','),
        faceVectors[2]!.map((e) => e.toString()).join(','),
      ]
    };

    debugPrint('Request body prepared');
    debugPrint('UID: ${bodydata['uid']}');
    debugPrint('CID: ${bodydata['cid']}');
    debugPrint('Type: ${bodydata['type']}');
    debugPrint('Files count: ${(bodydata['files'] as List).length}');
    debugPrint('File[0] base64 length: ${(bodydata['files'][0] as String).length}');
    debugPrint('File[1] base64 length: ${(bodydata['files'][1] as String).length}');
    debugPrint('File[2] base64 length: ${(bodydata['files'][2] as String).length}');

    final response = await http.post(Uri.parse(uri),
        body: json.encode(bodydata),
        headers: <String, String>{
          'Accept': 'application/json',
        });

    debugPrint('Response status code: ${response.statusCode}');
    debugPrint('Raw response body: ${response.body}');

    var data = json.decode(response.body);
    debugPrint('Decoded response: $data');

    setState(() {
      showLoadingOverlay = false;
    });
    if (data["status"].toString() == "true") {
      debugPrint('✅ Images uploaded successfully');

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          "Uploaded Images Successfully",
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.green,
      ));
      setState(() {
        showLoadingOverlay = false;
      });
      Navigator.pop(context);
      return;
    }

    debugPrint('❌ Upload failed. Server response: $data');
    setState(() {
      showLoadingOverlay = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
        "Try again",
        textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.red,
    ));
  }

  deleteImage(int index) => setState(() {
        imageBytes[index] = null;
      });

  @override
  Widget build(BuildContext context) {
    bool uploadedAllImages =
        imageBytes[0] != null && imageBytes[1] != null && imageBytes[2] != null;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Card(
                margin: const EdgeInsets.all(6),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xff07a299),
                          ),
                        ),
                      ),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Face Recognition Images",
                          style: TextStyle(
                            color: Color(0xff072a99),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text("Add all 3 Images to Continue",
                          style: TextStyle(
                            color: Color(0xff072a99),
                          )),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          UploadImageBox(
                            imageBytes: imageBytes[0],
                            addImage: () => addImage(0),
                            deleteImage: () => deleteImage(0),
                          ),
                          UploadImageBox(
                            imageBytes: imageBytes[1],
                            addImage: () => addImage(1),
                            deleteImage: () => deleteImage(1),
                          ),
                          UploadImageBox(
                            imageBytes: imageBytes[2],
                            addImage: () => addImage(2),
                            deleteImage: () => deleteImage(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: submitImages,
                              style: ButtonStyle(
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.all(15)),
                                shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                backgroundColor: WidgetStateProperty.all(
                                    uploadedAllImages
                                        ? const Color(0xff072a99)
                                        : Colors.grey),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                elevation: WidgetStateProperty.all(8),
                              ),
                              child: uploadedAllImages
                                  ? const Text(
                                      "Submit Images",
                                    )
                                  : const Text(
                                      "Upload All Images, To Continue",
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showLoadingOverlay)
              SizedBox.expand(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xcc072a99),
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
                        child: Text("Uploading Images",
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
        ),
      ),
    );
  }
}

class UploadImageBox extends StatelessWidget {
  const UploadImageBox({
    super.key,
    @required this.imageBytes,
    @required this.addImage,
    @required this.deleteImage,
  });
  final Uint8List? imageBytes;
  final VoidCallback? addImage, deleteImage;
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: GestureDetector(
      onTap: addImage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.width / 3,
            child: Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                ),
                elevation: 8,
                color: imageBytes != null ? Colors.black : Colors.white,
                child: imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_file_outlined),
                          SizedBox(height: 4),
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text("Click to Upload"))
                        ],
                      )),
          ),
          Card(
            elevation: 6,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: deleteImage,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.delete,
                  color: imageBytes != null ? Colors.red : Colors.grey[300],
                ),
              ),
              if (imageBytes != null)
                IconButton(
                    onPressed: addImage,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.refresh_rounded)),
            ]),
          )
        ],
      ),
    ));
  }
}
