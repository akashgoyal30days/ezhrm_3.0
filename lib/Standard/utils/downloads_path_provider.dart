import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadsPathProvider {
  static Future<Directory?> get downloadsDirectory async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception("Storage permission not granted");
      }

      final dir = Directory("/storage/emulated/0/Download");
      if (await dir.exists()) {
        return dir;
      } else {
        // fallback if /Download not found
        return await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    }
    return null;
  }
}
