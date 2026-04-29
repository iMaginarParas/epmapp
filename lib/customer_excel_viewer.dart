import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import 'main.dart';

// ─────────────────────────────────────────────────────────────
//  Customer model parsed from Excel / CSV
// ─────────────────────────────────────────────────────────────
class CustomerRecord {
  final String name;
  final String location;
  final Map<String, String> extra; // any additional columns

  const CustomerRecord({
    required this.name,
    required this.location,
    this.extra = const {},
  });
}

// ─────────────────────────────────────────────────────────────
//  Customer Excel Viewer Page  (Sales Team only)
// ─────────────────────────────────────────────────────────────
class CustomerExcelViewerPage extends StatefulWidget {
  /// Called when the user taps "Use" on a customer row.
  /// Provides the selected [CustomerRecord] back to the caller.
  final void Function(CustomerRecord)? onCustomerSelected;

  const CustomerExcelViewerPage({super.key, this.onCustomerSelected});

  @override
  State<CustomerExcelViewerPage> createState() =>
      _CustomerExcelViewerPageState();
}

class _CustomerExcelViewerPageState
    extends State<CustomerExcelViewerPage> {
  // ── State ──────────────────────────────────────────────────
  List<CustomerRecord> _all = [];
  List<CustomerRecord> _filtered = [];
  List<String> _headers = [];
  String? _fileName;
  bool _loading = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  // ── Column name guesses ────────────────────────────────────
  static const _nameKeys = [
    'customer name', 'customer', 'name', 'client', 'client name',
    'party', 'party name', 'company',
  ];
  static const _locationKeys = [
    'location', 'address', 'city', 'area', 'place',
    'delivery address', 'site',
  ];

  int _guessColumn(List<String> headers, List<String> keys) {
    for (final key in keys) {
      final idx = headers
          .indexWhere((h) => h.toLowerCase().trim() == key);
      if (idx != -1) return idx;
    }
    // Partial match fallback
    for (final key in keys) {
      final idx = headers
          .indexWhere((h) => h.toLowerCase().trim().contains(key));
      if (idx != -1) return idx;
    }
    return -1;
  }

  // ── File picking & parsing ─────────────────────────────────
  Future<void> _pickFile() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (mounted) showSnack(context, 'Could not read file', error: true);
        setState(() => _loading = false);
        return;
      }

      final ext = (file.extension ?? '').toLowerCase();
      List<List<String>> rows = [];

      if (ext == 'csv') {
        rows = _parseCsv(String.fromCharCodes(bytes));
      } else {
        // xlsx / xls
        final excel = xl.Excel.decodeBytes(bytes);
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName]!;
        for (final row in sheet.rows) {
          rows.add(row.map((c) => c?.value?.toString() ?? '').toList());
        }
      }

      _processRows(rows, file.name);
    } catch (e) {
      if (mounted) showSnack(context, 'Parse error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Minimal CSV parser (handles quoted fields with commas)
  List<List<String>> _parseCsv(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    return lines
        .where((l) => l.trim().isNotEmpty)
        .map((line) {
          final fields = <String>[];
          final buf = StringBuffer();
          bool inQuote = false;
          for (int i = 0; i < line.length; i++) {
            final ch = line[i];
            if (ch == '"') {
              inQuote = !inQuote;
            } else if (ch == ',' && !inQuote) {
              fields.add(buf.toString().trim());
              buf.clear();
            } else {
              buf.write(ch);
            }
          }
          fields.add(buf.toString().trim());
          return fields;
        })
        .toList();
  }

  void _processRows(List<List<String>> rows, String fileName) {
    if (rows.isEmpty) {
      showSnack(context, 'File is empty', error: true);
      return;
    }

    final headers =
        rows.first.map((h) => h.trim()).toList();
    final nameIdx    = _guessColumn(headers, _nameKeys);
    final locIdx     = _guessColumn(headers, _locationKeys);

    if (nameIdx == -1) {
      // Show column picker dialog
      _showColumnPickerDialog(headers, rows, fileName);
      return;
    }

    _buildRecords(rows, headers, nameIdx,
        locIdx == -1 ? null : locIdx, fileName);
  }

  void _buildRecords(
    List<List<String>> rows,
    List<String> headers,
    int nameIdx,
    int? locIdx,
    String fileName,
  ) {
    final records = <CustomerRecord>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.isEmpty)) continue;

      String name = nameIdx < row.length ? row[nameIdx] : '';
      String loc  = (locIdx != null && locIdx < row.length)
          ? row[locIdx]
          : '';

      if (name.isEmpty) continue;

      final extra = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        if (j == nameIdx || j == locIdx) continue;
        if (j < row.length && row[j].isNotEmpty) {
          extra[headers[j]] = row[j];
        }
      }

      records.add(CustomerRecord(name: name, location: loc, extra: extra));
    }

    setState(() {
      _headers  = headers;
      _all      = records;
      _fileName = fileName;
      _search   = '';
      _searchCtrl.clear();
      _filtered = records;
    });

    showSnack(context, '${records.length} customers loaded ✓');
  }

  // ── Column picker when auto-detect fails ──────────────────
  Future<void> _showColumnPickerDialog(
      List<String> headers, List<List<String>> rows, String fileName) async {
    int? nameIdx;
    int? locIdx;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.table_chart, color: Color(0xFF1A56DB)),
              SizedBox(width: 8),
              Text('Map Columns', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "We couldn't auto-detect the columns. Please select which columns contain customer name and location.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Customer Name column *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: List.generate(
                  headers.length,
                  (i) => DropdownMenuItem(value: i, child: Text(headers[i])),
                ),
                onChanged: (v) => ss(() => nameIdx = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Location / Address column (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: -1, child: Text('— None —')),
                  ...List.generate(
                    headers.length,
                    (i) => DropdownMenuItem(value: i, child: Text(headers[i])),
                  ),
                ],
                onChanged: (v) => ss(() => locIdx = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: nameIdx == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _buildRecords(rows, headers, nameIdx!,
                          (locIdx == null || locIdx == -1) ? null : locIdx,
                          fileName);
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search ─────────────────────────────────────────────────
  void _onSearch(String q) {
    setState(() {
      _search   = q;
      _filtered = q.isEmpty
          ? _all
          : _all.where((r) {
              final low = q.toLowerCase();
              return r.name.toLowerCase().contains(low) ||
                  r.location.toLowerCase().contains(low) ||
                  r.extra.values.any((v) => v.toLowerCase().contains(low));
            }).toList();
    });
  }

  // ── Use customer ───────────────────────────────────────────
  void _useCustomer(CustomerRecord record) {
    // Always pop with the record — callers can use either
    // onCustomerSelected callback or the Navigator.pop return value.
    if (widget.onCustomerSelected != null) {
      widget.onCustomerSelected!(record);
    }
    Navigator.pop(context, record);
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Directory',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            if (_fileName != null)
              Text(_fileName!,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _pickFile,
            icon: const Icon(Icons.upload_file, color: Colors.white, size: 18),
            label: Text(
              _all.isEmpty ? 'Upload' : 'Replace',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: _all.isEmpty ? _buildEmptyState() : _buildTable(),
    );
  }

  // ── Empty / Upload prompt ──────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_loading)
            const CircularProgressIndicator(color: Color(0xFF1A56DB))
          else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.table_chart_outlined,
                  size: 56, color: Color(0xFF1A56DB)),
            ),
            const SizedBox(height: 20),
            const Text('No customer file loaded',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827))),
            const SizedBox(height: 8),
            Text(
              'Upload an Excel (.xlsx / .xls) or CSV file\ncontaining customer names and locations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Supported: .xlsx  •  .xls  •  .csv',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }

  // ── Customer list ──────────────────────────────────────────
  Widget _buildTable() {
    return Column(
      children: [
        // Search bar
        Container(
          color: const Color(0xFF1A56DB),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search customers…',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white70, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white70, size: 18),
                      onPressed: () => _onSearch(''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),

        // Result count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_filtered.length} customer${_filtered.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              if (_loading) ...[
                const SizedBox(width: 10),
                const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: _filtered.isEmpty
              ? _emptySearch()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _CustomerTile(
                    record: _filtered[i],
                    searchQuery: _search,
                    onUse: () => _useCustomer(_filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _emptySearch() => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text('No results for "$_search"',
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────
//  Customer Tile
// ─────────────────────────────────────────────────────────────
class _CustomerTile extends StatelessWidget {
  final CustomerRecord record;
  final String searchQuery;
  final VoidCallback? onUse;

  const _CustomerTile({
    required this.record,
    required this.searchQuery,
    this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A56DB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                record.name.isNotEmpty
                    ? record.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Color(0xFF1A56DB),
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlightText(record.name, searchQuery,
                      const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  if (record.location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: _highlightText(
                              record.location,
                              searchQuery,
                              TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                        ),
                      ],
                    ),
                  ],
                  // Extra columns
                  if (record.extra.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: record.extra.entries
                          .take(3)
                          .map((e) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.grey.shade100,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text('${e.key}: ${e.value}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600)),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Use button (only shown when called from CreateOrder)
            if (onUse != null) ...[
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onUse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: const Text('Use'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Highlights matched search text in bold+blue
  Widget _highlightText(String text, String query, TextStyle base) {
    if (query.isEmpty) return Text(text, style: base);
    final lower = text.toLowerCase();
    final queryLow = query.toLowerCase();
    final idx = lower.indexOf(queryLow);
    if (idx == -1) return Text(text, style: base);

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: base.copyWith(
              color: const Color(0xFF1A56DB),
              fontWeight: FontWeight.w800,
              backgroundColor:
                  const Color(0xFF1A56DB).withOpacity(0.1),
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}