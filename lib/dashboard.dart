import 'dart:async';
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
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    ApiService().setToken(widget.token);
  }

  // ── Bottom nav items per department ───────────────────────
  List<_NavItem> get _navItems {
    switch (widget.department) {
      case 'Sales Team':
        return [
          _NavItem(icon: Icons.receipt_long_outlined,  activeIcon: Icons.receipt_long,  label: 'Orders'),
          _NavItem(icon: Icons.people_alt_outlined,    activeIcon: Icons.people_alt,    label: 'Customers'),
          _NavItem(icon: Icons.warehouse_outlined,     activeIcon: Icons.warehouse,     label: 'Inventory'),
          _NavItem(icon: Icons.logout,                 activeIcon: Icons.logout,        label: 'Logout'),
        ];
      case 'Driver':
        return [
          _NavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Deliveries'),
          _NavItem(icon: Icons.logout,                  activeIcon: Icons.logout,         label: 'Logout'),
        ];
      case 'Invoicing Team':
        return [
          _NavItem(icon: Icons.receipt_outlined,  activeIcon: Icons.receipt,  label: 'Orders'),
          _NavItem(icon: Icons.logout,            activeIcon: Icons.logout,   label: 'Logout'),
        ];
      case 'Manager':
        return [
          _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analytics'),
          _NavItem(icon: Icons.logout,             activeIcon: Icons.logout,    label: 'Logout'),
        ];
      case 'Admin':
        return [
          _NavItem(icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings, label: 'Admin'),
          _NavItem(icon: Icons.logout,                        activeIcon: Icons.logout,               label: 'Logout'),
        ];
      default:
        return [
          _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
          _NavItem(icon: Icons.logout,        activeIcon: Icons.logout, label: 'Logout'),
        ];
    }
  }

  void _onNavTap(int index) {
    final items = _navItems;
    // Last item is always Logout
    if (index == items.length - 1) {
      logout(context);
      return;
    }
    // Sales Team: Customers & Inventory open separate pages
    if (widget.department == 'Sales Team') {
      if (index == 1) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerExcelViewerPage()));
        return;
      }
      if (index == 2) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryViewerPage()));
        return;
      }
    }
    setState(() => _navIndex = index);
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
    final items = _navItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      floatingActionButton: _buildFab(),
      // ── Custom AppBar: gradient that echoes the splash ────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F1B2D),
                color.withOpacity(0.92),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  // Logo pill
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.40),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/invent.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  // Title + Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'EPM ORDER DESK',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.60),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          widget.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Department badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.20),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(deptIcon(widget.department),
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          widget.department,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ── Bottom Navigation Bar ─────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isLogout = i == items.length - 1;
                final isActive = !isLogout && i == _navIndex;
                final itemColor = isLogout
                    ? Colors.red.shade400
                    : isActive
                        ? color
                        : Colors.grey.shade400;

                return Expanded(
                  child: InkWell(
                    onTap: () => _onNavTap(i),
                    splashColor: color.withOpacity(0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? color.withOpacity(0.06)
                            : Colors.transparent,
                        border: Border(
                          top: BorderSide(
                            color: isActive ? color : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 22,
                            color: itemColor,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: itemColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }
}

/// Simple data class for bottom nav items
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
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
          borderRadius: BorderRadius.circular(16),
          border: Border(top: BorderSide(color: color, width: 3)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
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
  final status = (order['status'] ?? '').toString();
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: actions,
              ),
            ),
        ],
      ),
    ),
  );
}

void _showOrderDetail(BuildContext context, Map<String, dynamic> order) {
  final status = (order['status'] ?? '').toString();
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

          // ── Proof of Delivery Photo ───────────────────────
          if (order['delivery_photo_url'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.photo_camera_outlined, size: 15, color: Color(0xFF057A55)),
                const SizedBox(width: 6),
                const Text('Proof of Delivery',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: Color(0xFF057A55))),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _PodPhotoViewer(
                      url: order['delivery_photo_url'] as String,
                      orderRef: order['order_reference'] ?? '',
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      order['delivery_photo_url'] as String,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Could not load photo',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                      ),
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey.shade100,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                    ),
                    // Tap-to-expand hint
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('View full',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          const Divider(height: 24),
          Text('${items.length} Line Item(s)',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          ...items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
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
//  Full-screen POD Photo Viewer
// ─────────────────────────────────────────────────────────────
class _PodPhotoViewer extends StatelessWidget {
  final String url;
  final String orderRef;

  const _PodPhotoViewer({required this.url, required this.orderRef});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proof of Delivery',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if (orderRef.isNotEmpty)
              Text(orderRef,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF057A55).withOpacity(0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF057A55).withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined,
                    size: 14, color: Color(0xFF34D399)),
                SizedBox(width: 4),
                Text('Delivered',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF34D399),
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined,
                    size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 16),
                Text('Could not load photo',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
            loadingBuilder: (_, child, prog) => prog == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
          ),
        ),
      ),
    );
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

class _InvoicingDashboardState extends State<InvoicingDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _filter = 'today';
  Timer? _refreshTimer;
  DateTime? _lastUpdated;

  // History tab state
  List<dynamic> _history = [];
  bool _historyLoading = false;
  String _historyFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && _history.isEmpty && !_historyLoading) {
        _loadHistory();
      }
    });
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final data = await ApiService().getInvoicingDashboard();
      if (mounted) setState(() { _data = data; _lastUpdated = DateTime.now(); });
    } catch (_) {}
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().getInvoicingDashboard();
      if (mounted) setState(() { _data = data; _loading = false; _lastUpdated = DateTime.now(); });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showSnack(context, e.toString(), error: true); }
    }
  }

  Future<void> _loadHistory({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _historyLoading = true);
    try {
      final status = _historyFilter == 'All' ? null : _historyFilter;
      final data = await ApiService().getAllOrders(status: status);
      if (mounted) setState(() { _history = data; _historyLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _historyLoading = false); showSnack(context, e.toString(), error: true); }
    }
  }

  bool _isToday(dynamic createdAt) {
    if (createdAt == null) return false;
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (_) { return false; }
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
                if (_tabs.index == 1) _loadHistory(silent: true);
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
                if (_tabs.index == 1) _loadHistory(silent: true);
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
    return Column(
      children: [
        // ── Tab bar ─────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: const Color(0xFF7E3AF2),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF7E3AF2),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.inbox_outlined, size: 18), text: 'Queue'),
              Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'History'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildQueue(),
              _buildHistory(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Queue tab (existing pending + invoiced today) ─────────
  Widget _buildQueue() {
    final allPending  = (_data?['pending_orders']        as List?) ?? [];
    final allInvoiced = (_data?['invoiced_orders_today'] as List?) ?? [];
    final pending  = _filter == 'today'
        ? allPending.where((o) => _isToday((o as Map)['created_at'])).toList()
        : allPending;
    final invoiced = _filter == 'today'
        ? allInvoiced.where((o) => _isToday((o as Map)['created_at'])).toList()
        : allInvoiced;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Auto-refresh indicator ───────────────────────────
          Row(
            children: [
              const Icon(Icons.sync, size: 13, color: Color(0xFF7E3AF2)),
              const SizedBox(width: 4),
              Text(
                _lastUpdated == null
                    ? 'Auto-refreshes every 30s'
                    : 'Updated ${_lastUpdated!.hour.toString().padLeft(2, '0')}:${_lastUpdated!.minute.toString().padLeft(2, '0')}:${_lastUpdated!.second.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _load,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7E3AF2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 13, color: Color(0xFF7E3AF2)),
                      SizedBox(width: 4),
                      Text('Refresh', style: TextStyle(
                          fontSize: 11, color: Color(0xFF7E3AF2),
                          fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Stats ────────────────────────────────────────────
          Row(children: [
            _StatCard(label: 'Pending',        value: '${pending.length}',  color: Colors.orange,           icon: Icons.hourglass_empty),
            const SizedBox(width: 10),
            _StatCard(label: 'Invoiced Today', value: '${invoiced.length}', color: const Color(0xFF7E3AF2), icon: Icons.receipt_long),
          ]),
          const SizedBox(height: 12),

          // ── Date filter toggle ────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Row(
              children: ['today', 'all'].map((f) {
                final sel = _filter == f;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF7E3AF2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        f == 'today' ? 'Today' : 'All Orders',
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.w700, fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Pending ───────────────────────────────────────────
          _sectionTitle('Pending (${pending.length})'),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (pending.isEmpty)
            _emptyState('No pending orders', _filter == 'today' ? 'No orders placed today' : 'All caught up!')
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

          // ── Invoiced ──────────────────────────────────────────
          _sectionTitle('Invoiced (${invoiced.length})'),
          if (!_loading && invoiced.isEmpty)
            _emptyState('No invoices', _filter == 'today' ? 'None invoiced today yet' : 'No invoiced orders')
          else
            ...invoiced.map((o) => _orderCard(context, o as Map<String, dynamic>)),
        ],
      ),
    );
  }

  // ── History tab ───────────────────────────────────────────
  Widget _buildHistory() {
    return Column(
      children: [
        // Status filter chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Pending', 'Invoiced', 'Delivered', 'Cancelled'].map((f) {
                final sel = _historyFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: sel,
                    selectedColor: const Color(0xFF7E3AF2),
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w600, fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _historyFilter = f);
                      _loadHistory();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadHistory(),
            child: _historyLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? ListView(
                        children: [_emptyState(
                          'No orders found',
                          _historyFilter == 'All'
                              ? 'No orders in the system yet'
                              : 'No $_historyFilter orders',
                        )],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _history.length,
                        itemBuilder: (_, i) =>
                            _orderCard(context, _history[i] as Map<String, dynamic>),
                      ),
          ),
        ),
      ],
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

class _ManagerDashboardState extends State<ManagerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic>? _data;
  List<dynamic> _allOrders = [];   // raw orders for today view
  bool _loading = true;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().getManagerDashboard(days: _days);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showSnack(context, e.toString(), error: true); }
    }
  }

  bool _isToday(dynamic raw) {
    if (raw == null) return false;
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: const Color(0xFF057A55),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF057A55),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.today_outlined, size: 18), text: 'Today'),
              Tab(icon: Icon(Icons.bar_chart_outlined, size: 18), text: 'Analytics'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _TodayTab(data: _data, loading: _loading, isToday: _isToday, onRefresh: _load),
              _AnalyticsTab(data: _data, loading: _loading, days: _days,
                onDaysChanged: (d) { setState(() => _days = d); _load(); },
                onRefresh: _load,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Today Tab ────────────────────────────────────────────────
class _TodayTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final bool Function(dynamic) isToday;
  final Future<void> Function() onRefresh;

  const _TodayTab({required this.data, required this.loading, required this.isToday, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final daily     = (data?['daily_orders'] as List?) ?? [];
    final bySalesman = (data?['orders_by_salesman'] as List?) ?? [];
    final byCustomer = (data?['orders_by_customer'] as List?) ?? [];

    // Today stats from daily_orders (the backend already has daily breakdowns)
    final todayStr = () {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    }();

    int todayTotal = 0;
    final Map<String, int> todayBySalesman = {};
    for (final d in daily) {
      if ((d['date'] as String?) == todayStr) {
        todayTotal += (d['count'] as int? ?? 0);
        final sm = d['salesman'] as String? ?? 'unknown';
        todayBySalesman[sm] = (todayBySalesman[sm] ?? 0) + (d['count'] as int? ?? 0);
      }
    }

    final now = DateTime.now();
    final dateLabel = '${now.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][now.month-1]} ${now.year}';

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Date header ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF057A55), Color(0xFF0B9B6D)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(dateLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$todayTotal order${todayTotal == 1 ? "" : "s"}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),

          if (loading) ...[
            const SizedBox(height: 40),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            const SizedBox(height: 16),

            // ── Today by salesman ─────────────────────────────
            if (todayBySalesman.isEmpty)
              _emptyState('No orders today', 'Orders placed today will appear here')
            else ...[
              _sectionTitle('Orders by Salesman — Today'),
              ...todayBySalesman.entries.map((e) => _statListTile(
                Icons.person_outline, e.key, '${e.value} order${e.value == 1 ? "" : "s"}', const Color(0xFF1A56DB))),

              // ── Mini bar chart for today per salesman ─────────
              const SizedBox(height: 8),
              _TodayBarChart(salesmanCounts: todayBySalesman),
            ],

            const SizedBox(height: 8),

            // ── Quick summary cards ───────────────────────────
            _sectionTitle('Overall Summary (${data?["days"] ?? "..."} days)'),
            const SizedBox(height: 4),
            _QuickSummary(summary: (data?['summary'] as Map?) ?? {}),
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
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Text(trailing, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}

// Mini horizontal bar chart for today's salesman breakdown
class _TodayBarChart extends StatelessWidget {
  final Map<String, int> salesmanCounts;
  const _TodayBarChart({required this.salesmanCounts});

  @override
  Widget build(BuildContext context) {
    if (salesmanCounts.isEmpty) return const SizedBox();
    final maxVal = salesmanCounts.values.fold(0, (a, b) => a > b ? a : b);
    final colors = [
      const Color(0xFF1A56DB), const Color(0xFF057A55), const Color(0xFF7E3AF2),
      const Color(0xFFE3A008), const Color(0xFFDC2626), const Color(0xFF0891B2),
    ];
    final entries = salesmanCounts.entries.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final pct = maxVal > 0 ? e.value / maxVal : 0.0;
          final color = colors[i % colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                width: 80,
                child: Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(children: [
                  Container(height: 20, decoration: BoxDecoration(
                    color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10))),
                  FractionallySizedBox(
                    widthFactor: pct.toDouble(),
                    child: Container(height: 20, decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(10))),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              Text('${e.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ]),
          );
        }),
      ),
    );
  }
}

// Quick 4-stat summary grid
class _QuickSummary extends StatelessWidget {
  final Map summary;
  const _QuickSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: [
        _miniCard('Pending',   '${summary['total_pending']   ?? 0}', Colors.orange,           Icons.hourglass_empty),
        _miniCard('Invoiced',  '${summary['total_invoiced']  ?? 0}', const Color(0xFF1A56DB), Icons.receipt),
        _miniCard('Delivered', '${summary['total_delivered'] ?? 0}', Colors.green,            Icons.check_circle_outline),
        _miniCard('Cancelled', '${summary['total_cancelled'] ?? 0}', Colors.red,              Icons.cancel_outlined),
      ],
    );
  }

  Widget _miniCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border(top: BorderSide(color: color, width: 3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10)],
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
      ]),
    );
  }
}

// ── Analytics Tab ────────────────────────────────────────────
class _AnalyticsTab extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final int days;
  final void Function(int) onDaysChanged;
  final Future<void> Function() onRefresh;

  const _AnalyticsTab({
    required this.data, required this.loading, required this.days,
    required this.onDaysChanged, required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final summary    = data?['summary']            as Map? ?? {};
    final bySalesman = (data?['orders_by_salesman'] as List?) ?? [];
    final byCustomer = (data?['orders_by_customer'] as List?) ?? [];
    final byProduct  = (data?['orders_by_product']  as List?) ?? [];
    final daily      = (data?['daily_orders']       as List?) ?? [];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Period chips ──────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [7, 14, 30, 90].map((d) {
              final selected = days == d;
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
                  onSelected: (_) => onDaysChanged(d),
                ),
              );
            }).toList()),
          ),
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
          if (loading) ...[
            const SizedBox(height: 40),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            if (daily.isNotEmpty) ...[
              _sectionTitle('Daily Orders'),
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
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Text(trailing, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
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

class _DriverDashboardState extends State<DriverDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Invoiced pool tab (all unassigned invoiced orders)
  List<dynamic> _invoicedOrders = [];
  // To Deliver tab (assigned to me, status=Loading)
  List<dynamic> _myOrders = [];
  bool _loading = true;

  // History tab
  List<dynamic> _history = [];
  bool _historyLoading = false;
  String _historyFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 2 && _history.isEmpty && !_historyLoading) {
        _loadHistory();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getDriverDashboard();
      setState(() {
        _invoicedOrders = (data['invoiced_orders'] as List?) ?? [];
        _myOrders       = (data['my_loading_orders'] as List?) ?? [];
        _loading        = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _loadHistory({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _historyLoading = true);
    try {
      final status = _historyFilter == 'All' ? null : _historyFilter;
      final data = await ApiService().getAllOrders(status: status);
      if (mounted) setState(() { _history = data; _historyLoading = false; });
    } catch (e) {
      if (mounted) { setState(() => _historyLoading = false); showSnack(context, e.toString(), error: true); }
    }
  }

  void _showLoadingDialog(String orderId, String ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => _LoadingSheet(
        orderId: orderId,
        orderRef: ref,
        onDone: () {
          _load();
          if (_tabs.index == 2) _loadHistory(silent: true);
        },
      ),
    );
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
        onDone: () {
          _load();
          if (_tabs.index == 2) _loadHistory(silent: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: const Color(0xFFE3A008),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE3A008),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            tabs: [
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 18),
                    if (_invoicedOrders.isNotEmpty)
                      Positioned(
                        top: -4, right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A56DB), shape: BoxShape.circle),
                          child: Text('${_invoicedOrders.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
                text: 'Invoiced',
              ),
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 18),
                    if (_myOrders.isNotEmpty)
                      Positioned(
                        top: -4, right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3A008), shape: BoxShape.circle),
                          child: Text('${_myOrders.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 9,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                  ],
                ),
                text: 'To Deliver',
              ),
              const Tab(icon: Icon(Icons.history_outlined, size: 18), text: 'History'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildInvoicedPool(),
              _buildMyQueue(),
              _buildHistory(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 1: Invoiced pool — all unassigned invoiced orders ─────────────────
  Widget _buildInvoicedPool() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _StatCard(label: 'Available', value: '${_invoicedOrders.length}',
                color: const Color(0xFF1A56DB), icon: Icons.receipt_long_outlined),
          ]),
          _sectionTitle('Invoiced Orders — Tap Loading to claim (${_invoicedOrders.length})'),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_invoicedOrders.isEmpty)
            _emptyState('No invoiced orders', 'Orders ready for pickup appear here')
          else
            ..._invoicedOrders.map((o) {
              try {
                final order = o as Map<String, dynamic>;
                return _orderCard(
                  context,
                  order,
                  actions: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Loading',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3A008),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => _showLoadingDialog(
                          order['id']?.toString() ?? '',
                          order['order_reference']?.toString() ?? ''),
                    ),
                  ],
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            }),
        ],
      ),
    );
  }

  // ── Tab 2: My queue — orders I claimed (status=Loading) ───────────────────
  Widget _buildMyQueue() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _StatCard(label: 'To Deliver', value: '${_myOrders.length}',
                color: const Color(0xFFE3A008), icon: Icons.local_shipping_outlined),
          ]),
          _sectionTitle('Assigned to Me — Ready to Deliver (${_myOrders.length})'),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_myOrders.isEmpty)
            _emptyState('Nothing assigned yet',
                'Claim an order from the Invoiced tab to see it here')
          else
            ..._myOrders.map((o) {
              try {
                final order = o as Map<String, dynamic>;
                return _orderCard(
                  context,
                  order,
                  actions: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.local_shipping, size: 18),
                      label: const Text('Deliver',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF057A55),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => _showDeliveryDialog(
                          order['id']?.toString() ?? '',
                          order['order_reference']?.toString() ?? ''),
                    ),
                  ],
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            }),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Invoiced', 'Loading', 'Delivered', 'Cancelled', 'Pending'].map((f) {
                final sel = _historyFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: sel,
                    selectedColor: const Color(0xFFE3A008),
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w600, fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _historyFilter = f);
                      _loadHistory();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadHistory(),
            child: _historyLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? ListView(
                        children: [_emptyState(
                          'No orders found',
                          _historyFilter == 'All'
                              ? 'No orders in the system yet'
                              : 'No $_historyFilter orders',
                        )],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _history.length,
                        itemBuilder: (_, i) =>
                            _orderCard(context, _history[i] as Map<String, dynamic>),
                      ),
          ),
        ),
      ],
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

// ─────────────────────────────────────────────────────────────
//  LOADING SHEET — Driver claims order + enters DN & Invoice #
// ─────────────────────────────────────────────────────────────
class _LoadingSheet extends StatefulWidget {
  final String orderId;
  final String orderRef;
  final VoidCallback onDone;

  const _LoadingSheet({required this.orderId, required this.orderRef, required this.onDone});

  @override
  State<_LoadingSheet> createState() => _LoadingSheetState();
}

class _LoadingSheetState extends State<_LoadingSheet> {
  final _dnCtrl = TextEditingController();
  final _invCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    final dn = _dnCtrl.text.trim();
    final inv = _invCtrl.text.trim(); // optional
    if (dn.isEmpty) {
      showSnack(context, 'Please enter the Delivery Note Number', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().markLoading(widget.orderId, dn, inv.isEmpty ? null : inv);
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Order assigned to you — Loading confirmed ✓');
        widget.onDone();
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } on NetworkException catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
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
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3A008).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFFE3A008), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Loading',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(widget.orderRef,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3A008).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE3A008).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFFE3A008)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This order will be assigned to you once submitted.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _dnCtrl,
              decoration: const InputDecoration(
                labelText: 'Delivery Note Number *',
                prefixIcon: Icon(Icons.description_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _invCtrl,
              decoration: const InputDecoration(
                labelText: 'Invoice Number (optional)',
                hintText: 'Leave blank if not yet available',
                prefixIcon: Icon(Icons.receipt_long_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(_loading ? 'Saving…' : 'Confirm Loading',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE3A008),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _submit,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dnCtrl.dispose();
    _invCtrl.dispose();
    super.dispose();
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
    _tabs = TabController(length: 3, vsync: this);
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Users'),
              Tab(icon: Icon(Icons.contacts_outlined, size: 18), text: 'Customers'),
              Tab(icon: Icon(Icons.warehouse_outlined, size: 18), text: 'Inventory'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _AdminUsersTab(),
              _AdminCustomersTab(),
              _AdminInventoryTab(),
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
      backgroundColor: const Color(0xFFF0F4FF),
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


// ── Customers Tab ────────────────────────────────────────────
class _AdminCustomersTab extends StatefulWidget {
  const _AdminCustomersTab();
  @override
  State<_AdminCustomersTab> createState() => _AdminCustomersTabState();
}

class _AdminCustomersTabState extends State<_AdminCustomersTab> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;
  final Set<String> _selected = {};
  bool _selecting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _selected.clear(); _selecting = false; });
    try {
      final data = await ApiService().adminListCustomers();
      if (mounted) setState(() { _customers = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showSnack(context, e.toString(), error: true); }
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
    });
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == _customers.length) {
        _selected.clear();
      } else {
        _selected.addAll(_customers.map((c) => c['id'] as String));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customers?'),
        content: Text('Permanently remove $count customer${count == 1 ? "" : "s"}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    int deleted = 0;
    for (final id in List<String>.from(_selected)) {
      try {
        await ApiService().adminDeleteCustomer(id);
        deleted++;
      } catch (_) {}
    }
    if (mounted) { showSnack(context, '$deleted customer${deleted == 1 ? "" : "s"} deleted'); _load(); }
  }

  Future<void> _importFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.first.bytes == null) return;

    final bytes = result.files.first.bytes!;
    final excel = xl.Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;

    // Read ALL cells from ALL rows — no header skip, no column filter
    // Any non-empty cell value in any column is treated as a customer name
    final names = <String>{};
    for (final row in sheet.rows) {
      for (final cell in row) {
        final val = cell?.value?.toString().trim() ?? '';
        if (val.isNotEmpty) names.add(val);
      }
    }

    if (names.isEmpty) {
      if (mounted) showSnack(context, 'No names found in the file', error: true);
      return;
    }

    try {
      final res = await ApiService().adminBulkImportCustomers(names.toList());
      final imported = res['imported'] ?? 0;
      final skipped = res['skipped_duplicates'] ?? 0;
      if (mounted) {
        showSnack(context, '$imported customer(s) imported${skipped > 0 ? ", $skipped duplicates skipped" : ""}');
        _load();
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Import failed: $e', error: true);
    }
  }

  void _showAddCustomer() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Customer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A56DB)),
                onPressed: () async {
                  final name = ctrl.text.trim();
                  if (name.isEmpty) return;
                  try {
                    await ApiService().adminAddCustomer(name);
                    if (mounted) { Navigator.pop(ctx); showSnack(context, 'Customer added ✓'); _load(); }
                  } on ApiException catch (e) {
                    if (mounted) showSnack(context, e.message, error: true);
                  }
                },
                child: const Text('Add'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _customers.isNotEmpty && _selected.length == _customers.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      floatingActionButton: _selecting
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'import_customers',
                  backgroundColor: const Color(0xFF1A56DB),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Import Excel', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _importFromExcel,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'add_customer',
                  backgroundColor: const Color(0xFF057A55),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _showAddCustomer,
                ),
              ],
            ),
      body: Column(
        children: [
          // ── Selection toolbar ─────────────────────────────
          if (_selecting)
            Container(
              color: const Color(0xFF1A3A6B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    tristate: true,
                    activeColor: Colors.white,
                    checkColor: const Color(0xFF1A3A6B),
                    onChanged: (_) => _selectAll(),
                  ),
                  Text('${_selected.length} selected',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text('Delete (${_selected.length})',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                    onPressed: _selected.isEmpty ? null : _deleteSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => setState(() { _selecting = false; _selected.clear(); }),
                  ),
                ],
              ),
            ),
          // ── List ─────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? _emptyState('No customers', 'Import from Excel or add manually')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _customers.length,
                          itemBuilder: (_, i) {
                            final c = _customers[i];
                            final name = c['name'] as String;
                            final id = c['id'] as String;
                            final isSel = _selected.contains(id);
                            return GestureDetector(
                              onLongPress: () => setState(() { _selecting = true; _selected.add(id); }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF1A56DB).withOpacity(0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSel ? Border.all(color: const Color(0xFF1A56DB), width: 1.5) : null,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  leading: _selecting
                                      ? Checkbox(
                                          value: isSel,
                                          activeColor: const Color(0xFF1A56DB),
                                          onChanged: (_) => _toggleSelect(id),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: const Color(0xFF1A56DB).withOpacity(0.1),
                                          child: Text(name[0].toUpperCase(),
                                              style: const TextStyle(color: Color(0xFF1A56DB), fontWeight: FontWeight.w800)),
                                        ),
                                  title: Text(name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  onTap: _selecting ? () => _toggleSelect(id) : null,
                                  trailing: _selecting
                                      ? null
                                      : IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: const Text('Delete Customer?'),
                                                content: Text('Remove "$name"?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              try {
                                                await ApiService().adminDeleteCustomer(id);
                                                if (mounted) { showSnack(context, 'Deleted'); _load(); }
                                              } on ApiException catch (e) {
                                                if (mounted) showSnack(context, e.message, error: true);
                                              }
                                            }
                                          },
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Inventory Tab ────────────────────────────────────────────
class _AdminInventoryTab extends StatefulWidget {
  const _AdminInventoryTab();
  @override
  State<_AdminInventoryTab> createState() => _AdminInventoryTabState();
}

class _AdminInventoryTabState extends State<_AdminInventoryTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  final Set<String> _selected = {};
  bool _selecting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _selected.clear(); _selecting = false; });
    try {
      final data = await ApiService().adminListInventory();
      if (mounted) setState(() { _items = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); showSnack(context, e.toString(), error: true); }
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) _selected.remove(id); else _selected.add(id);
    });
  }

  void _selectAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected.addAll(_items.map((it) => it['id'] as String));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Items?'),
        content: Text('Permanently remove $count item${count == 1 ? "" : "s"} from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    int deleted = 0;
    for (final id in List<String>.from(_selected)) {
      try { await ApiService().adminDeleteInventoryItem(id); deleted++; } catch (_) {}
    }
    if (mounted) { showSnack(context, '$deleted item${deleted == 1 ? "" : "s"} deleted'); _load(); }
  }

  Future<void> _importFromExcel() async {
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

    // Read every row, every column pair:
    // Col 0 = product name, Col 1 = quantity, Col 2 = UOM (optional)
    // No header skip, no name/colon filtering — take everything with a valid qty
    final items = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row.isEmpty) continue;
      final name = (row[0]?.value?.toString() ?? '').trim();
      if (name.isEmpty) continue;
      final qtyStr = row.length > 1 ? (row[1]?.value?.toString() ?? '').trim() : '';
      final qty = double.tryParse(qtyStr);
      if (qty == null) continue; // skip rows without a numeric qty
      final uom = row.length > 2 ? (row[2]?.value?.toString() ?? '').trim() : '';
      items.add({
        'product_name': name,
        'quantity': qty,
        if (uom.isNotEmpty) 'uom': uom,
      });
    }

    if (items.isEmpty) {
      if (mounted) showSnack(context, 'No valid rows found (need name + number)', error: true);
      return;
    }

    try {
      final res = await ApiService().adminBulkImportInventory(items);
      final count = res['upserted'] ?? items.length;
      if (mounted) { showSnack(context, '$count item(s) imported/updated'); _load(); }
    } catch (e) {
      if (mounted) showSnack(context, 'Import failed: $e', error: true);
    }
  }

  void _showAddItem() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final uomCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20, right: 20, top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add / Update Inventory Item',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('If the product already exists its quantity will be updated.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                prefixIcon: Icon(Icons.inventory_2_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: uomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'UOM',
                    hintText: 'Pcs',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7E3AF2)),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final qty = double.tryParse(qtyCtrl.text.trim());
                  if (name.isEmpty || qty == null) {
                    showSnack(context, 'Enter a valid name and quantity', error: true);
                    return;
                  }
                  try {
                    final res = await ApiService().adminAddInventoryItem({
                      'product_name': name,
                      'quantity': qty,
                      if (uomCtrl.text.trim().isNotEmpty) 'uom': uomCtrl.text.trim(),
                    });
                    final updated = res['updated'] == true;
                    if (mounted) {
                      Navigator.pop(ctx);
                      showSnack(context, updated ? 'Item updated ✓' : 'Item added ✓');
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
      ),
    );
  }

  Color _qtyColor(double qty) {
    if (qty <= 0) return Colors.red;
    if (qty < 10) return Colors.orange;
    return const Color(0xFF057A55);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _items.isNotEmpty && _selected.length == _items.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      floatingActionButton: _selecting
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'import_inventory',
                  backgroundColor: const Color(0xFF7E3AF2),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Import Excel', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _importFromExcel,
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'add_inventory',
                  backgroundColor: const Color(0xFF057A55),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _showAddItem,
                ),
              ],
            ),
      body: Column(
        children: [
          // ── Selection toolbar ─────────────────────────────
          if (_selecting)
            Container(
              color: const Color(0xFF3B1FA0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    tristate: true,
                    activeColor: Colors.white,
                    checkColor: const Color(0xFF3B1FA0),
                    onChanged: (_) => _selectAll(),
                  ),
                  Text('${_selected.length} selected',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: Text('Delete (${_selected.length})',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                    onPressed: _selected.isEmpty ? null : _deleteSelected,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => setState(() { _selecting = false; _selected.clear(); }),
                  ),
                ],
              ),
            ),
          // ── List ─────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _emptyState('No inventory', 'Import from Excel or add manually')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            final name = item['product_name'] as String;
                            final id = item['id'] as String;
                            final qty = (item['quantity'] as num).toDouble();
                            final uom = item['uom'] as String? ?? '';
                            final isSel = _selected.contains(id);
                            return GestureDetector(
                              onLongPress: () => setState(() { _selecting = true; _selected.add(id); }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? const Color(0xFF7E3AF2).withOpacity(0.08) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSel ? Border.all(color: const Color(0xFF7E3AF2), width: 1.5) : null,
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  onTap: _selecting ? () => _toggleSelect(id) : null,
                                  leading: _selecting
                                      ? Checkbox(
                                          value: isSel,
                                          activeColor: const Color(0xFF7E3AF2),
                                          onChanged: (_) => _toggleSelect(id),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: const Color(0xFF7E3AF2).withOpacity(0.1),
                                          child: Text(name[0].toUpperCase(),
                                              style: const TextStyle(color: Color(0xFF7E3AF2), fontWeight: FontWeight.w800)),
                                        ),
                                  title: Text(name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: uom.isNotEmpty
                                      ? Text(uom, style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                                      : null,
                                  trailing: _selecting
                                      ? Text(
                                          qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2),
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _qtyColor(qty)),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2),
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _qtyColor(qty)),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (_) => AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                    title: const Text('Delete Item?'),
                                                    content: Text('Remove "$name" from inventory?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  try {
                                                    await ApiService().adminDeleteInventoryItem(id);
                                                    if (mounted) { showSnack(context, 'Deleted'); _load(); }
                                                  } on ApiException catch (e) {
                                                    if (mounted) showSnack(context, e.message, error: true);
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
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
      backgroundColor: const Color(0xFFF0F4FF),
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