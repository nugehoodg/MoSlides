import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../services/marp_service.dart';
import '../widgets/theme_selector_sheet.dart';

class PreviewScreen extends StatefulWidget {
  final String markdown;
  final String theme;
  final String size;
  final String fontSize;
  final String title;

  const PreviewScreen({
    super.key,
    required this.markdown,
    required this.theme,
    required this.size,
    required this.fontSize,
    required this.title,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late WebViewController _controller;
  late String _currentTheme;
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.theme;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      ));
    _loadAndRender(widget.markdown, _currentTheme);
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }

  Future<String> _embedLocalImages(String markdown) async {
    final regex = RegExp(r'file://(/[^)"\s]+)');
    String result = markdown;
    
    final matches = regex.allMatches(markdown).toList();
    for (final match in matches) {
      if (match.groupCount >= 1) {
        final path = match.group(1)!;
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = path.split('.').last.toLowerCase();
          final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
          
          final dataUri = 'data:$mimeType;base64,$base64String';
          result = result.replaceFirst(match.group(0)!, dataUri);
        }
      }
    }
    return result;
  }

  Future<void> _loadAndRender(String markdown, String theme) async {
    final embeddedMarkdown = await _embedLocalImages(markdown);
    final html = MarpService.generateHtml(
      embeddedMarkdown, 
      theme, 
      size: widget.size, 
      fontSize: widget.fontSize,
    );
    if (!mounted) return;
    _controller.loadHtmlString(html);
  }

  void _reloadWithTheme(String theme) {
    setState(() {
      _currentTheme = theme;
      _isLoading = true;
    });
    _loadAndRender(widget.markdown, theme);
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      // Extract fully pre-rendered HTML DOM directly from the isolated JS context! 
      // Because Native Android Print spoolers usually disable runtime JS engines, causing blank pages.
      final jsResult = await _controller.runJavaScriptReturningResult('''
        (function() {
          const body = stripFrontMatter(MD);
          const slides = body.split(/\\n---\\n|\\n---\$/m).filter(s=>s.trim().length>0);
          let h = '';
          slides.forEach(function(text) {
             h += '<div class="slide">' + parseSlide(text.trim()) + '</div>';
          });
          return h;
        })();
      ''');
      
      final String parsedHtmlDivs = jsonDecode(jsResult as String);

      final htmlContent = MarpService.generatePdfHtml(
        parsedHtmlDivs, 
        _currentTheme, 
        size: widget.size,
        fontSize: widget.fontSize,
      );
      
      final parts = widget.size.split('x');
      final w = double.tryParse(parts[0]) ?? 1360.0;
      final h = double.tryParse(parts[1]) ?? 768.0;
      final customFormat = PdfPageFormat(w, h, marginAll: 0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final bytes = await Printing.convertHtml(
        format: customFormat,
        html: htmlContent,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${widget.title}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported Successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _changeTheme() {
    showThemeSelectorSheet(
      context,
      current: _currentTheme,
      onSelected: _reloadWithTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'PREVIEW — ${_currentTheme.toUpperCase()}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white54,
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Colors.white70),
            tooltip: 'Change theme',
            onPressed: _changeTheme,
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white70),
            tooltip: 'Export PDF',
            onPressed: _isExporting ? null : _exportPdf,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Rendering slides...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
