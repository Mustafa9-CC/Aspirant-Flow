import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import '../models/models.dart';
import 'pdf_viewer_screen.dart';
import 'note_editor_screen.dart';
import '../services/device_storage_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dictionary_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<FileSystemEntity> _scannedFiles = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Auto-scan on first load to find device files automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanDevice();
    });
  }

  Future<void> _scanDevice() async {
    setState(() => _isScanning = true);

    bool granted = await DeviceStorageService.requestPermission();
    if (granted) {
      try {
        final files = await DeviceStorageService.scanForDocuments();
        setState(() {
          _scannedFiles = files;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found ${_scannedFiles.length} files')),
          );
        }
      } catch (e) {
        // Handle scan error silently or log it properly
      }
    } else {
      if (mounted) {
        // Open settings if permanently denied
        openAppSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Storage permission required to scan files')),
        );
      }
    }

    setState(() => _isScanning = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'txt',
        'ppt',
        'pptx',
        'xls',
        'xlsx'
      ],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(file.path);
      final newPath = p.join(appDir.path, fileName);

      // Copy file to app directory to ensure persistence
      await file.copy(newPath);

      final doc = StudyDocument(
        id: const Uuid().v4(),
        path: newPath,
        name: fileName,
        type: p.extension(fileName).replaceFirst('.', ''), // remove dot
        dateAdded: DateTime.now(),
      );

      final box = Hive.box<StudyDocument>('study_documents');
      box.add(doc);
    }
  }

  void _openDocument(StudyDocument doc) {
    if (doc.type.toLowerCase() == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            filePath: doc.path,
            fileName: doc.name,
          ),
        ),
      );
    } else {
      OpenFilex.open(doc.path);
    }
  }

  void _deleteDocument(StudyDocument doc) {
    // Optional: delete actual file? For now just remove from list.
    // File(doc.path).delete();
    doc.delete();
  }

  Future<void> _deleteNote(StudyNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await note.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Study Material',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          tabs: const [
            Tab(text: 'My Docs'),
            Tab(text: 'Device'),
            Tab(text: 'Notes'),
            Tab(text: 'Dictionary'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index !=
              3) // Hide search bar for Dictionary tab as it has its own
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.2),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentsList(),
                _buildScannedFilesList(),
                _buildNotesList(),
                const DictionaryScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 3
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (_tabController.index == 0) {
                  _uploadDocument();
                } else if (_tabController.index == 1) {
                  _scanDevice();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const NoteEditorScreen()),
                  );
                }
              },
              label: Text(
                _tabController.index == 0
                    ? 'Upload'
                    : _tabController.index == 1
                        ? 'Scan'
                        : 'New Note',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              icon: Icon(_tabController.index == 0
                  ? Icons.upload_file
                  : _tabController.index == 1
                      ? Icons.sync
                      : Icons.edit),
            ),
    );
  }

  Widget _buildScannedFilesList() {
    if (_isScanning) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredFiles = _scannedFiles.where((file) {
      final name = p.basename(file.path).toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (filteredFiles.isEmpty) {
      return Center(
        child: Text(
          'No files found or scanned yet.\nGo to this tab and tap Scan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
        final name = p.basename(file.path);
        final ext = p.extension(file.path).replaceAll('.', '').toUpperCase();

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              ext == 'PDF' ? Icons.picture_as_pdf : Icons.insert_drive_file,
              color: Colors.blueAccent,
            ),
          ),
          title: Text(name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          subtitle: Text(file.path,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey)),
          onTap: () {
            // We can treat it as a StudyDocument temporarily or direct open
            // To annotate, we might need to copy it or open direct.
            // PdfViewerScreen supports file path.
            if (ext == 'PDF') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(
                    filePath: file.path,
                    fileName: name,
                  ),
                ),
              );
            } else {
              OpenFilex.open(file.path);
            }
          },
        );
      },
    );
  }

  Widget _buildDocumentsList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<StudyDocument>('study_documents').listenable(),
      builder: (context, Box<StudyDocument> box, _) {
        final docs = box.values
            .where((doc) => doc.name.toLowerCase().contains(_searchQuery))
            .toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No documents found.\nUpload one to get started!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  doc.type.toLowerCase() == 'pdf'
                      ? Icons.picture_as_pdf
                      : Icons.description,
                  color: Colors.redAccent,
                ),
              ),
              title: Text(doc.name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Added on ${_formatDate(doc.dateAdded)}',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
              ),
              onTap: () => _openDocument(doc),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteDocument(doc),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotesList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<StudyNote>('study_notes').listenable(),
      builder: (context, Box<StudyNote> box, _) {
        final notes = box.values
            .where((note) =>
                note.title.toLowerCase().contains(_searchQuery) ||
                note.content.toLowerCase().contains(_searchQuery))
            .toList();

        if (notes.isEmpty) {
          return Center(
            child: Text(
              'No notes found.\nCreate one to get started!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(note: note),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        note.content,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(note.lastModified),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: () => _deleteNote(note),
                          child: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
