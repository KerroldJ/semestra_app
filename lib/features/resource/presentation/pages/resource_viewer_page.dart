import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xl;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../domain/entities/resource_entity.dart';

class ResourceViewerPage extends ConsumerStatefulWidget {
  final ResourceEntity resource;

  const ResourceViewerPage({super.key, required this.resource});

  @override
  ConsumerState<ResourceViewerPage> createState() => _ResourceViewerPageState();
}

class _ResourceViewerPageState extends ConsumerState<ResourceViewerPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // PDF Viewer
  PdfControllerPinch? _pdfController;
  int _pdfTotalPages = 0;
  int _pdfCurrentPage = 1;

  // Excel / CSV Viewer
  List<String> _sheetNames = [];
  String _selectedSheet = '';
  Map<String, List<List<String>>> _excelSheets = {};
  List<List<String>> _csvRows = [];

  // Plain Text
  String _textContent = '';

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final file = File(widget.resource.filePath);
    if (!await file.exists()) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'File not found on device at:\n${widget.resource.filePath}';
      });
      return;
    }

    final ext = widget.resource.extension.toLowerCase();

    try {
      if (ext == 'pdf') {
        _pdfController = PdfControllerPinch(
          document: PdfDocument.openFile(widget.resource.filePath),
        );
        setState(() => _isLoading = false);
      } else if (ext == 'xlsx' || ext == 'xls') {
        final bytes = await file.readAsBytes();
        final excel = xl.Excel.decodeBytes(bytes);
        final Map<String, List<List<String>>> parsedSheets = {};
        final List<String> names = [];

        for (final table in excel.tables.keys) {
          names.add(table);
          final rows = <List<String>>[];
          final rawRows = excel.tables[table]?.rows ?? [];

          // Find max columns
          int maxCols = 0;
          for (final row in rawRows) {
            if (row.length > maxCols) maxCols = row.length;
          }

          for (final row in rawRows) {
            final rowList = <String>[];
            for (int i = 0; i < maxCols; i++) {
              if (i < row.length) {
                final cellVal = row[i]?.value;
                rowList.add(_formatRawCellValue(cellVal));
              } else {
                rowList.add('');
              }
            }
            rows.add(rowList);
          }
          parsedSheets[table] = rows;
        }

        setState(() {
          _sheetNames = names;
          _selectedSheet = names.isNotEmpty ? names.first : '';
          _excelSheets = parsedSheets;
          _isLoading = false;
        });
      } else if (ext == 'csv') {
        final content = await file.readAsString();
        final rawRows = const CsvToListConverter().convert(content);
        int maxCols = 0;
        for (final row in rawRows) {
          if (row.length > maxCols) maxCols = row.length;
        }
        final formattedRows = <List<String>>[];
        for (final row in rawRows) {
          final rowList = <String>[];
          for (int i = 0; i < maxCols; i++) {
            if (i < row.length) {
              rowList.add(_formatRawCellValue(row[i]));
            } else {
              rowList.add('');
            }
          }
          formattedRows.add(rowList);
        }
        setState(() {
          _csvRows = formattedRows;
          _isLoading = false;
        });
      } else if (ext == 'txt' || ext == 'rtf' || ext == 'log' || ext == 'json' || ext == 'xml') {
        final content = await file.readAsString();
        setState(() {
          _textContent = content;
          _isLoading = false;
        });
      } else {
        // For other files, attempt text read
        try {
          final content = await file.readAsString(encoding: utf8);
          if (content.isNotEmpty && !content.contains('\x00')) {
            _textContent = content;
          }
        } catch (_) {}
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading document preview: $e';
      });
    }
  }

  String _formatRawCellValue(dynamic val) {
    if (val == null) return '';
    String str = val.toString().trim();
    if (str.isEmpty) return '';

    // Clean up raw ISO timestamps (e.g. 2025-05-01T00:00:00.000Z)
    if (str.contains('T') || (str.length >= 10 && str.contains('-') && str.contains(':'))) {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        if (dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
          return DateFormat('yyyy-MM-dd').format(dt);
        } else {
          return DateFormat('yyyy-MM-dd HH:mm').format(dt);
        }
      }
    }

    // Clean trailing .0 in numbers like 1040.0
    if (RegExp(r'^-?\d+\.0+$').hasMatch(str)) {
      return str.split('.').first;
    }

    return str;
  }

  Future<void> _openExternal() async {
    try {
      final result = await OpenFilex.open(widget.resource.filePath);
      if (result.type != ResultType.done && result.type != ResultType.noAppToOpen) {
        if (result.message.isNotEmpty) {
          AppToast.info(result.message);
        }
      }
    } catch (e) {
      AppToast.error('Could not open file externally: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.resource.categoryColor;
    final ext = widget.resource.extension;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF3F5F7),
      appBar: AppBar(
        backgroundColor: isDark ? theme.cardColor : Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ext.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.resource.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.resource.fileName,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppTheme.inkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open with WPS / External App',
            onPressed: _openExternal,
          ),
        ],
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Rendering ${widget.resource.extension.toUpperCase()} document...',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _openExternal,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open in WPS / System App'),
              ),
            ],
          ),
        ),
      );
    }

    final ext = widget.resource.extension.toLowerCase();

    if (ext == 'pdf' && _pdfController != null) {
      return _buildPdfViewer();
    } else if (ext == 'xlsx' || ext == 'xls') {
      return _buildSpreadsheetViewer(
        sheetNames: _sheetNames,
        selectedSheet: _selectedSheet,
        onSheetChanged: (s) => setState(() => _selectedSheet = s),
        rows: _excelSheets[_selectedSheet] ?? [],
      );
    } else if (ext == 'csv') {
      return _buildSpreadsheetViewer(
        sheetNames: const ['Data'],
        selectedSheet: 'Data',
        onSheetChanged: (_) {},
        rows: _csvRows,
      );
    } else if (ext == 'txt' || _textContent.isNotEmpty) {
      return _buildTextViewer();
    } else {
      return _buildDocOverviewViewer();
    }
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        PdfViewPinch(
          controller: _pdfController!,
          scrollDirection: Axis.vertical,
          onDocumentLoaded: (doc) {
            setState(() => _pdfTotalPages = doc.pagesCount);
          },
          onPageChanged: (page) {
            setState(() => _pdfCurrentPage = page);
          },
        ),
        if (_pdfTotalPages > 0)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Page $_pdfCurrentPage of $_pdfTotalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpreadsheetViewer({
    required List<String> sheetNames,
    required String selectedSheet,
    required ValueChanged<String> onSheetChanged,
    required List<List<String>> rows,
  }) {
    return _ExcelSpreadsheetView(
      sheetNames: sheetNames,
      selectedSheet: selectedSheet,
      onSheetChanged: onSheetChanged,
      rows: rows,
      onOpenExternal: _openExternal,
    );
  }

  Widget _buildTextViewer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.hairlineBorder(context)),
        ),
        child: SelectableText(
          _textContent,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13.5,
            height: 1.55,
          ),
        ),
      ),
    );
  }

  Widget _buildDocOverviewViewer() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.resource.categoryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.resource.icon, color: color, size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              widget.resource.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.resource.categoryLabel} • ${widget.resource.formattedSize}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : AppTheme.inkMuted,
              ),
            ),
            const SizedBox(height: 14),
            if (widget.resource.notes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.resource.notes,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 20),
            ],
            ElevatedButton.icon(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open with WPS / Office App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandFill(context),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A WPS / Microsoft Excel grade spreadsheet viewer with column letters (A, B, C...),
/// row numbers (1, 2, 3...), pinch-to-zoom, pan, formula bar, cell inspection,
/// search, and classic Excel worksheet tabs.
class _ExcelSpreadsheetView extends StatefulWidget {
  final List<String> sheetNames;
  final String selectedSheet;
  final ValueChanged<String> onSheetChanged;
  final List<List<String>> rows;
  final VoidCallback onOpenExternal;

  const _ExcelSpreadsheetView({
    required this.sheetNames,
    required this.selectedSheet,
    required this.onSheetChanged,
    required this.rows,
    required this.onOpenExternal,
  });

  @override
  State<_ExcelSpreadsheetView> createState() => _ExcelSpreadsheetViewState();
}

class _ExcelSpreadsheetViewState extends State<_ExcelSpreadsheetView> {
  final TransformationController _transController = TransformationController();
  int? _selectedRow;
  int? _selectedCol;
  bool _isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transController.addListener(() {
      final scale = _transController.value.getMaxScaleOnAxis();
      if ((scale - _currentScale).abs() > 0.05) {
        setState(() => _currentScale = scale);
      }
    });
  }

  @override
  void dispose() {
    _transController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final matrix = _transController.value.clone();
    matrix.scaleByDouble(1.25, 1.25, 1.0, 1.0);
    _transController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transController.value.clone();
    matrix.scaleByDouble(0.8, 0.8, 1.0, 1.0);
    _transController.value = matrix;
  }

  String _getColumnLetter(int colIndex) {
    String name = '';
    int n = colIndex;
    while (n >= 0) {
      name = String.fromCharCode((n % 26) + 65) + name;
      n = (n ~/ 26) - 1;
    }
    return name;
  }

  String _getCellReference(int row, int col) {
    return '${_getColumnLetter(col)}${row + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final excelGreen = const Color(0xFF107C41);

    if (widget.rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('This worksheet is empty',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // Determine grid bounds
    final numRows = widget.rows.length;
    int numCols = 0;
    for (final row in widget.rows) {
      if (row.length > numCols) numCols = row.length;
    }
    if (numCols == 0) numCols = 1;

    // Selected cell content
    String selectedCellRef = 'A1';
    String selectedCellValue = '';
    if (_selectedRow != null && _selectedCol != null) {
      selectedCellRef = _getCellReference(_selectedRow!, _selectedCol!);
      if (_selectedRow! < widget.rows.length &&
          _selectedCol! < widget.rows[_selectedRow!].length) {
        selectedCellValue = widget.rows[_selectedRow!][_selectedCol!];
      }
    } else if (widget.rows.isNotEmpty && widget.rows.first.isNotEmpty) {
      selectedCellRef = 'A1';
      selectedCellValue = widget.rows.first.first;
    }

    // Calculate column widths based on longest content
    final colWidths = <int, double>{};
    for (int c = 0; c < numCols; c++) {
      double maxLen = 0;
      for (int r = 0; r < math.min(numRows, 100); r++) {
        final val = c < widget.rows[r].length ? widget.rows[r][c] : '';
        if (val.length > maxLen) maxLen = val.length.toDouble();
      }
      // Between 95px and 260px
      colWidths[c] = math.max(95.0, math.min(260.0, maxLen * 9.0 + 32.0));
    }

    final gridBorderColor =
        isDark ? const Color(0xFF333842) : const Color(0xFFD6DCE3);
    final headerBgColor =
        isDark ? const Color(0xFF1E222B) : const Color(0xFFF1F4F8);
    final headerTextColor =
        isDark ? const Color(0xFF9DA5B4) : const Color(0xFF4B5563);
    final activeHeaderBg = excelGreen.withValues(alpha: isDark ? 0.35 : 0.15);

    return Column(
      children: [
        // Top Formula / Value Bar (Excel style fx bar)
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            border: Border(
              bottom: BorderSide(color: gridBorderColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Cell Reference Box (e.g. A1, B5)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFE9ECEF),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: gridBorderColor),
                ),
                child: Text(
                  selectedCellRef,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: isDark ? Colors.white : excelGreen,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Formula 'fx' symbol
              Text(
                'fx',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: excelGreen,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 18,
                color: gridBorderColor,
              ),
              const SizedBox(width: 8),
              // Cell Value
              Expanded(
                child: Text(
                  selectedCellValue.isEmpty ? '—' : selectedCellValue,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: selectedCellValue.isEmpty
                        ? (isDark ? Colors.white38 : Colors.grey)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Search button
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  size: 18,
                  color: _isSearching ? excelGreen : headerTextColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Search in sheet',
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchCtrl.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              // Zoom out
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Zoom Out',
                onPressed: _zoomOut,
              ),
              // Zoom in
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: 'Zoom In',
                onPressed: _zoomIn,
              ),
            ],
          ),
        ),

        // Search bar if open
        if (_isSearching)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: isDark ? const Color(0xFF2A2E39) : const Color(0xFFE8EDF2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search in sheet...',
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: isDark ? Colors.black26 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim().toLowerCase());
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_countMatches(widget.rows, _searchQuery)} found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: excelGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),

        // The Full-Fledged Interactive Excel Grid Canvas
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF181A1F) : const Color(0xFFE5E9EE),
            child: InteractiveViewer(
              transformationController: _transController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(200),
              minScale: 0.4,
              maxScale: 3.5,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF21252B) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: gridBorderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP ROW: Corner Cell + Column Letters (A, B, C...)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top-left corner box
                        Container(
                          width: 44,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: headerBgColor,
                            border: Border(
                              right: BorderSide(color: gridBorderColor),
                              bottom: BorderSide(color: gridBorderColor),
                            ),
                          ),
                          child: Icon(Icons.grid_on_rounded,
                              size: 13, color: headerTextColor),
                        ),
                        // Column Headers (A, B, C...)
                        ...List.generate(numCols, (c) {
                          final isColActive = _selectedCol == c;
                          final width = colWidths[c] ?? 110.0;
                          return Container(
                            width: width,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isColActive ? activeHeaderBg : headerBgColor,
                              border: Border(
                                right: BorderSide(color: gridBorderColor),
                                bottom: BorderSide(color: gridBorderColor),
                              ),
                            ),
                            child: Text(
                              _getColumnLetter(c),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isColActive
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: isColActive
                                    ? excelGreen
                                    : headerTextColor,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    // DATA ROWS: Row Number (1, 2, 3...) + Cells
                    ...List.generate(numRows, (r) {
                      final isRowActive = _selectedRow == r;
                      final rowData = widget.rows[r];
                      final isHeaderRow = r == 0;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left Row Number (1, 2, 3...)
                          Container(
                            width: 44,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isRowActive ? activeHeaderBg : headerBgColor,
                              border: Border(
                                right: BorderSide(color: gridBorderColor),
                                bottom: BorderSide(color: gridBorderColor),
                              ),
                            ),
                            child: Text(
                              '${r + 1}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isRowActive
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: isRowActive
                                    ? excelGreen
                                    : headerTextColor,
                              ),
                            ),
                          ),
                          // Cell Columns
                          ...List.generate(numCols, (c) {
                            final width = colWidths[c] ?? 110.0;
                            final cellValue =
                                c < rowData.length ? rowData[c] : '';
                            final isCellSelected =
                                _selectedRow == r && _selectedCol == c;

                            final isSearchMatch = _searchQuery.isNotEmpty &&
                                cellValue.toLowerCase().contains(_searchQuery);

                            // Number detection for right-alignment
                            final isNumber = RegExp(r'^-?[\d,]+(\.\d+)?$')
                                .hasMatch(cellValue);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRow = r;
                                  _selectedCol = c;
                                });
                              },
                              child: Container(
                                width: width,
                                height: 32,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                alignment: isNumber
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: isCellSelected
                                      ? (isDark
                                          ? excelGreen.withValues(alpha: 0.3)
                                          : const Color(0xFFD8F3E5))
                                      : isSearchMatch
                                          ? Colors.yellow.withValues(alpha: 0.4)
                                          : isHeaderRow
                                              ? (isDark
                                                  ? Colors.white.withValues(alpha: 0.04)
                                                  : const Color(0xFFF9FBFC))
                                              : null,
                                  border: isCellSelected
                                      ? Border.all(
                                          color: excelGreen,
                                          width: 2.0,
                                        )
                                      : Border(
                                          right: BorderSide(
                                              color: gridBorderColor,
                                              width: 0.6),
                                          bottom: BorderSide(
                                              color: gridBorderColor,
                                              width: 0.6),
                                        ),
                                ),
                                child: Text(
                                  cellValue,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isHeaderRow
                                        ? FontWeight.w800
                                        : FontWeight.w400,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),

        // BOTTOM EXCEL WORKSHEET TABS BAR (WPS / Excel style)
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : Colors.white,
            border: Border(
              top: BorderSide(color: gridBorderColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Worksheet icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.tab_rounded,
                  size: 18,
                  color: excelGreen,
                ),
              ),
              // Tabs List
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.sheetNames.map((sheet) {
                      final isSelected = widget.selectedSheet == sheet;
                      return InkWell(
                        onTap: () {
                          widget.onSheetChanged(sheet);
                          setState(() {
                            _selectedRow = null;
                            _selectedCol = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF2C313C)
                                    : const Color(0xFFEAF5EE))
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected
                                    ? excelGreen
                                    : Colors.transparent,
                                width: 3,
                              ),
                              right: BorderSide(color: gridBorderColor),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sheet,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? (isDark ? Colors.white : excelGreen)
                                      : headerTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Info summary badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$numRows rows × $numCols cols',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : AppTheme.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _countMatches(List<List<String>> rows, String query) {
    if (query.isEmpty) return 0;
    int count = 0;
    for (final r in rows) {
      for (final cell in r) {
        if (cell.toLowerCase().contains(query)) {
          count++;
        }
      }
    }
    return count;
  }
}
