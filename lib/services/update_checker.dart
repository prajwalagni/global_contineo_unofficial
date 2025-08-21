import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class UpdateChecker {
  static const String updateUrl =
      "https://raw.githubusercontent.com/prajwalagni/global_contineo_unofficial/main/update.json";
  static bool forceUpdate = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(updateUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> allUpdateData = jsonDecode(response.body);

        // Get the SharedPreferences instance
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        // Check if beta updates are enabled (default to false if not set)
        final bool betaUpdatesEnabled = prefs.getBool('betaUpdates') ?? false;

        // Select the relevant update channel (stable or beta)
        Map<String, dynamic>? selectedUpdateChannel;
        if (betaUpdatesEnabled) {
          selectedUpdateChannel = allUpdateData['beta'];
        } else {
          selectedUpdateChannel = allUpdateData['stable'];
        }

        // Proceed only if a valid update channel was found
        if (selectedUpdateChannel == null) {
          print(
            "No update data found for the selected channel (beta: $betaUpdatesEnabled).",
          );
          return; // Exit if no data
        }

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version;
        String latestVersion = selectedUpdateChannel['version'];
        String downloadUrl = selectedUpdateChannel['url'];
        String changelog = selectedUpdateChannel['changelog'];
        forceUpdate = selectedUpdateChannel['force_update'] ?? false;
        // You no longer need `betaUpdate` from the JSON directly here,
        // as you're making the decision based on `betaUpdatesEnabled` from SharedPreferences.

        // Compare versions (simple string comparison works for semantic versioning
        // if correctly formatted, e.g., 1.0.0 < 1.1.0).
        // For more robust version comparison (e.g., handling -beta, -rc, etc.),
        // you might use a dedicated version comparison library like `pub_semver`.
        if (latestVersion.compareTo(currentVersion) > 0) {
          _showUpdateDialog(
            context,
            downloadUrl,
            changelog,
            forceUpdate,
            betaUpdatesEnabled, // Pass this to dialog if you want to display "Beta Update"
          );
        } else {
          print(
            "App is up to date for the ${betaUpdatesEnabled ? 'beta' : 'stable'} channel.",
          );
        }
      }
    } catch (e) {
      print("Error checking for updates: $e");
      // Optional: Show a user-friendly message if update check fails
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Failed to check for updates. Please try again later.")),
      // );
    }
  }

  static void _showUpdateDialog(
    BuildContext context,
    String downloadUrl,
    String changelog,
    bool forceUpdate,
    bool isBetaUpdate, // New parameter to indicate if it's a beta update
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate, // Prevent dismissal for force updates
      builder:
          (context) => PopScope(
            canPop: !forceUpdate,
            child: AlertDialog(
              title: Text(
                isBetaUpdate ? "Beta Update Available" : "Update Available",
              ), // Dynamic title
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align text to start
                children: [
                  Text("A new version is available!"),
                  if (isBetaUpdate)
                    const Text(
                      "You are on the beta channel.",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.orange,
                      ),
                    ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(child: Text("What's new:\n$changelog")),
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
                    // Make sure the dialog is popped before starting download dialog
                    // Navigator.of(context).pop();
                    await _downloadAndInstallApk(context, downloadUrl);
                  },
                  child: const Text("Update Now"),
                ),
              ],
            ),
          ),
    );
  }

  static final enableInstallAPKbtn = ValueNotifier<bool>(false);
  static Future<void> _downloadAndInstallApk(
    BuildContext context,
    String url,
  ) async {
    final dio = Dio();
    // Use getApplicationDocumentsDirectory for app-specific files that don't need external access,
    // or getExternalStorageDirectory for shared storage (might need Android 11+ permission handling).
    // For APKs, getExternalStorageDirectory is often used so package installer can access it.
    final Directory? tempDir = await getExternalStorageDirectory();
    if (tempDir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not find storage directory.")),
      );
      return;
    }
    final filePath = '${tempDir.path}/app-release.apk';

    final progressNotifier = ValueNotifier<double>(0.0);

    _showDownloadProgressDialog(context, progressNotifier, enableInstallAPKbtn);

    try {
      WakelockPlus.enable();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progressNotifier.value = received / total;
          }
        },
      );
      WakelockPlus.disable();

      // Ensure the download progress dialog is explicitly closed using its context
      // Navigator.of(context, rootNavigator: true).pop();

      // Request permissions before attempting to install
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (status.isGranted) {
          enableInstallAPKbtn.value = true;
          // await OpenFile.open(filePath);
        } else if (status.isDenied || status.isPermanentlyDenied) {
          // Explain why permission is needed and offer to open settings
          _showPermissionDeniedDialog(context);
        }
      } else {
        // Handle other platforms or simply open the file if it's not Android
        // await OpenFile.open(filePath);
      }
    } catch (e) {
      print("Download failed: $e");
      // Ensure any open dialogs are closed
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: ${e.toString()}")),
      );
    }
  }

  static void _showDownloadProgressDialog(
    BuildContext context,
    ValueNotifier<double> progressNotifier,
    ValueNotifier<bool> enableInstallAPKbtn,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          // Prevent back button dismissal during download
          canPop: false,
          child: AlertDialog(
            title: const Text("Downloading Update"),
            content: ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, value, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: value),
                    const SizedBox(height: 8),
                    Text("${(value * 100).toStringAsFixed(1)}%"),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (forceUpdate) exit(0);
                },
                child: const Text("Cancel"),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: enableInstallAPKbtn,
                builder: (context, value, child) {
                  return ElevatedButton(
                    onPressed:
                        value
                            ? () async {
                              final Directory? tempDir =
                                  await getExternalStorageDirectory();
                              if (tempDir == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Could not find storage directory.",
                                    ),
                                  ),
                                );
                                return;
                              }
                              final filePath =
                                  '${tempDir.path}/app-release.apk';
                              await OpenFilex.open(filePath);
                            }
                            : null,
                    child: const Text("Install"),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Moved _installApk content directly into _downloadAndInstallApk for better flow
  // and added a separate dialog for permission denial.
  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text("Permission Required"),
            content: const Text(
              "To install the update, please grant permission to install unknown apps.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  exit(0);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await _openInstallUnknownAppsSettings(); // Open app settings for the user to grant permission
                  final Directory? tempDir =
                      await getExternalStorageDirectory();
                  if (tempDir == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Could not find storage directory."),
                      ),
                    );
                    return;
                  }
                  final filePath = '${tempDir.path}/app-release.apk';
                  if (Platform.isAndroid) {
                    final status =
                        await Permission.requestInstallPackages.request();
                    // print(status);
                    if (status.isGranted) {
                      // await OpenFile.open(filePath);
                      enableInstallAPKbtn.value = true;
                    } else if (status.isDenied || status.isPermanentlyDenied) {
                      // Explain why permission is needed and offer to open settings
                      _showPermissionDeniedDialog(context);
                    }
                  } else {
                    // Handle other platforms or simply open the file if it's not Android
                    await OpenFilex.open(filePath);
                  }
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
    );
  }

  static Future<void> _openInstallUnknownAppsSettings() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      if (androidInfo.version.sdkInt >= 26) {
        final intent = AndroidIntent(
          action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
          data: 'package:$packageName',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } else {
        // For Android < 8.0, open general settings
        final intent = AndroidIntent(
          action: 'android.settings.SECURITY_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      }
    }
  }
}
