import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'login.dart';
import 'dashboard.dart';

// ─────────────────────────────────────────────────────────────
//  CONFIG — change this to your Railway URL
// ─────────────────────────────────────────────────────────────
const String kBaseUrl = 'https://emp-backend-production-8c1d.up.railway.app';

// ─────────────────────────────────────────────────────────────
//  Local Notifications setup
// ─────────────────────────────────────────────────────────────
final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'epm_orders_channel',
  'EPM Order Alerts',
  description: 'Order status updates and delivery notifications',
  importance: Importance.high,
);

// ─────────────────────────────────────────────────────────────
//  Background message handler (top-level, outside any class)
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are auto-shown by FCM on Android.
  // Nothing extra needed here unless you want custom logging.
  debugPrint('[FCM Background] ${message.notification?.title}');
}

// ─────────────────────────────────────────────────────────────
//  Main
// ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp();

  // 2. Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Create Android notification channel
  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);

  // 4. Initialize local notifications
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );
  await _localNotifications.initialize(initSettings);

  // 5. Set foreground notification presentation options (iOS)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const EpmApp());
}

// ─────────────────────────────────────────────────────────────
//  Show a local notification when app is in foreground
// ─────────────────────────────────────────────────────────────
void showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  final android = message.notification?.android;
  if (notification == null) return;

  _localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const SplashGate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Splash / Auth Gate  —  Animated Welcome Screen
// ─────────────────────────────────────────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _tagOpacity;
  late final Animation<Offset> _tagSlide;
  late final Animation<double> _lineWidth;
  late final Animation<double> _shimmerPos;
  late final Animation<double> _exitScale;
  late final Animation<double> _exitOpacity;
  late final Animation<double> _bgAngle;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _bgAngle = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
    ]).animate(_logoCtrl);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.4, curve: Curves.easeIn)));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _ringScale = Tween<double>(begin: 1.0, end: 1.35).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));
    _ringOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0, 0.6)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _tagOpacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1.0)));
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
    _lineWidth = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textCtrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _shimmerPos = Tween<double>(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _exitCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    _shimmerCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted || _navigated) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final dept = prefs.getString('department');
    final fullName = prefs.getString('full_name') ?? '';
    final username = prefs.getString('username') ?? '';

    await _exitCtrl.forward();

    if (!mounted) return;
    if (token != null && dept != null) {
      ApiService().setToken(token);
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
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _textCtrl.dispose();
    _shimmerCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bgAngle, _exitOpacity, _exitScale]),
      builder: (context, child) {
        return Opacity(
          opacity: _exitOpacity.value,
          child: Transform.scale(
            scale: _exitScale.value,
            child: child,
          ),
        );
      },
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _bgAngle,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.cos(_bgAngle.value * 2 * math.pi),
                    math.sin(_bgAngle.value * 2 * math.pi),
                  ),
                  end: Alignment(
                    -math.cos(_bgAngle.value * 2 * math.pi),
                    -math.sin(_bgAngle.value * 2 * math.pi),
                  ),
                  colors: const [Color(0xFF0A1628), Color(0xFF1A3A6B), Color(0xFF0D2347)],
                ),
              ),
              child: child,
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_logoScale, _logoOpacity, _logoSlide, _ringScale, _ringOpacity, _shimmerPos]),
                  builder: (context, _) {
                    return SlideTransition(
                      position: _logoSlide,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _ringScale.value,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(_ringOpacity.value),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: _logoScale.value,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment(_shimmerPos.value - 1, 0),
                                      end: Alignment(_shimmerPos.value, 0),
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.srcATop,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: Image.asset('assets/invent.png', fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: Listenable.merge([_titleOpacity, _titleSlide, _tagOpacity, _tagSlide, _lineWidth]),
                  builder: (context, _) {
                    return Column(
                      children: [
                        SlideTransition(
                          position: _titleSlide,
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: const Text(
                              'EPM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 8,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: SizedBox(
                            width: 200,
                            child: Align(
                              child: FractionallySizedBox(
                                widthFactor: _lineWidth.value,
                                child: Container(height: 1, color: Colors.white.withOpacity(0.3)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SlideTransition(
                          position: _tagSlide,
                          child: FadeTransition(
                            opacity: _tagOpacity,
                            child: Text(
                              'O R D E R   D E S K',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SlideTransition(
                          position: _tagSlide,
                          child: FadeTransition(
                            opacity: _tagOpacity,
                            child: Text(
                              'Order. Track. Deliver.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  API Service
// ─────────────────────────────────────────────────────────────
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Auth ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _safePost(
      Uri.parse('$kBaseUrl/auth/login'),
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _handle(res);
  }

  /// Register FCM token with backend after login.
  Future<void> registerFcmToken(String token) async {
    try {
      final res = await _safePost(
        Uri.parse('$kBaseUrl/auth/register-fcm-token'),
        body: jsonEncode({'token': token}),
      );
      if (res.statusCode == 200) {
        debugPrint('[FCM] Token registered with backend');
      }
    } catch (e) {
      debugPrint('[FCM] Failed to register token: $e');
      // Non-fatal: don't interrupt user flow
    }
  }

  /// Remove FCM token on logout.
  Future<void> removeFcmToken(String token) async {
    try {
      final res = await _safeDelete(
        Uri.parse('$kBaseUrl/auth/fcm-token'),
        body: jsonEncode({'token': token}),
      );
      debugPrint('[FCM] Token removal status: ${res.statusCode}');
    } catch (e) {
      debugPrint('[FCM] Failed to remove token: $e');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/auth/me'));
    return _handle(res);
  }

  // ── Orders ────────────────────────────────────────────────
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> body) async {
    final res = await _safePost(
      Uri.parse('$kBaseUrl/orders?confirmed=true'),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<List<dynamic>> getMyOrders() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/orders/my'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res);
    return [];
  }

  Future<List<dynamic>> getAllOrders({String? status}) async {
    final uri = Uri.parse('$kBaseUrl/orders').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final res = await _safeGet(uri);
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res);
    return [];
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/orders/$orderId'));
    return _handle(res);
  }

  // ── Invoicing ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getInvoicingDashboard() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/invoicing/dashboard'));
    return _handle(res);
  }

  Future<Map<String, dynamic>> markInvoiced(
      String orderId, String invoiceNumber) async {
    final res = await _safePatch(
      Uri.parse('$kBaseUrl/orders/$orderId/invoice'),
      body: jsonEncode({'invoice_number': invoiceNumber}),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> cancelOrder(
      String orderId, String reason) async {
    final res = await _safePatch(
      Uri.parse('$kBaseUrl/orders/$orderId/cancel'),
      body: jsonEncode({'cancel_reason': reason}),
    );
    return _handle(res);
  }

  // ── Manager ───────────────────────────────────────────────
  Future<Map<String, dynamic>> getManagerDashboard({int days = 30}) async {
    final res = await _safeGet(
        Uri.parse('$kBaseUrl/manager/dashboard?days=$days'));
    return _handle(res);
  }

  // ── Driver ────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDriverDashboard() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/driver/dashboard'));
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateDelivery(
    String orderId,
    bool delivered, {
    String? reason,
    List<int>? photoBytes,
    String photoMime = 'image/jpeg',
  }) async {
    final uri = Uri.parse('$kBaseUrl/orders/$orderId/delivery');
    final request = http.MultipartRequest('PATCH', uri)
      ..headers.addAll({
        if (_token != null) 'Authorization': 'Bearer $_token',
      })
      ..fields['delivered'] = delivered.toString();
    if (reason != null) request.fields['reason'] = reason;
    if (photoBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        photoBytes,
        filename: 'delivery.jpg',
        contentType: MediaType.parse(photoMime),
      ));
    }
    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException(timeout: true);
    }
  }

  Future<Map<String, dynamic>> markLoading(
      String orderId, String deliveryNoteNumber, String invoiceNumber) async {
    final res = await _safePatch(
      Uri.parse('$kBaseUrl/orders/$orderId/loading'),
      body: jsonEncode({
        'delivery_note_number': deliveryNoteNumber,
        'invoice_number': invoiceNumber,
      }),
    );
    return _handle(res);
  }

  // ── Customers ─────────────────────────────────────────────
  Future<List<String>> getCustomers() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/customers'));
    if (res.statusCode == 200) return List<String>.from(jsonDecode(res.body));
    _handle(res);
    return [];
  }

  Future<Map<String, dynamic>> adminBulkImportCustomers(
      List<String> customers) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/customers/bulk'),
        body: jsonEncode(customers));
    return _handle(res);
  }

  Future<Map<String, dynamic>> adminAddCustomer(String name) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/customers/add'),
        body: jsonEncode({'name': name}));
    return _handle(res);
  }

  Future<List<dynamic>> adminListCustomers() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/admin/customers'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res);
    return [];
  }

  Future<void> adminDeleteCustomer(String customerId) async {
    final res =
        await _safeDelete(Uri.parse('$kBaseUrl/admin/customers/$customerId'));
    if (res.statusCode != 204) _handle(res);
  }

  // ── Inventory ─────────────────────────────────────────────
  Future<Map<String, dynamic>> adminBulkImportInventory(
      List<Map<String, dynamic>> items) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/inventory/bulk'),
        body: jsonEncode(items));
    return _handle(res);
  }

  Future<Map<String, dynamic>> adminAddInventoryItem(
      Map<String, dynamic> body) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/inventory/add'),
        body: jsonEncode(body));
    return _handle(res);
  }

  Future<List<dynamic>> adminListInventory() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/admin/inventory'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res);
    return [];
  }

  Future<void> adminDeleteInventoryItem(String itemId) async {
    final res =
        await _safeDelete(Uri.parse('$kBaseUrl/admin/inventory/$itemId'));
    if (res.statusCode != 204) _handle(res);
  }

  Future<List<dynamic>> getInventory() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/inventory'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res);
    return [];
  }

  // ── Admin: Users ──────────────────────────────────────────
  Future<List<dynamic>> adminListUsers() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/admin/users'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res);
    return [];
  }

  Future<Map<String, dynamic>> adminCreateUser(
      Map<String, dynamic> body) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/users'),
        body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> adminUpdateUser(
      String userId, Map<String, dynamic> body) async {
    final res = await _safePatch(Uri.parse('$kBaseUrl/admin/users/$userId'),
        body: jsonEncode(body));
    return _handle(res);
  }

  Future<void> adminDeleteUser(String userId) async {
    final res = await _safeDelete(Uri.parse('$kBaseUrl/admin/users/$userId'));
    if (res.statusCode != 204) _handle(res);
  }

  // ── Orders: Edit & Delete ─────────────────────────────────
  Future<Map<String, dynamic>> editOrder(
      String orderId, Map<String, dynamic> body) async {
    final res = await _safePatch(Uri.parse('$kBaseUrl/orders/$orderId'),
        body: jsonEncode(body));
    return _handle(res);
  }

  Future<void> deleteOrder(String orderId) async {
    final res = await _safeDelete(Uri.parse('$kBaseUrl/orders/$orderId'));
    if (res.statusCode != 204) _handle(res);
  }

  // ── Safe HTTP wrappers ────────────────────────────────────
  Future<http.Response> _safeGet(Uri uri) async {
    try {
      return await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException(timeout: true);
    }
  }

  Future<http.Response> _safePost(Uri uri, {String? body}) async {
    try {
      return await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException(timeout: true);
    }
  }

  Future<http.Response> _safePatch(Uri uri, {String? body}) async {
    try {
      return await http
          .patch(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException(timeout: true);
    }
  }

  Future<http.Response> _safeDelete(Uri uri, {String? body}) async {
    try {
      final request = http.Request('DELETE', uri);
      request.headers.addAll(_headers);
      if (body != null) request.body = body;
      final streamed = await request.send().timeout(const Duration(seconds: 15));
      return await http.Response.fromStream(streamed);
    } on SocketException {
      throw NetworkException();
    } on TimeoutException {
      throw NetworkException(timeout: true);
    }
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body is List) return {'list': body};
      return body as Map<String, dynamic>;
    }
    final detail =
        (body is Map) ? (body['detail'] ?? 'Request failed') : 'Request failed';
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

class NetworkException implements Exception {
  final bool timeout;
  NetworkException({this.timeout = false});
  @override
  String toString() => timeout
      ? 'Request timed out. Check your connection.'
      : 'No internet connection. Please check your network.';
}

// ─────────────────────────────────────────────────────────────
//  Shared UI helpers
// ─────────────────────────────────────────────────────────────
Color deptColor(String dept) {
  switch (dept) {
    case 'Admin':
      return const Color(0xFFDC2626);
    case 'Sales Team':
      return const Color(0xFF1A56DB);
    case 'Invoicing Team':
      return const Color(0xFF7E3AF2);
    case 'Manager':
      return const Color(0xFF057A55);
    case 'Driver':
      return const Color(0xFFE3A008);
    default:
      return Colors.grey;
  }
}

IconData deptIcon(String dept) {
  switch (dept) {
    case 'Admin':
      return Icons.admin_panel_settings_outlined;
    case 'Sales Team':
      return Icons.shopping_cart_outlined;
    case 'Invoicing Team':
      return Icons.receipt_outlined;
    case 'Manager':
      return Icons.bar_chart_outlined;
    case 'Driver':
      return Icons.local_shipping_outlined;
    default:
      return Icons.person_outline;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'Pending':
      return Colors.orange;
    case 'Invoiced':
      return const Color(0xFF1A56DB);
    case 'Delivered':
      return Colors.green;
    case 'Cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

void showSnack(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(
          error
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          size: 16),
      const SizedBox(width: 10),
      Expanded(
          child: Text(msg,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600))),
    ]),
    backgroundColor: const Color(0xFF1C2B5E),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
          color: (error ? const Color(0xFFEF4444) : const Color(0xFF10B981))
              .withOpacity(0.3)),
    ),
    duration: const Duration(seconds: 3),
  ));
}

Future<void> logout(BuildContext context) async {
  // Remove FCM token before clearing prefs
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await ApiService().removeFcmToken(fcmToken);
    }
  } catch (e) {
    debugPrint('[FCM] Error removing token on logout: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}