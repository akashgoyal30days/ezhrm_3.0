import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PoliciesCard extends StatelessWidget {
  final String name;
  final String description;
  final String file;
  const PoliciesCard(
      {super.key,
      required this.name,
      required this.description,
      required this.file});

  Future<void> _openFile(BuildContext context) async {
    try {
      // Try to open directly in browser/external app
      if (await canLaunchUrl(Uri.parse(file))) {
        await launchUrl(Uri.parse(file));
      } else {
        // If direct launch fails, download and open locally
        final response = await http.get(Uri.parse(file));
        final bytes = response.bodyBytes;
        final directory = await getTemporaryDirectory();
        final fileName = file.split('/').last;
        final filePath = '${directory.path}/$fileName';
        final localFile = File(filePath);
        await localFile.writeAsBytes(bytes);
        await OpenFile.open(filePath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          decoration: BoxDecoration(
            color: Color(0x00f7f7f7),
            border: Border.all(
              color: Colors.grey, // Border color
              width: 1.0, // Border width
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 25),
                child: Image.asset(
                  "assets/images/pdf_icon.png",
                  height: 36,
                  width: 36,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )),
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Material(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      _openFile(context);
                      // showDialog(
                      //   context: context,
                      //   builder: (context) => Dialog(
                      //     child: InteractiveViewer(
                      //       panEnabled: true,
                      //       minScale: 0.5,
                      //       maxScale: 3.0,
                      //       child: Image.network(
                      //         file, // Your network image URL
                      //         fit: BoxFit.contain,
                      //       ),
                      //     ),
                      //   ),
                      // );
                      // Your ${name} action
                    },
                    child: Image.asset(
                      "assets/images/eye_icon.png",
                      height: 36,
                      width: 36,
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}
