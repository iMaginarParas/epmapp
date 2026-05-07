import 'package:flutter/material.dart';
import 'main.dart';

// ─────────────────────────────────────────────────────────────
//  Customer Directory — loads from backend (admin imports data)
// ─────────────────────────────────────────────────────────────
class CustomerExcelViewerPage extends StatefulWidget {
  final void Function(String name)? onCustomerSelected;

  const CustomerExcelViewerPage({super.key, this.onCustomerSelected});

  @override
  State<CustomerExcelViewerPage> createState() => _CustomerExcelViewerPageState();
}

class _CustomerExcelViewerPageState extends State<CustomerExcelViewerPage> {
  List<String> _all = [];
  List<String> _filtered = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getCustomers();
      setState(() {
        _all = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, 'Failed to load customers', error: true);
    }
  }

  void _onSearch(String q) {
    setState(() {
      _search = q;
      _filtered = q.isEmpty
          ? _all
          : _all.where((n) => n.toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  void _useCustomer(String name) {
    widget.onCustomerSelected?.call(name);
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Customer Directory',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_alt_outlined,
                size: 56, color: Color(0xFF1A56DB)),
          ),
          const SizedBox(height: 20),
          const Text('No customers yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Ask your administrator to import\nthe customer list via Excel.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
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
              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: () => _onSearch(''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${_filtered.length} customer${_filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),

        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text('No results for "$_search"',
                      style: TextStyle(color: Colors.grey.shade400)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final name = _filtered[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1A56DB).withOpacity(0.1),
                          child: Text(name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Color(0xFF1A56DB), fontWeight: FontWeight.w800)),
                        ),
                        title: Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: ElevatedButton(
                          onPressed: () => _useCustomer(name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A56DB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          child: const Text('Use'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}