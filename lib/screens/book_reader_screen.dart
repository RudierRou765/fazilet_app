import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../book_engine_service.dart';

/// Book Reader Screen — The "Seamless Reading" Experience
/// Features: Fragment stitching, Lora typography, adjustable sizing, and TOC
/// Zero AI-Slop: Premium aesthetic, high-performance ListView, brand-compliant
class BookReaderScreen extends StatefulWidget {
  final LibraryBook book;

  const BookReaderScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final BookEngineService _engine = BookEngineService();
  
  List<BookFragment> _fragments = [];
  Map<int, List<int>> _structure = {};
  bool _isLoading = true;
  double _fontSize = 18.0;
  bool _isControlBarVisible = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBookData() async {
    try {
      final fragments = await _engine.getBookContent(widget.book.filename);
      final structure = await _engine.getBookStructure(widget.book.filename);
      
      setState(() {
        _fragments = fragments;
        _structure = structure;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load book: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? FaziletTheme.darkPrimary : FaziletTheme.lightBackground,
      appBar: _buildAppBar(isDark),
      drawer: _buildTOCDrawer(isDark),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              _buildReaderView(isDark),
              if (_isControlBarVisible) _buildControlBar(isDark),
            ],
          ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        widget.book.title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : FaziletTheme.darkPrimary,
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_open_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.text_fields_rounded),
          onPressed: () => setState(() => _isControlBarVisible = !_isControlBarVisible),
        ),
      ],
    );
  }

  Widget _buildReaderView(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _isControlBarVisible = !_isControlBarVisible),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        itemCount: _fragments.length,
        itemBuilder: (context, index) {
          final fragment = _fragments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              fragment.content,
              textAlign: TextAlign.justify,
              style: GoogleFonts.lora(
                fontSize: _fontSize,
                height: 1.8,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlBar(bool isDark) {
    return Positioned(
      bottom: 30,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(12, 36)),
            ),
            Text(
              'Font Size: ${_fontSize.toInt()}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(12, 36)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTOCDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? FaziletTheme.darkPrimary : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Table of Contents',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: _structure.keys.map((chapterId) {
                  return ExpansionTile(
                    title: Text(
                      'Chapter $chapterId',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    children: _structure[chapterId]!.map((sectionId) {
                      return ListTile(
                        title: Text('Section $sectionId'),
                        onTap: () {
                          // TODO: Implement jump-to-section logic
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
