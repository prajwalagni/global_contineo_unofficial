import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UpdateChecker {
  static const String updateUrl =
      "https://raw.githubusercontent.com/prajwalagni/global_contineo_unofficial/main/update.json";

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(updateUrl));
      if (response.statusCode == 200) {
        final updateData = jsonDecode(response.body);

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;
        String latestVersion = updateData['version'];
        bool forceUpdate = updateData['force_update'] ?? false;

        if (latestVersion.compareTo(currentVersion) > 0) {
          _showUpdateDialog(
            context,
            updateData['url'],
            updateData['changelog'],
            forceUpdate,
          );
        }
      }
    } catch (e) {
      print("Error checking for updates: $e");
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String downloadUrl,
    String changelog,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // Prevent dismissal for force updates
      builder: (context) => AlertDialog(
        title: const Text("Update Available"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("A new version is available!"),
            const SizedBox(height: 8),
            Text("What's new:\n$changelog"),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Later"),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog
              _downloadAndInstallApk(context, downloadUrl);
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstallApk(
      BuildContext context, String url) async {
    final dio = Dio();
    final tempDir = await getExternalStorageDirectory();
    final filePath = '${tempDir!.path}/app-release.apk';

    try {
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            _showDownloadProgress(context, progress);
          }
        },
      );

      // Open the downloaded APK file
      await OpenFile.open(filePath);
    } catch (e) {
      print("Download failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Download failed. Please try again."),
        ),
      );
    }
  }

  static void _showDownloadProgress(BuildContext context, double progress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Downloading Update"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text("${(progress * 100).toStringAsFixed(1)}%"),
          ],
        ),
      ),
    );
  }
}
