import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

// Very basic recursive file finder without external package if desired,
// but checking common directories is safer.
// "files from entire storage" is dangerous on Android 11+.
// We will focus on /storage/emulated/0/Documents, Download, etc.

class DeviceStorageService {
  static Future<bool> requestPermission() async {
    // For Android 11+ (SDK 30+), MANAGE_EXTERNAL_STORAGE is needed for "All files access"
    // ignoring Google Play policy for this personal app context.

    if (Platform.isAndroid) {
      // Try Manage External Storage first
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      // Fallback for older devices
      if (await Permission.storage.request().isGranted) {
        return true;
      }
    }
    return false;
  }

  static Future<List<FileSystemEntity>> scanForDocuments() async {
    List<FileSystemEntity> files = [];

    // We can't easily scan root /storage/emulated/0 recursively without hitting permissions or special folders.
    // Let's target specific common folders.

    final List<String> targetDirs = [
      '/storage/emulated/0/Documents',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Books',
    ];

    for (var dirPath in targetDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          // Recursive list
          await for (var entity
              in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final ext = entity.path.split('.').last.toLowerCase();
              if (['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt']
                  .contains(ext)) {
                files.add(entity);
              }
            }
          }
        } catch (e) {
          print('Error scanning $dirPath: $e');
        }
      }
    }

    return files;
  }
}
