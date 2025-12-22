import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'bottombar_ios.dart/bottombar_ios.dart';

class ViewdocPdf extends StatefulWidget {
  final filepath;
  final documentname;
  const ViewdocPdf(
      {super.key, @required this.filepath, @required this.documentname});

  @override
  State<ViewdocPdf> createState() => _ViewdocPdfState();
}

class _ViewdocPdfState extends State<ViewdocPdf> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.filepath
                .toString()
                .substring(widget.filepath.toString().length - 1)
                .toString() ==
            'g'
        ? Scaffold(
            bottomNavigationBar: const bottombar_ios(),
            appBar: AppBar(
              title: Text(widget.documentname.toString()),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.indigo,
                      Colors.blue.shade600,
                    ],
                  ),
                ),
              ),
            ),
            body: ListView(
              children: [
                // Text(widget.filepath
                //     .toString()
                //     .substring(widget.filepath.toString().length - 1)
                //     .toString()),
                CachedNetworkImage(
                  placeholder: (context, url) => const LinearProgressIndicator(
                    color: Colors.blue,
                  ),
                  imageUrl: widget.filepath.toString(),
                  errorWidget: (context, url, error) => Column(
                    children: const [
                      Icon(
                        Icons.warning,
                        color: Colors.grey,
                        size: 50,
                      ),
                      Text("Image Not Available")
                    ],
                  ),
                )
              ],
            ))
        : Scaffold(
            appBar: AppBar(
              title: Text(widget.documentname.toString()),
            ),
            body: PDFView(filePath: widget.filepath.toString()));
  }
}
