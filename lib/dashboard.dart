import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'create_order.dart';
import 'customer_excel_viewer.dart';

class DashboardPage extends StatefulWidget {
  final String department;
  final String fullName;
  final String username;
  final String token;

  const DashboardPage({
    super.key,
    required this.department,
    required this.fullName,
    required this.username,
    required this.token,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<SalesDashboardState> _salesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ApiService().setToken(widget.token);
  }

  Widget _buildBody() {
    switch (widget.department) {
      case 'Sales Team':
        return SalesDashboard(key: _salesKey, username: widget.username);
      case 'Invoicing Team':
        return const InvoicingDashboard();
      case 'Manager':
        return const ManagerDashboard();
      case 'Driver':
        return const DriverDashboard();
      case 'Admin':
        return const AdminDashboard();
      default:
        return const Center(child: Text('Unknown department'));
    }
  }

  Widget? _buildFab() {
    if (widget.department != 'Sales Team') return null;
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF1A56DB),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.w700)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateOrderPage(
              onOrderCreated: () => _salesKey.currentState?.load(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = deptColor(widget.department);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      floatingActionButton: _buildFab(),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EPM ORDER DESK',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
            Text(widget.fullName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(deptIcon(widget.department), size: 14),
                const SizedBox(width: 4),
                Text(widget.department,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // ── Customers directory — Sales Team only ──────────
          if (widget.department == 'Sales Team')
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: 'Customer Directory',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerExcelViewerPage(),
                  ),
                );
              },
            ),
          // ── Inventory viewer — Sales Team only ─────────────
          if (widget.department == 'Sales Team')
            IconButton(
              icon: const Icon(Icons.warehouse_outlined),
              tooltip: 'Inventory',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InventoryViewerPage(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared Widgets
// ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

Widget _sectionTitle(String title) => Padding(
  padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
  child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
);

Widget _orderCard(BuildContext context, Map<String, dynamic> order, {List<Widget>? actions}) {
  final status = order['status'] as String;
  return GestureDetector(
    onTap: () => _showOrderDetail(context, order),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(order['order_reference'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: statusColor(status))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(order['customer_name'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(order['customer_location'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text('${order['created_by_username'] ?? ''}  •  ${_fmtDate(order['created_at'])}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    const Spacer(),
                    Text('${(order['items'] as List?)?.length ?? 0} items',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                if (order['invoice_number'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      const Icon(Icons.receipt, size: 13, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('Invoice: ${order['invoice_number']}',
                          style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                if (order['delivered_by'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.check_circle, size: 13, color: Colors.green),
                      const SizedBox(width: 4),
                      Text('Delivered by ${order['delivered_by']} • ${_fmtDate(order['delivered_at'])}',
                          style: const TextStyle(fontSize: 11, color: Colors.green)),
                    ]),
                  ),
                if (order['cancel_reason'] != null && status == 'Cancelled')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      const Icon(Icons.cancel_outlined, size: 13, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(child: Text('Reason: ${order['cancel_reason']}',
                          style: const TextStyle(fontSize: 11, color: Colors.red))),
                    ]),
                  ),
              ],
            ),
          ),
          if (actions != null && actions.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: actions.map((a) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: a)).toList()),
            ),
        ],
      ),
    ),
  );
}

void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
  final status = order['status'] as String;
  final items = (order['items'] as List?) ?? [];
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // Reference + Status
          Row(children: [
            Expanded(child: Text(order['order_reference'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: statusColor(status))),
            ),
          ]),
          const SizedBox(height: 14),
          _detailRow(Icons.person_outline, 'Customer', order['customer_name'] ?? ''),
          _detailRow(Icons.location_on_outlined, 'Location', order['customer_location'] ?? ''),
          _detailRow(Icons.access_time, 'Created', _fmtDate(order['created_at'])),
          _detailRow(Icons.account_circle_outlined, 'By', order['created_by_username'] ?? ''),
          if (order['invoice_number'] != null)
            _detailRow(Icons.receipt, 'Invoice #', order['invoice_number']!),
          if (order['delivered_by'] != null)
            _detailRow(Icons.local_shipping, 'Delivered by',
                '${order['delivered_by']} at ${_fmtDate(order['delivered_at'])}'),
          if (order['cancel_reason'] != null && status == 'Cancelled')
            _detailRow(Icons.cancel_outlined, 'Cancel Reason', order['cancel_reason']!),
          const Divider(height: 24),
          Text('${items.length} Line Item(s)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          ...items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A56DB),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text('${item['line_number']}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item['item_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                    Text('${item['qty']} ${item['uom']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                            color: Color(0xFF1A56DB))),
                  ],
                ),
                if ((item['remark'] ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, left: 30),
                    child: Text('Remark: ${item['remark']}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          )),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Widget _detailRow(IconData icon, String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: Colors.grey.shade500),
      const SizedBox(width: 8),
      SizedBox(width: 80, child: Text(label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500))),
      Expanded(child: Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
    ],
  ),
);

String _fmtDate(dynamic raw) {
  if (raw == null) return '';
  try {
    final dt = DateTime.parse(raw.toString()).toLocal();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return raw.toString();
  }
}

// ─────────────────────────────────────────────────────────────
//  SALES DASHBOARD
// ─────────────────────────────────────────────────────────────
class SalesDashboard extends StatefulWidget {
  final String username;
  const SalesDashboard({super.key, required this.username});

  @override
  State<SalesDashboard> createState() => SalesDashboardState();
}

class SalesDashboardState extends State<SalesDashboard> {
  List<dynamic> _orders = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService().getMyOrders();
      setState(() { _orders = raw; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'All') return _orders;
    return _orders.where((o) => o['status'] == _filter).toList();
  }

  Future<void> _confirmDelete(Map<String, dynamic> order) async {
    final ref = order['order_reference'] ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Order'),
        ]),
        content: Text('Permanently delete order $ref?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService().deleteOrder(order['id']);
      if (mounted) showSnack(context, 'Order $ref deleted');
      load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } on NetworkException catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending   = _orders.where((o) => o['status'] == 'Pending').length;
    final invoiced  = _orders.where((o) => o['status'] == 'Invoiced').length;
    final delivered = _orders.where((o) => o['status'] == 'Delivered').length;

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          Row(children: [
            _StatCard(label: 'Pending',   value: '$pending',   color: Colors.orange,           icon: Icons.hourglass_empty),
            const SizedBox(width: 10),
            _StatCard(label: 'Invoiced',  value: '$invoiced',  color: const Color(0xFF1A56DB), icon: Icons.receipt),
            const SizedBox(width: 10),
            _StatCard(label: 'Delivered', value: '$delivered', color: Colors.green,            icon: Icons.check_circle_outline),
          ]),
          const SizedBox(height: 16),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Invoiced', 'Delivered', 'Cancelled'].map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: sel,
                    selectedColor: const Color(0xFF1A56DB),
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w600, fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),
          _sectionTitle('My Orders (${_filtered.length})'),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            _emptyState('No orders', _filter == 'All' ? 'Tap + New Order to create one' : 'No $_filter orders')
          else
            ..._filtered.map((o) {
              final isPending = o['status'] == 'Pending';
              return _orderCard(
                context,
                o as Map<String, dynamic>,
                actions: isPending ? [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A56DB),
                      side: const BorderSide(color: Color(0xFF1A56DB)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateOrderPage(
                            onOrderCreated: load,
                            existingOrder: o,
                          ),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 14),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => _confirmDelete(o),
                  ),
                ] : null,
              );
            }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INVOICING DASHBOARD
// ─────────────────────────────────────────────────────────────
class InvoicingDashboard extends StatefulWidget {
  const InvoicingDashboard({super.key});

  @override
  State<InvoicingDashboard> createState() => _InvoicingDashboardState();
}

class _InvoicingDashboardState extends State<InvoicingDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getInvoicingDashboard();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  void _showInvoiceDialog(String orderId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Invoice Number'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Invoice #', prefixIcon: Icon(Icons.tag)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await ApiService().markInvoiced(orderId, ctrl.text.trim());
                if (mounted) showSnack(context, 'Marked as Invoiced ✓');
                _load();
              } on ApiException catch (e) {
                if (mounted) showSnack(context, e.message, error: true);
              } on NetworkException catch (e) {
                if (mounted) showSnack(context, e.toString(), error: true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String orderId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Reason for cancellation'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              try {
                await ApiService().cancelOrder(orderId, ctrl.text.trim());
                if (mounted) showSnack(context, 'Order cancelled');
                _load();
              } on ApiException catch (e) {
                if (mounted) showSnack(context, e.message, error: true);
              } on NetworkException catch (e) {
                if (mounted) showSnack(context, e.toString(), error: true);
              }
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending  = (_data?['pending_orders']       as List?) ?? [];
    final invoiced = (_data?['invoiced_orders_today'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _StatCard(label: 'Pending',        value: '${pending.length}',  color: Colors.orange,              icon: Icons.hourglass_empty),
            const SizedBox(width: 10),
            _StatCard(label: 'Invoiced Today', value: '${invoiced.length}', color: const Color(0xFF7E3AF2),    icon: Icons.receipt_long),
          ]),
          _sectionTitle('Pending Orders'),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (pending.isEmpty)
            _emptyState('No pending orders', 'All caught up!')
          else
            ...pending.map((o) => _orderCard(
              context,
              o as Map<String, dynamic>,
              actions: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt, size: 14),
                  label: const Text('Invoice', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A56DB),
                    side: const BorderSide(color: Color(0xFF1A56DB)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => _showInvoiceDialog(o['id']),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => _showCancelDialog(o['id']),
                ),
              ],
            )),
          _sectionTitle('Invoiced Today'),
          if (!_loading && invoiced.isEmpty)
            _emptyState('No invoices today', 'Invoiced orders appear here')
          else
            ...invoiced.map((o) => _orderCard(context, o as Map<String, dynamic>)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  MANAGER DASHBOARD
// ─────────────────────────────────────────────────────────────
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _days = 30;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getManagerDashboard(days: _days);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary    = _data?['summary']            as Map? ?? {};
    final bySalesman = (_data?['orders_by_salesman'] as List?) ?? [];
    final byCustomer = (_data?['orders_by_customer'] as List?) ?? [];
    final byProduct  = (_data?['orders_by_product']  as List?) ?? [];
    final daily      = (_data?['daily_orders']       as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [7, 14, 30, 90].map((d) {
            final selected = _days == d;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${d}d'),
                selected: selected,
                selectedColor: const Color(0xFF057A55),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600, fontSize: 12,
                ),
                onSelected: (_) { setState(() => _days = d); _load(); },
              ),
            );
          }).toList()),
          const SizedBox(height: 12),
          Row(children: [
            _StatCard(label: 'Pending',   value: '${summary['total_pending']   ?? 0}', color: Colors.orange,           icon: Icons.hourglass_empty),
            const SizedBox(width: 8),
            _StatCard(label: 'Invoiced',  value: '${summary['total_invoiced']  ?? 0}', color: const Color(0xFF1A56DB), icon: Icons.receipt),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _StatCard(label: 'Delivered', value: '${summary['total_delivered'] ?? 0}', color: Colors.green,            icon: Icons.check_circle_outline),
            const SizedBox(width: 8),
            _StatCard(label: 'Cancelled', value: '${summary['total_cancelled'] ?? 0}', color: Colors.red,              icon: Icons.cancel_outlined),
          ]),
          if (_loading) ...[
            const SizedBox(height: 40),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            // Daily orders bar chart (simple)
            if (daily.isNotEmpty) ...[
              _sectionTitle('Daily Orders (by salesman)'),
              _DailyChart(data: daily),
            ],

            _sectionTitle('By Salesman'),
            ...bySalesman.map((s) => _statListTile(Icons.person_outline, s['username'], '${s['order_count']} orders', const Color(0xFF1A56DB))),
            if (bySalesman.isEmpty) _emptyState('No data', ''),

            _sectionTitle('By Customer'),
            ...byCustomer.map((c) => _statListTile(Icons.store_outlined, c['customer_name'], '${c['order_count']} orders', const Color(0xFF057A55))),
            if (byCustomer.isEmpty) _emptyState('No data', ''),

            _sectionTitle('By Product'),
            ...byProduct.map((p) => _statListTile(Icons.inventory_2_outlined, p['item_name'], '${p['total_qty']} ${p['uom']}', const Color(0xFF7E3AF2))),
            if (byProduct.isEmpty) _emptyState('No data', ''),
          ],
        ],
      ),
    );
  }

  Widget _statListTile(IconData icon, String title, String trailing, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Text(trailing, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

// Simple bar chart for daily orders
class _DailyChart extends StatelessWidget {
  final List<dynamic> data;
  const _DailyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Group by date, sum counts
    final Map<String, int> byDate = {};
    for (final d in data) {
      final date = d['date'] as String;
      byDate[date] = (byDate[date] ?? 0) + (d['count'] as int);
    }
    final dates = byDate.keys.toList()..sort();
    final maxVal = byDate.values.fold(0, (a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox();

    return Container(
      height: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dates.map((date) {
          final count = byDate[date]!;
          final pct = count / maxVal;
          final label = date.length >= 10 ? '${date.substring(8, 10)}/${date.substring(5, 7)}' : date;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFF057A55))),
                  const SizedBox(height: 2),
                  Container(
                    height: 100 * pct,
                    decoration: BoxDecoration(
                      color: const Color(0xFF057A55).withOpacity(0.7),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DRIVER DASHBOARD
// ─────────────────────────────────────────────────────────────
class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getDriverDashboard();
      setState(() { _orders = (data['invoiced_orders'] as List?) ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  void _showDeliveryDialog(String orderId, String ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _DeliverySheet(
        orderId: orderId,
        orderRef: ref,
        onDone: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _StatCard(label: 'To Deliver', value: '${_orders.length}',
                color: const Color(0xFFE3A008), icon: Icons.local_shipping_outlined),
          ]),
          _sectionTitle('Ready to Deliver'),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_orders.isEmpty)
            _emptyState('No deliveries', 'Invoiced orders appear here')
          else
            ..._orders.map((o) => _orderCard(
              context,
              o as Map<String, dynamic>,
              actions: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_shipping, size: 15),
                  label: const Text('Update Delivery', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3A008),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => _showDeliveryDialog(o['id'], o['order_reference']),
                ),
              ],
            )),
        ],
      ),
    );
  }
}

class _DeliverySheet extends StatefulWidget {
  final String orderId;
  final String orderRef;
  final VoidCallback onDone;

  const _DeliverySheet({required this.orderId, required this.orderRef, required this.onDone});

  @override
  State<_DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends State<_DeliverySheet> {
  bool? _delivered;
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  Uint8List? _photoBytes;

  Future<void> _pickPhoto(ImageSource source) async {
    final result = await ImagePicker().pickImage(
      source: source, imageQuality: 75, maxWidth: 1280,
    );
    if (result == null) return;
    final bytes = await result.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<void> _submit() async {
    if (_delivered == null) return;
    if (_delivered == true && _photoBytes == null) {
      showSnack(context, 'Please take or upload a delivery photo', error: true);
      return;
    }
    if (_delivered == false && _reasonCtrl.text.trim().isEmpty) {
      showSnack(context, 'Please enter a reason', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().updateDelivery(
        widget.orderId,
        _delivered!,
        reason: _delivered! ? null : _reasonCtrl.text.trim(),
        photoBytes: _photoBytes != null ? List<int>.from(_photoBytes!) : null,
        photoMime: 'image/jpeg',
      );
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, _delivered! ? 'Marked as Delivered ✓' : 'Status updated');
        widget.onDone();
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.local_shipping, color: Color(0xFFE3A008)),
              const SizedBox(width: 8),
              Text(widget.orderRef,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
            const SizedBox(height: 16),
            const Text('Delivery Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _ChoiceBtn(label: '✓  Delivered', selected: _delivered == true,
                  color: Colors.green, onTap: () => setState(() => _delivered = true))),
              const SizedBox(width: 10),
              Expanded(child: _ChoiceBtn(label: '✗  Not Delivered', selected: _delivered == false,
                  color: Colors.red, onTap: () => setState(() => _delivered = false))),
            ]),

            // ── Photo section (Delivered) ──────────────────────
            if (_delivered == true) ...[
              const SizedBox(height: 16),
              const Text('Proof of Delivery Photo *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              if (_photoBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(_photoBytes!,
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retake / Change'),
                  onPressed: () => _pickPhoto(ImageSource.camera),
                ),
              ] else
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE3A008),
                        side: const BorderSide(color: Color(0xFFE3A008)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _pickPhoto(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE3A008),
                        side: const BorderSide(color: Color(0xFFE3A008)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                    ),
                  ),
                ]),
            ],

            // ── Reason (Not Delivered) ─────────────────────────
            if (_delivered == false) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(
                    labelText: 'Reason for non-delivery',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _delivered != null && !_loading ? _submit : null,
                child: _loading
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ChoiceBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
      ),
    );
  }
}

Widget _emptyState(String title, String subtitle) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        if (subtitle.isNotEmpty)
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ],
    ),
  );
}
// ─────────────────────────────────────────────────────────────
//  ADMIN DASHBOARD
// ─────────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: const Color(0xFFDC2626),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFDC2626),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Users'),
              Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Stock Items'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _AdminUsersTab(),
              _AdminStockTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Users Tab ────────────────────────────────────────────────
class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();
  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().adminListUsers();
      setState(() { _users = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  void _showCreateUser() {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? dept;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create User',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined), border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: userCtrl,
                  decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email), border: OutlineInputBorder()),
                  autocorrect: false,
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Min 3 chars' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: dept,
                  decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business_outlined), border: OutlineInputBorder()),
                  items: ['Sales Team', 'Invoicing Team', 'Manager', 'Driver', 'Admin']
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setSt(() => dept = v),
                  validator: (v) => v == null ? 'Select department' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await ApiService().adminCreateUser({
                          'full_name': nameCtrl.text.trim(),
                          'username': userCtrl.text.trim(),
                          'password': passCtrl.text,
                          'department': dept,
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          showSnack(context, 'User created ✓');
                          _load();
                        }
                      } on ApiException catch (e) {
                        if (mounted) showSnack(context, e.message, error: true);
                      }
                    },
                    child: const Text('Create User'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showEditUser(Map<String, dynamic> user) {
    String? dept = user['department'];
    bool isActive = user['is_active'] ?? true;
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit — ${user['username']}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: dept,
                decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                items: ['Sales Team', 'Invoicing Team', 'Manager', 'Driver', 'Admin']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setSt(() => dept = v),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passCtrl,
                decoration: const InputDecoration(
                    labelText: 'New Password (leave blank to keep)',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Account Active', style: TextStyle(fontWeight: FontWeight.w600)),
                value: isActive,
                activeColor: const Color(0xFFDC2626),
                onChanged: (v) => setSt(() => isActive = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete User?'),
                          content: Text('Permanently delete "${user['username']}"?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await ApiService().adminDeleteUser(user['id']);
                          if (mounted) { showSnack(context, 'User deleted'); _load(); }
                        } on ApiException catch (e) {
                          if (mounted) showSnack(context, e.message, error: true);
                        }
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                    onPressed: () async {
                      final patch = <String, dynamic>{
                        'department': dept,
                        'is_active': isActive,
                        if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                      };
                      try {
                        await ApiService().adminUpdateUser(user['id'], patch);
                        if (mounted) {
                          Navigator.pop(ctx);
                          showSnack(context, 'User updated ✓');
                          _load();
                        }
                      } on ApiException catch (e) {
                        if (mounted) showSnack(context, e.message, error: true);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: _showCreateUser,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i] as Map<String, dynamic>;
                  final active = u['is_active'] ?? true;
                  final dept = u['department'] as String;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: deptColor(dept).withOpacity(0.15),
                        child: Icon(deptIcon(dept), color: deptColor(dept), size: 20),
                      ),
                      title: Row(children: [
                        Text(u['full_name'] ?? u['username'],
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: active ? const Color(0xFF0F1B2D) : Colors.grey,
                            )),
                        const SizedBox(width: 6),
                        if (!active)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Disabled', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
                          ),
                      ]),
                      subtitle: Text('@${u['username']}  •  $dept',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showEditUser(u),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ── Stock Items Tab ──────────────────────────────────────────
class _AdminStockTab extends StatefulWidget {
  const _AdminStockTab();
  @override
  State<_AdminStockTab> createState() => _AdminStockTabState();
}

class _AdminStockTabState extends State<_AdminStockTab> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().adminListStockItems();
      setState(() { _items = data; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _importCustomerExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return;

    final bytes = result.files.first.bytes!;
    final excel = xl.Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    final rows = sheet.rows;

    if (rows.length < 2) {
      if (mounted) showSnack(context, 'File is empty or has no data rows', error: true);
      return;
    }

    // Column A = Customer Name only. Header row (row 0) is skipped.
    final customerNames = <String>{};
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final customer = row.isNotEmpty
          ? (row[0]?.value?.toString() ?? '').trim()
          : '';
      if (customer.isNotEmpty) customerNames.add(customer);
    }

    if (customerNames.isEmpty) {
      if (mounted) showSnack(context, 'No customer names found in Column A', error: true);
      return;
    }

    int customerSuccess = 0;
    try {
      final res = await ApiService().adminImportCustomers(customerNames.toList());
      customerSuccess = res['imported'] ?? customerNames.length;
    } catch (_) {
      customerSuccess = 0;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Import Complete'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF1A56DB)),
              const SizedBox(width: 6),
              Text('$customerSuccess customer name(s) saved',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Excel format:\n  Column A → Customer Name\n  Row 1 = header (skipped)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _importInventoryExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return;

    final bytes = result.files.first.bytes!;
    final excel = xl.Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    final rows = sheet.rows;

    if (rows.length < 2) {
      if (mounted) showSnack(context, 'File is empty or has no data rows', error: true);
      return;
    }

    // Column A = Product Name, Column B = Quantity, Column C = UOM (optional)
    // Header row (row 0) is skipped.
    final items = <Map<String, dynamic>>[];
    final skipped = <int>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final name = row.isNotEmpty
          ? (row[0]?.value?.toString() ?? '').trim()
          : '';
      final qtyRaw = row.length > 1
          ? (row[1]?.value?.toString() ?? '').trim()
          : '';
      final uom = row.length > 2
          ? (row[2]?.value?.toString() ?? '').trim()
          : null;

      if (name.isEmpty) continue;
      final qty = double.tryParse(qtyRaw);
      if (qty == null) { skipped.add(i + 1); continue; } // 1-based row for user display

      items.add({
        'product_name': name,
        'quantity': qty,
        if (uom != null && uom.isNotEmpty) 'uom': uom,
      });
    }

    if (items.isEmpty) {
      if (mounted) showSnack(context, 'No valid inventory rows found', error: true);
      return;
    }

    int upserted = 0;
    try {
      final res = await ApiService().adminImportInventory(items);
      upserted = res['upserted'] ?? items.length;
    } catch (e) {
      if (mounted) showSnack(context, 'Import failed: $e', error: true);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Inventory Imported'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warehouse_outlined, size: 16, color: Color(0xFF7E3AF2)),
              const SizedBox(width: 6),
              Text('$upserted item(s) added/updated',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            if (skipped.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('  Rows skipped (invalid qty): ${skipped.join(", ")}',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Excel format:\n  Column A → Product Name\n  Column B → Quantity\n  Column C → UOM (optional)\n  Row 1 = header (skipped)',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateItem() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? uom;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Stock Item',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name', prefixIcon: Icon(Icons.inventory_2_outlined), border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: uom,
                  decoration: const InputDecoration(labelText: 'Unit of Measure', border: OutlineInputBorder()),
                  items: ['Pcs', 'Kg', 'Ltr', 'Box', 'Mtr', 'Nos']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setSt(() => uom = v),
                  validator: (v) => v == null ? 'Select UOM' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await ApiService().adminCreateStockItem({
                          'item_name': nameCtrl.text.trim(),
                          'uom': uom,
                          if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          showSnack(context, 'Stock item added ✓');
                          _load();
                        }
                      } on ApiException catch (e) {
                        if (mounted) showSnack(context, e.message, error: true);
                      }
                    },
                    child: const Text('Add Item'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showEditItem(Map<String, dynamic> item) {
    String? uom = item['uom'];
    bool isActive = item['is_active'] ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit — ${item['item_name']}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: uom,
                decoration: const InputDecoration(labelText: 'Unit of Measure', border: OutlineInputBorder()),
                items: ['Pcs', 'Kg', 'Ltr', 'Box', 'Mtr', 'Nos']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setSt(() => uom = v),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active', style: TextStyle(fontWeight: FontWeight.w600)),
                value: isActive,
                activeColor: const Color(0xFFDC2626),
                onChanged: (v) => setSt(() => isActive = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  onPressed: () async {
                    try {
                      await ApiService().adminUpdateStockItem(item['id'], {
                        'uom': uom,
                        'is_active': isActive,
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        showSnack(context, 'Updated ✓');
                        _load();
                      }
                    } on ApiException catch (e) {
                      if (mounted) showSnack(context, e.message, error: true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_customers',
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.people_alt_outlined),
            label: const Text('Import Customers', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _importCustomerExcel,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'import_inventory',
            backgroundColor: const Color(0xFF7E3AF2),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.warehouse_outlined),
            label: const Text('Import Inventory', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _importInventoryExcel,
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'add_item',
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _showCreateItem,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i] as Map<String, dynamic>;
                  final active = item['is_active'] ?? true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFDC2626).withOpacity(0.1),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFDC2626), size: 20),
                      ),
                      title: Row(children: [
                        Text(item['item_name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14,
                              color: active ? const Color(0xFF0F1B2D) : Colors.grey,
                            )),
                        const SizedBox(width: 6),
                        if (!active)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                            child: const Text('Inactive', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
                          ),
                      ]),
                      subtitle: Text(item['uom'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showEditItem(item),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  INVENTORY VIEWER — Sales Team (and all authenticated users)
// ─────────────────────────────────────────────────────────────
class InventoryViewerPage extends StatefulWidget {
  const InventoryViewerPage({super.key});

  @override
  State<InventoryViewerPage> createState() => _InventoryViewerPageState();
}

class _InventoryViewerPageState extends State<InventoryViewerPage> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
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
      final data = await ApiService().getInventory();
      final items = data.cast<Map<String, dynamic>>();
      setState(() {
        _all = items;
        _filtered = _applySearch(items, _search);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, 'Failed to load inventory', error: true);
    }
  }

  List<Map<String, dynamic>> _applySearch(List<Map<String, dynamic>> src, String q) {
    if (q.isEmpty) return src;
    final lower = q.toLowerCase();
    return src
        .where((item) =>
            (item['product_name'] as String).toLowerCase().contains(lower))
        .toList();
  }

  void _onSearch(String q) {
    setState(() {
      _search = q;
      _filtered = _applySearch(_all, q);
    });
  }

  String _fmtUpdated(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return 'Updated ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Color _qtyColor(double qty) {
    if (qty <= 0) return Colors.red;
    if (qty < 10) return Colors.orange;
    return const Color(0xFF057A55);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7E3AF2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Inventory',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Sync',
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
              color: const Color(0xFF7E3AF2).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warehouse_outlined,
                size: 56, color: Color(0xFF7E3AF2)),
          ),
          const SizedBox(height: 20),
          const Text('No inventory yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Ask your administrator to import\ninventory via Excel.',
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
          color: const Color(0xFF7E3AF2),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search products…',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      },
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

        // Summary row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_filtered.length} product${_filtered.length == 1 ? '' : 's'}',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'Synced from admin import',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),

        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text('No results for "$_search"',
                      style: TextStyle(color: Colors.grey.shade400)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final name = item['product_name'] as String;
                      final qty = (item['quantity'] as num).toDouble();
                      final uom = item['uom'] as String? ?? '';
                      final qtyColor = _qtyColor(qty);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10)
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF7E3AF2).withOpacity(0.1),
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Color(0xFF7E3AF2),
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            _fmtUpdated(item['updated_at']),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                qty % 1 == 0
                                    ? qty.toInt().toString()
                                    : qty.toStringAsFixed(2),
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: qtyColor),
                              ),
                              if (uom.isNotEmpty)
                                Text(uom,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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