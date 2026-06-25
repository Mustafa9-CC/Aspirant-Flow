import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dictionary_service.dart';

class DictionaryScreen extends StatefulWidget {
  final String? initialWord;

  const DictionaryScreen({super.key, this.initialWord});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _definition;
  String? _searchedWord;
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialWord != null) {
      _searchController.text = widget.initialWord!;
      _search(widget.initialWord!);
    }
  }

  Future<void> _search(String word) async {
    if (word.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchedWord = word;
      _definition = null;
    });

    final def = await DictionaryService().getDefinition(word.trim());

    setState(() {
      _isLoading = false;
      _definition = def;
    });
  }

  Future<void> _searchOnline() async {
    if (_searchedWord == null) return;
    final url = Uri.parse(
        'https://www.google.com/search?q=define+${Uri.encodeComponent(_searchedWord!)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter word to define...',
              prefixIcon: const Icon(Icons.menu_book),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _search(_searchController.text),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.surfaceVariant.withAlpha(50),
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildResult(),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.spellcheck, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Search for a word to see its definition',
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_definition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Word not found in offline dictionary.',
              style:
                  GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _searchOnline,
              icon: const Icon(Icons.public),
              label: const Text('Search Online'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _searchedWord ?? '',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),
          // Simple handling of potential HTML content in definition
          Text(
            _definition!.replaceAll(
                RegExp(r'<[^>]*>'), ''), // Strip basic HTML tags if any
            style: GoogleFonts.outfit(
              fontSize: 18,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
