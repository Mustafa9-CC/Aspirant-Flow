import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class NoteStorageService {
  static const String appFolderName = "AspirantFlow";

  static Future<String> getBaseDirectory() async {
    if (Platform.isAndroid) {
      // Use public Documents folder for persistent storage like Obsidian
      return "/storage/emulated/0/Documents/$appFolderName";
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      return p.join(docDir.path, appFolderName);
    }
  }

  static Future<void> initializeFolders() async {
    final base = await getBaseDirectory();
    await Directory(p.join(base, "Notes")).create(recursive: true);
    await Directory(p.join(base, "Attachments", "Images"))
        .create(recursive: true);
    await Directory(p.join(base, "Attachments", "Audio"))
        .create(recursive: true);
  }

  static Future<String> copyToStorage(File file, String category) async {
    final base = await getBaseDirectory();
    final fileName = p.basename(file.path);
    final targetPath = p.join(base, "Attachments", category, fileName);

    // Check if file already exists at target
    if (file.path == targetPath) return targetPath;

    final targetFile = File(targetPath);
    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }

    await file.copy(targetPath);
    return targetPath;
  }

  static Future<void> saveNoteAsFile(StudyNote note) async {
    try {
      final base = await getBaseDirectory();
      final noteDir = Directory(p.join(base, "Notes"));
      if (!await noteDir.exists()) await noteDir.create(recursive: true);

      final noteFile = File(p.join(noteDir.path, "${note.id}.md"));

      final buffer = StringBuffer();
      buffer.writeln("---");
      buffer.writeln("id: ${note.id}");
      buffer.writeln("title: ${note.title}");
      buffer.writeln("lastModified: ${note.lastModified.toIso8601String()}");
      if (note.tags.isNotEmpty) {
        buffer.writeln("tags: [${note.tags.join(", ")}]");
      }
      if (note.voiceNotePath != null) {
        buffer.writeln("voiceNote: ${p.basename(note.voiceNotePath!)}");
      }
      buffer.writeln("---");
      buffer.writeln("");
      buffer.writeln(note.content);

      if (note.imagePaths.isNotEmpty) {
        buffer.writeln("\n## Attachments");
        for (var img in note.imagePaths) {
          buffer.writeln("![[${p.basename(img)}]]");
        }
      }

      await noteFile.writeAsString(buffer.toString());
    } catch (e) {
      print("Error saving note as file: $e");
    }
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Permission.manageExternalStorage for "All files access" (Obsidian style)
      // or just Permission.storage if targeting older SDKs.
      // For modern Android, we usually need MANAGE_EXTERNAL_STORAGE to write to /Documents non-app-specific folders easily.

      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }

      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }
}
