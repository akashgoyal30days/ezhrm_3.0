import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart'; // Import open_file package

// Initialize notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  _ImageToPdfScreenState createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  File? _image;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _requestPermissions();
  }

  // Initialize notification settings with tap handling
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Handle notification tap
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          // Open the PDF file when tapped using open_file
          await OpenFile.open(response.payload);
        }
      },
    );
  }

  // Request storage permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Request storage permissions for Android 12 and below
      if (await Permission.storage.request().isGranted) {
        print("Storage permission granted");
      } else {
        print("Storage permission denied");
      }
      // Request manage external storage for Android 13+
      if (await Permission.manageExternalStorage.request().isGranted) {
        print("Manage external storage permission granted");
      } else {
        print("Manage external storage permission denied");
      }
    }
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selected')),
      );
    }
  }

  // Convert image to PDF and download it
  Future<void> _downloadPdf() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }

    // Create a new PDF document
    final pdf = pw.Document();

    // Load the image as a PdfImage
    final image = pw.MemoryImage(
      File(_image!.path).readAsBytesSync(),
    );

    // Add a page to the PDF with the image
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );

    // Save to Downloads directory for easy access
    Directory? downloadsDirectory;
    try {
      downloadsDirectory =
          Directory('/storage/emulated/0/Download'); // Android Downloads folder
      if (!await downloadsDirectory.exists()) {
        downloadsDirectory = await getDownloadsDirectory(); // Fallback
      }
    } catch (e) {
      downloadsDirectory =
          await getApplicationDocumentsDirectory(); // Fallback to app directory
    }

    final fileName =
        'image_to_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${downloadsDirectory!.path}/$fileName';
    final file = File(filePath);

    // Save the PDF file
    await file.writeAsBytes(await pdf.save());

    // Show notification with tap action
    await _showNotification(filePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF downloaded at: $filePath')),
    );
  }

  // Show download notification with tap action (no file path in message)
  Future<void> _showNotification(String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'PDF Downloaded',
      'Tap to open your PDF', // Simplified message without file path
      platformChannelSpecifics,
      payload: filePath, // File path still passed as payload for tap action
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF Converter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? const Text('No image selected.')
                : Image.file(_image!, height: 300),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _downloadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Download PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
