import 'package:flutter/material.dart';

class DocumentTypePickerDialogBox extends StatelessWidget {
  const DocumentTypePickerDialogBox({
    super.key,
    @required this.camera,
    @required this.gallery,
  });
  final VoidCallback? camera, gallery;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Upload an Image',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff072a99)),
                  ),
                ),
                const Text(
                  "choose a method",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: MediaQuery.of(context).size.width / 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            camera!();
                          },
                          child: Card(
                            color: const Color(0xff072a99),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.camera_alt_sharp,
                                  size: 30,
                                  color: Colors.white,
                                ),
                                Text(
                                  "Camera",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            gallery!();
                          },
                          child: Card(
                            color: const Color(0xff072a99),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.photo_size_select_actual,
                                  size: 30,
                                  color: Colors.white,
                                ),
                                Text(
                                  "Gallery",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    foregroundColor: WidgetStateProperty.all(
                      const Color(0xff072a99),
                    ),
                  ),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
