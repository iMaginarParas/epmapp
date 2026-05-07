import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'customer_excel_viewer.dart';

const List<String> kUOMOptions = ['Pcs', 'Kg', 'Ltr', 'Box', 'Mtr', 'Nos'];

// ─────────────────────────────────────────────────────────────
//  Data model for a line item (local only, before submit)
// ─────────────────────────────────────────────────────────────
class OrderLineItem {
  int lineNumber;
  String itemName;
  double qty;
  String uom;
  String remark;

  OrderLineItem({
    required this.lineNumber,
    this.itemName = '',
    this.qty = 1,
    this.uom = 'Pcs',
    this.remark = '',
  });

  Map<String, dynamic> toJson() => {
    'line_number': lineNumber,
    'item_name': itemName,
    'qty': qty,
    'uom': uom,
    'remark': remark.isEmpty ? null : remark,
  };
}

// ─────────────────────────────────────────────────────────────
//  Create / Edit Order Page
// ─────────────────────────────────────────────────────────────
class CreateOrderPage extends StatefulWidget {
  final VoidCallback onOrderCreated;
  final Map<String, dynamic>? existingOrder; // non-null = edit mode

  const CreateOrderPage({
    super.key,
    required this.onOrderCreated,
    this.existingOrder,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final List<OrderLineItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingOrder != null) {
      final o = widget.existingOrder!;
      _customerNameCtrl.text = o['customer_name'] ?? '';
      _locationCtrl.text     = o['customer_location'] ?? '';
      final existingItems = (o['items'] as List?) ?? [];
      if (existingItems.isNotEmpty) {
        for (final item in existingItems) {
          _items.add(OrderLineItem(
            lineNumber: item['line_number'] ?? _items.length + 1,
            itemName:   item['item_name']   ?? '',
            qty:        (item['qty'] as num?)?.toDouble() ?? 1,
            uom:        item['uom']         ?? 'Pcs',
            remark:     item['remark']      ?? '',
          ));
        }
      } else {
        _addItem();
      }
    } else {
      _addItem(); // Start with one empty item
    }
  }

  void _addItem() {
    setState(() {
      _items.add(OrderLineItem(lineNumber: _items.length + 1));
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) {
      showSnack(context, 'Order must have at least one item', error: true);
      return;
    }
    setState(() {
      _items.removeAt(index);
      // Re-number
      for (int i = 0; i < _items.length; i++) {
        _items[i].lineNumber = i + 1;
      }
    });
  }

  /// Opens the Customer Directory viewer and auto-fills name + location
  /// when the user taps "Use" on a row.
  Future<void> _pickFromDirectory() async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerExcelViewerPage(
          onCustomerSelected: (name) {},
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _customerNameCtrl.text = selected;
      });
      showSnack(context, '$selected selected ✓');
    }
  }

  Future<void> _confirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate all items have names
    for (final item in _items) {
      if (item.itemName.trim().isEmpty) {
        showSnack(context, 'Item ${item.lineNumber}: Please enter item name', error: true);
        return;
      }
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(widget.existingOrder != null ? Icons.edit_outlined : Icons.receipt_long,
                color: const Color(0xFF1A56DB)),
            const SizedBox(width: 8),
            Text(widget.existingOrder != null ? 'Confirm Changes' : 'Confirm Order'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Customer', _customerNameCtrl.text.trim()),
            _confirmRow('Location', _locationCtrl.text.trim()),
            _confirmRow('Items', '${_items.length} line item(s)'),
            const Divider(height: 16),
            ..._items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('${item.lineNumber}. ',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  Expanded(child: Text(item.itemName, style: const TextStyle(fontSize: 12))),
                  Text('${item.qty} ${item.uom}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF1A56DB))),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.existingOrder != null ? 'Save Changes' : 'Create Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    final isEdit = widget.existingOrder != null;
    final payload = {
      'customer_name': _customerNameCtrl.text.trim(),
      'customer_location': _locationCtrl.text.trim(),
      'items': _items.map((i) => i.toJson()).toList(),
    };
    try {
      if (isEdit) {
        await ApiService().editOrder(widget.existingOrder!['id'], payload);
      } else {
        await ApiService().createOrder(payload);
      }
      if (mounted) {
        showSnack(context, isEdit ? 'Order updated ✓' : 'Order created successfully ✓');
        widget.onOrderCreated();
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } on NetworkException catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _confirmRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A56DB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
            widget.existingOrder != null ? 'Edit Order' : 'New Order',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _confirmAndSubmit,
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Info Card
            _sectionCard(
              title: 'Customer Details',
              icon: Icons.store_outlined,
              color: const Color(0xFF1A56DB),
              children: [
                // ── Pick from Excel directory ────────────────
                OutlinedButton.icon(
                  onPressed: _pickFromDirectory,
                  icon: const Icon(Icons.table_chart_outlined,
                      size: 16, color: Color(0xFF1A56DB)),
                  label: const Text('Pick from Customer Directory',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1A56DB),
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1A56DB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Customer name required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / Address *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Location required' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Items Section Header
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF1A56DB)),
                const SizedBox(width: 8),
                const Text('Order Items',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const Spacer(),
                Text('${_items.length} item(s)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
            const SizedBox(height: 10),

            // Item Cards
            ..._items.asMap().entries.map((entry) =>
                _ItemCard(
                  key: ValueKey(entry.key),
                  item: entry.value,
                  onChanged: () => setState(() {}),
                  onRemove: () => _removeItem(entry.key),
                ),
            ),

            // Add Item Button
            GestureDetector(
              onTap: _addItem,
              child: Container(
                margin: const EdgeInsets.only(top: 4, bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1A56DB), style: BorderStyle.solid),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Color(0xFF1A56DB), size: 20),
                    SizedBox(width: 8),
                    Text('Add Item',
                        style: TextStyle(color: Color(0xFF1A56DB),
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ),

            // Submit Button (also at bottom for convenience)
            ElevatedButton.icon(
              onPressed: _loading ? null : _confirmAndSubmit,
              icon: Icon(widget.existingOrder != null ? Icons.save_outlined : Icons.receipt_long),
              label: Text(widget.existingOrder != null ? 'Review & Save Changes' : 'Review & Submit Order'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Individual Item Card
// ─────────────────────────────────────────────────────────────
class _ItemCard extends StatefulWidget {
  final OrderLineItem item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ItemCard({super.key, required this.item, required this.onChanged, required this.onRemove});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _remarkCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl   = TextEditingController(text: widget.item.itemName);
    _qtyCtrl    = TextEditingController(text: widget.item.qty == 1 ? '' : widget.item.qty.toString());
    _remarkCtrl = TextEditingController(text: widget.item.remark);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A56DB).withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A56DB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text('${widget.item.lineNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                const Text('Line Item',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A56DB))),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Item Name
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: 18),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) {
                    widget.item.itemName = v;
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 10),
                // Qty + UOM Row
                Row(
                  children: [
                    // Qty
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Qty *',
                          prefixIcon: Icon(Icons.numbers, size: 18),
                          isDense: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        onChanged: (v) {
                          widget.item.qty = double.tryParse(v) ?? 1;
                          widget.onChanged();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // UOM Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: widget.item.uom,
                        decoration: const InputDecoration(
                          labelText: 'UOM',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: kUOMOptions.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            widget.item.uom = v;
                            widget.onChanged();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Remark
                TextField(
                  controller: _remarkCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Remark (optional)',
                    prefixIcon: Icon(Icons.notes, size: 18),
                    isDense: true,
                  ),
                  maxLines: 1,
                  onChanged: (v) {
                    widget.item.remark = v;
                    widget.onChanged();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Section Card helper
// ─────────────────────────────────────────────────────────────
Widget _sectionCard({
  required String title,
  required IconData icon,
  required Color color,
  required List<Widget> children,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.all(14), child: Column(children: children)),
      ],
    ),
  );
}