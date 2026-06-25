import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dictionary_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isSearchToolbarVisible = false;
  late PdfTextSearchResult _searchResult;
  final TextEditingController _searchController = TextEditingController();

  PdfAnnotationMode _annotationMode = PdfAnnotationMode.none;
  Annotation? _selectedAnnotation;
  bool _isDirty = false;
  OverlayEntry? _overlayEntry;

  Color _activeColor = const Color.fromARGB(255, 45, 251, 124);
  double _activeOpacity = 0.5;

  final List<Color> _colors = [
    const Color.fromARGB(255, 45, 251, 124), // Neon Green
    Colors.yellow,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();
    _searchResult = PdfTextSearchResult();
    // Initialize default annotation settings if possible
    _updateAnnotationSettings();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(
      BuildContext context, PdfTextSelectionChangedDetails details) {
    _removeOverlay();
    if (details.selectedText == null || details.globalSelectedRegion == null) {
      return;
    }

    final Rect selectionRect = details.globalSelectedRegion!;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: selectionRect.left,
        top: selectionRect.top - 60, // Adjust depending on menu height
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(blurRadius: 4, color: Colors.black26)
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Default copy behavior usually happens or we can do it manually.
                    // Syncfusion might handle copy if we don't suppress menu, OR we implement copy ourselves.
                    // The user said "option along with copy".
                    // If we suppressed default menu, we MUST implement Copy.
                    // Clipboard.setData(ClipboardData(text: details.selectedText!));
                    // _removeOverlay();
                    // Actually, let's just implement Define button.
                    _showDefinitionDialog(details.selectedText!);
                    _removeOverlay();
                    // Deselect text? _pdfViewerController.clearSelection();
                  },
                  icon: const Icon(Icons.school, size: 18),
                  label: const Text("Define Offline"),
                ),
                // Since we are showing a custom overlay, we might obscure the system menu or exist alongside it.
                // If the system menu is visible, this overlay appears too.
                // Syncfusion's system menu shows Copy/Highlight etc.
                // We just want to ADD "Define Offline".
                // Since we didn't disable system menu (canShowTextSelectionMenu = true by default),
                // this overlay will appear ALONG WITH system menu if positions don't overlap too badly.
                // But typically system menu appears above/below.
                // Let's try to position ours carefully or providing a clear "Define" button.
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showDefinitionDialog(String word) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 350),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DictionaryScreen(
                initialWord: word), // reuse DictionaryScreen logic
          ),
        ),
      ),
    );
  }

  void _updateAnnotationSettings() {
    try {
      _pdfViewerController.annotationSettings.highlight.color = _activeColor;
      _pdfViewerController.annotationSettings.highlight.opacity =
          _activeOpacity;
      _pdfViewerController.annotationSettings.underline.color = _activeColor;
      _pdfViewerController.annotationSettings.underline.opacity =
          _activeOpacity;
    } catch (_) {}
  }

  Future<void> _saveChanges() async {
    try {
      final List<int> bytes = await _pdfViewerController.saveDocument();
      final File file = File(widget.filePath);
      await file.writeAsBytes(bytes);
      if (mounted) {
        setState(() {
          _isDirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    }
  }

  void _onSearchTextChanged(String text) {
    if (text.isEmpty) {
      _searchResult.clear();
      setState(() {});
      return;
    }

    _searchResult = _pdfViewerController.searchText(text);
    _searchResult.addListener(() {
      if (_searchResult.hasResult) {
        setState(() {});
      }
    });
  }

  Widget _buildAnnotationToolbar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildToolButton(
                  icon: Icons.mouse,
                  mode: PdfAnnotationMode.none,
                  tooltip: 'Selection Mode',
                ),
                _buildToolButton(
                  icon: Icons.border_color,
                  mode: PdfAnnotationMode.highlight,
                  tooltip: 'Highlight',
                  color: _activeColor,
                ),
                _buildToolButton(
                  icon: Icons.format_underlined,
                  mode: PdfAnnotationMode.underline,
                  tooltip: 'Underline',
                  color: _activeColor,
                ),
                _buildToolButton(
                  icon: Icons.format_strikethrough,
                  mode: PdfAnnotationMode.strikethrough,
                  tooltip: 'Strikethrough',
                ),
                _buildToolButton(
                  icon: Icons.sticky_note_2,
                  mode: PdfAnnotationMode.stickyNote,
                  tooltip: 'Add Note/Comment',
                ),
                if (_selectedAnnotation != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Annotation',
                    onPressed: () {
                      _pdfViewerController
                          .removeAnnotation(_selectedAnnotation!);
                      setState(() {
                        _selectedAnnotation = null;
                        _isDirty = true;
                      });
                    },
                  ),
                const VerticalDivider(width: 20, indent: 8, endIndent: 8),
                IconButton(
                  icon: Icon(Icons.save,
                      color:
                          _isDirty ? theme.colorScheme.primary : Colors.grey),
                  tooltip: 'Save Changes',
                  onPressed: _isDirty ? _saveChanges : null,
                ),
              ],
            ),
          ),
          if (_annotationMode == PdfAnnotationMode.highlight ||
              _annotationMode == PdfAnnotationMode.underline)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text("Color: ",
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: SizedBox(
                      height: 30,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colors.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final color = _colors[index];
                          final isSelected = _activeColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _activeColor = color;
                                _updateAnnotationSettings();
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text("Opacity: ",
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 100,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 12),
                      ),
                      child: Slider(
                        value: _activeOpacity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (val) {
                          setState(() {
                            _activeOpacity = val;
                            _updateAnnotationSettings();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required PdfAnnotationMode mode,
    required String tooltip,
    Color? color,
  }) {
    final isSelected = _annotationMode == mode;
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: IconButton(
          icon: Icon(icon,
              color:
                  isSelected ? Theme.of(context).colorScheme.primary : color),
          onPressed: () {
            setState(() {
              _annotationMode = mode;
              _pdfViewerController.annotationMode = mode;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);

        final navigate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Save changes?'),
            content: const Text(
                'You have unsaved annotations. Do you want to save them before leaving?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Just leave
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(true), // Save and leave
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (navigate == null) return; // Dialog dismissed

        if (navigate == true) {
          await _saveChanges();
        }

        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearchToolbarVisible
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: GoogleFonts.outfit(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search in PDF...',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearchTextChanged,
                  onSubmitted: (text) => _onSearchTextChanged(text),
                )
              : Text(
                  widget.fileName,
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
          actions: [
            if (_isSearchToolbarVisible) ...[
              if (_searchResult.hasResult) ...[
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    _searchResult.previousInstance();
                  },
                ),
                Center(
                  child: Text(
                    '${_searchResult.currentInstanceIndex} / ${_searchResult.totalInstanceCount}',
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () {
                    _searchResult.nextInstance();
                  },
                ),
              ],
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSearchToolbarVisible = false;
                    _searchController.clear();
                    _searchResult.clear();
                  });
                },
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearchToolbarVisible = true;
                  });
                },
              ),
          ],
        ),
        body: Column(
          children: [
            _buildAnnotationToolbar(),
            Expanded(
              child: SfPdfViewer.file(
                File(widget.filePath),
                controller: _pdfViewerController,
                key: _pdfViewerKey,
                onAnnotationSelected: (Annotation annotation) {
                  setState(() {
                    _selectedAnnotation = annotation;
                  });
                },
                onAnnotationDeselected: (Annotation annotation) {
                  setState(() {
                    _selectedAnnotation = null;
                  });
                },
                onAnnotationAdded: (Annotation annotation) {
                  setState(() {
                    _isDirty = true;
                  });
                },
                enableTextSelection: true,
                canShowTextSelectionMenu: true,
                onTextSelectionChanged:
                    (PdfTextSelectionChangedDetails details) {
                  if (details.selectedText != null &&
                      details.globalSelectedRegion != null) {
                    _showOverlay(context, details);
                  } else {
                    _removeOverlay();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
