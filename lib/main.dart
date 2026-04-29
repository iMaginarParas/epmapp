import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'dashboard.dart';

// ─────────────────────────────────────────────────────────────
//  CONFIG — change this to your Railway URL
// ─────────────────────────────────────────────────────────────
const String kBaseUrl = 'https://emp-backend-production-8c1d.up.railway.app';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EpmApp());
}

class EpmApp extends StatelessWidget {
  const EpmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPM ORDER DESK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const SplashGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Splash / Auth Gate
// ─────────────────────────────────────────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final dept = prefs.getString('department');
    final fullName = prefs.getString('full_name') ?? '';
    final username = prefs.getString('username') ?? '';

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    if (token != null && dept != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            department: dept,
            fullName: fullName,
            username: username,
            token: token,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1437),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset('assets/invent.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 22),
            const Text('EPM ORDER DESK',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(height: 6),
            Text('Internal Operations Platform',
              style: TextStyle(color: Color(0xFF8494B4), fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 48),
            const SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(color: Color(0xFFF5A623), strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  API Service
// ─────────────────────────────────────────────────────────────
class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> signup({
    required String username,
    required String fullName,
    required String password,
    required String department,
  }) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/signup'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'full_name': fullName,
        'password': password,
        'department': department,
      }),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> getManagerDashboard({int days = 30}) async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/manager/dashboard?days=$days'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> getInvoicingDashboard() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/invoicing/dashboard'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> getDriverDashboard() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/driver/dashboard'),
      headers: _headers,
    );
    return _handle(res);
  }

  Future<List<dynamic>> getMyOrders() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/orders/my'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded.containsKey('list')) return decoded['list'] as List;
      return [];
    }
    _handle(res); // will throw
    return [];
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async {
    final uri = Uri.parse('$kBaseUrl/orders').replace(queryParameters: {'confirmed': 'true'});
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<List<dynamic>> getAllOrders({String? status}) async {
    final uri = Uri.parse('$kBaseUrl/orders').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      return [];
    }
    _handle(res);
    return [];
  }

  Future<Map<String, dynamic>> markInvoiced(String orderId, String invoiceNumber) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/orders/$orderId/invoice'),
      headers: _headers,
      body: jsonEncode({'invoice_number': invoiceNumber}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/orders/$orderId/cancel'),
      headers: _headers,
      body: jsonEncode({'cancel_reason': reason}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateDelivery(
      String orderId, bool delivered, {String? reason}) async {
    final res = await http.patch(
      Uri.parse('$kBaseUrl/orders/$orderId/delivery'),
      headers: _headers,
      body: jsonEncode({'delivered': delivered, if (reason != null) 'reason': reason}),
    );
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) return {'list': body};
      return body as Map<String, dynamic>;
    }
    final detail = (body is Map) ? (body['detail'] ?? 'Request failed') : 'Request failed';
    throw ApiException(detail.toString(), res.statusCode);
  }

  void setToken(String token) => _token = token;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────
//  Shared UI helpers
// ─────────────────────────────────────────────────────────────
Color deptColor(String dept) {
  switch (dept) {
    case 'Sales Team':     return const Color(0xFF1A56DB);
    case 'Invoicing Team': return const Color(0xFF7E3AF2);
    case 'Manager':        return const Color(0xFF057A55);
    case 'Driver':         return const Color(0xFFE3A008);
    default:               return Colors.grey;
  }
}

IconData deptIcon(String dept) {
  switch (dept) {
    case 'Sales Team':     return Icons.shopping_cart_outlined;
    case 'Invoicing Team': return Icons.receipt_outlined;
    case 'Manager':        return Icons.bar_chart_outlined;
    case 'Driver':         return Icons.local_shipping_outlined;
    default:               return Icons.person_outline;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'Pending':   return Colors.orange;
    case 'Invoiced':  return const Color(0xFF1A56DB);
    case 'Delivered': return Colors.green;
    case 'Cancelled': return Colors.red;
    default:          return Colors.grey;
  }
}

void showSnack(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: error ? const Color(0xFFEF4444) : const Color(0xFF10B981), size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
    backgroundColor: const Color(0xFF1C2B5E),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: (error ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.3)),
    ),
    duration: const Duration(seconds: 3),
  ));
}

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}