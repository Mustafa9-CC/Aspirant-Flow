import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class NoteEditorScreen extends StatefulWidget {
  final StudyNote? note; // Null if creating new

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late Box<StudyNote> _notesBox;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _notesBox = Hive.box<StudyNote>('study_notes');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return; // Don't save empty notes

    if (widget.note != null) {
      // Update existing
      final updatedNote = StudyNote(
        id: widget.note!.id,
        title: title,
        content: content,
        lastModified: DateTime.now(),
      );
      // We need to find the key to update, relying on HiveObject saving might be easier if we passed the object from the box
      // But since we passed a copy/reference, we can just save it if it's in the box.
      // Actually widget.note is a HiveObject.
      widget.note!
          .delete(); // Delete old version to re-add? No, HiveObject has save().
      // But we can't update fields on the object directly if they are final.
      // So we have to replace it in the box.

      // Find key by ID or just use putAt if we knew index.
      // Easier: delete old, add new? Or just search list.
      // Best: Store key?

      // Let's iterate to find key (not efficient but safe for small lists) or assume ID is unique
      final key = _notesBox.values
          .firstWhere((element) => element.id == widget.note!.id)
          .key;
      _notesBox.put(key, updatedNote);
    } else {
      // Create new
      final newNote = StudyNote(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'Untitled Note' : title,
        content: content,
        lastModified: DateTime.now(),
      );
      _notesBox.add(newNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null ? 'New Note' : 'Edit Note',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _saveNote();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                border: InputBorder.none,
                hintStyle: GoogleFonts.outfit(color: Colors.grey),
              ),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: GoogleFonts.outfit(fontSize: 16),
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Start typing...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
