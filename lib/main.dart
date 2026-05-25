import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
//  Splash / Auth Gate  —  Animated Welcome Screen
// ─────────────────────────────────────────────────────────────
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with TickerProviderStateMixin {

  // ── Animation controllers ─────────────────────────────────
  late final AnimationController _bgCtrl;      // background gradient sweep
  late final AnimationController _logoCtrl;    // logo entrance
  late final AnimationController _ringCtrl;    // pulsing ring
  late final AnimationController _textCtrl;    // text + tagline fade-up
  late final AnimationController _exitCtrl;    // whole-screen exit zoom
  late final AnimationController _shimmerCtrl; // shimmer sweep on logo box

  // ── Logo animations ───────────────────────────────────────
  late final Animation<double>  _logoScale;
  late final Animation<double>  _logoOpacity;
  late final Animation<Offset>  _logoSlide;

  // ── Ring glow ─────────────────────────────────────────────
  late final Animation<double>  _ringScale;
  late final Animation<double>  _ringOpacity;

  // ── Text ──────────────────────────────────────────────────
  late final Animation<double>  _titleOpacity;
  late final Animation<Offset>  _titleSlide;
  late final Animation<double>  _tagOpacity;
  late final Animation<Offset>  _tagSlide;
  late final Animation<double>  _lineWidth;    // animated underline

  // ── Shimmer ───────────────────────────────────────────────
  late final Animation<double>  _shimmerPos;

  // ── Exit ─────────────────────────────────────────────────
  late final Animation<double>  _exitScale;
  late final Animation<double>  _exitOpacity;

  // ── Background gradient angle ─────────────────────────────
  late final Animation<double>  _bgAngle;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // ── 1. Background gradient slow rotation ─────────────────
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat();
    _bgAngle = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);

    // ── 2. Logo entrance — bouncy scale + fade + slide ────────
    _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    );
    _logoScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96)
          .chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
    ]).animate(_logoCtrl);
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl,
          curve: const Interval(0, 0.4, curve: Curves.easeIn)));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    // ── 3. Pulsing glow ring ──────────────────────────────────
    _ringCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _ringScale   = Tween<double>(begin: 1.0, end: 1.35).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));
    _ringOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    // ── 4. Text entrance ─────────────────────────────────────
    _textCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0, 0.6)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _tagOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1.0)));
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
    _lineWidth = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));

    // ── 5. Shimmer sweep on logo box ─────────────────────────
    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    );
    _shimmerPos = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // ── 6. Exit animation ────────────────────────────────────
    _exitCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn)));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Step 1: logo bounces in
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoCtrl.forward();

    // Step 2: shimmer sweep after logo settles
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    _shimmerCtrl.forward();

    // Step 3: text slides up
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _textCtrl.forward();

    // Step 4: hold, then check auth and exit
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token    = prefs.getString('token');
    final dept     = prefs.getString('department');
    final fullName = prefs.getString('full_name') ?? '';
    final username = prefs.getString('username') ?? '';

    if (!mounted) return;

    // Play exit animation
    _ringCtrl.stop();
    await _exitCtrl.forward();

    if (!mounted || _navigated) return;
    _navigated = true;

    if (token != null && dept != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => DashboardPage(
            department: dept,
            fullName: fullName,
            username: username,
            token: token,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
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
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _bgCtrl, _logoCtrl, _ringCtrl, _textCtrl, _shimmerCtrl, _exitCtrl,
      ]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF060D1F),
          body: FadeTransition(
            opacity: _exitOpacity,
            child: Transform.scale(
              scale: _exitScale.value,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  // ── Animated mesh background ──────────────
                  CustomPaint(
                    painter: _MeshBackgroundPainter(t: _bgAngle.value),
                  ),

                  // ── Radial glow behind logo ───────────────
                  Positioned(
                    left: size.width / 2 - 160,
                    top: size.height * 0.28 - 160,
                    child: Container(
                      width: 320, height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF1A56DB).withOpacity(0.30),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),

                  // ── Main content ──────────────────────────
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // ── Logo block ────────────────────────
                      SlideTransition(
                        position: _logoSlide,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [

                                // Outer pulsing ring
                                Transform.scale(
                                  scale: _ringScale.value,
                                  child: Opacity(
                                    opacity: _ringOpacity.value,
                                    child: Container(
                                      width: 120, height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF1A56DB),
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Mid ring (faster pulse offset)
                                Transform.scale(
                                  scale: 1.0 + (_ringScale.value - 1.0) * 0.55,
                                  child: Opacity(
                                    opacity: _ringOpacity.value * 0.6,
                                    child: Container(
                                      width: 108, height: 108,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFF5A623),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Logo box with shimmer
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: Stack(
                                    children: [
                                      // Logo container
                                      Container(
                                        width: 96, height: 96,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(26),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF1A56DB).withOpacity(0.5),
                                              blurRadius: 32,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Image.asset(
                                          'assets/invent.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),

                                      // Shimmer overlay
                                      Positioned.fill(
                                        child: Transform.translate(
                                          offset: Offset(
                                            _shimmerPos.value * 96, 0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(26),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0),
                                                  Colors.white.withOpacity(0.55),
                                                  Colors.white.withOpacity(0),
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Title ─────────────────────────────
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: Column(
                            children: [
                              // Letter-spaced title
                              const Text(
                                'EPM ORDER DESK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Animated underline
                              Align(
                                alignment: Alignment.center,
                                child: FractionallySizedBox(
                                  widthFactor: _lineWidth.value,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF1A56DB),
                                        Color(0xFFF5A623),
                                      ]),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Tagline ───────────────────────────
                      SlideTransition(
                        position: _tagSlide,
                        child: FadeTransition(
                          opacity: _tagOpacity,
                          child: const Text(
                            'Internal Operations Platform',
                            style: TextStyle(
                              color: Color(0xFF8494B4),
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),

                      // ── Loading dots ──────────────────────
                      FadeTransition(
                        opacity: _tagOpacity,
                        child: _PulsingDots(),
                      ),
                    ],
                  ),

                  // ── Corner accent lines ───────────────────
                  Positioned(
                    top: 0, left: 0,
                    child: Opacity(
                      opacity: _titleOpacity.value * 0.4,
                      child: CustomPaint(
                        size: const Size(80, 80),
                        painter: _CornerLinePainter(topLeft: true),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Opacity(
                      opacity: _titleOpacity.value * 0.4,
                      child: CustomPaint(
                        size: const Size(80, 80),
                        painter: _CornerLinePainter(topLeft: false),
                      ),
                    ),
                  ),

                  // ── Version tag ───────────────────────────
                  Positioned(
                    bottom: 28,
                    left: 0, right: 0,
                    child: FadeTransition(
                      opacity: _tagOpacity,
                      child: const Text(
                        'v2.0.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF3A4A6A),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Animated mesh background painter ─────────────────────────
class _MeshBackgroundPainter extends CustomPainter {
  final double t;
  const _MeshBackgroundPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark base
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFF060D1F));

    // Slow-moving gradient orbs
    final orbs = [
      _Orb(cx: 0.15 + 0.1 * _sin(t * 0.7), cy: 0.2 + 0.08 * _cos(t * 0.5),
           r: size.width * 0.55,
           color: const Color(0xFF1A56DB).withOpacity(0.12)),
      _Orb(cx: 0.85 - 0.08 * _sin(t * 0.6), cy: 0.75 + 0.1 * _cos(t * 0.8),
           r: size.width * 0.5,
           color: const Color(0xFF0D2A6B).withOpacity(0.18)),
      _Orb(cx: 0.5 + 0.12 * _cos(t * 0.4), cy: 0.45 + 0.06 * _sin(t * 0.9),
           r: size.width * 0.3,
           color: const Color(0xFFF5A623).withOpacity(0.05)),
    ];

    for (final orb in orbs) {
      canvas.drawCircle(
        Offset(orb.cx * size.width, orb.cy * size.height),
        orb.r,
        Paint()
          ..shader = RadialGradient(colors: [orb.color, Colors.transparent])
              .createShader(Rect.fromCircle(
                center: Offset(orb.cx * size.width, orb.cy * size.height),
                radius: orb.r)),
      );
    }

    // Subtle grid dots
    final dotPaint = Paint()
      ..color = const Color(0xFF1A56DB).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  double _sin(double v) => math.sin(v * math.pi * 2);
  double _cos(double v) => math.cos(v * math.pi * 2);

  @override
  bool shouldRepaint(_MeshBackgroundPainter old) => old.t != t;
}

class _Orb {
  final double cx, cy, r;
  final Color color;
  const _Orb({required this.cx, required this.cy, required this.r, required this.color});
}

// ── Corner accent line painter ────────────────────────────────
class _CornerLinePainter extends CustomPainter {
  final bool topLeft;
  const _CornerLinePainter({required this.topLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A56DB).withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (topLeft) {
      canvas.drawLine(const Offset(0, 40), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), const Offset(40, 0), paint);
    } else {
      canvas.drawLine(Offset(size.width, size.height - 40),
          Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height),
          Offset(size.width - 40, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerLinePainter old) => false;
}

// ── Three pulsing loading dots ────────────────────────────────
class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      );
      final anim = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      );
      _ctrls.add(ctrl);
      _anims.add(anim);

      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == 1
                  ? Color.lerp(const Color(0xFF1A56DB),
                      const Color(0xFFF5A623), _anims[i].value)!
                      .withOpacity(_anims[i].value)
                  : const Color(0xFF1A56DB).withOpacity(_anims[i].value),
            ),
          ),
        );
      }),
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

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/auth/login'),
        body: jsonEncode({'username': username, 'password': password}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> getManagerDashboard({int days = 30}) async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/manager/dashboard?days=$days'));
    return _handle(res);
  }

  Future<Map<String, dynamic>> getInvoicingDashboard() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/invoicing/dashboard'));
    return _handle(res);
  }

  Future<Map<String, dynamic>> getDriverDashboard() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/driver/dashboard'));
    return _handle(res);
  }

  Future<List<dynamic>> getMyOrders() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/orders/my'));
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
    final res = await _safePost(uri, body: jsonEncode(body));
    return _handle(res);
  }

  Future<List<dynamic>> getAllOrders({String? status}) async {
    final uri = Uri.parse('$kBaseUrl/orders').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final res = await _safeGet(uri);
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      return [];
    }
    _handle(res);
    return [];
  }

  Future<Map<String, dynamic>> markInvoiced(String orderId, String invoiceNumber) async {
    final res = await _safePatch(Uri.parse('$kBaseUrl/orders/$orderId/invoice'),
        body: jsonEncode({'invoice_number': invoiceNumber}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId, String reason) async {
    final res = await _safePatch(Uri.parse('$kBaseUrl/orders/$orderId/cancel'),
        body: jsonEncode({'cancel_reason': reason}));
    return _handle(res);
  }

  Future<Map<String, dynamic>> updateDelivery(
      String orderId, bool delivered, {String? reason, List<int>? photoBytes, String? photoMime}) async {
    try {
      final request = http.MultipartRequest(
        'PATCH', Uri.parse('$kBaseUrl/orders/$orderId/delivery'),
      );
      request.headers['Authorization'] = 'Bearer $_token';
      request.fields['delivered'] = delivered.toString();
      if (reason != null) request.fields['reason'] = reason;
      if (photoBytes != null && photoMime != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photo', photoBytes,
          filename: 'delivery.jpg',
          contentType: MediaType.parse(photoMime),
        ));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } on SocketException { throw NetworkException(); }
      on TimeoutException { throw NetworkException(timeout: true); }
  }

  Future<List<String>> getCustomers() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/customers'));
    if (res.statusCode == 200) return List<String>.from(jsonDecode(res.body));
    _handle(res); return [];
  }

  // ── Admin: Customers ─────────────────────────────────────
  Future<Map<String, dynamic>> adminBulkImportCustomers(List<String> names) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/customers/bulk'), body: jsonEncode(names));
    return _handle(res);
  }

  Future<Map<String, dynamic>> adminAddCustomer(String name) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/customers/add'), body: jsonEncode({'name': name}));
    return _handle(res);
  }

  Future<List<dynamic>> adminListCustomers() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/admin/customers'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res); return [];
  }

  Future<void> adminDeleteCustomer(String customerId) async {
    final res = await _safeDelete(Uri.parse('$kBaseUrl/admin/customers/$customerId'));
    if (res.statusCode != 204) _handle(res);
  }

  // ── Admin: Inventory ──────────────────────────────────────
  Future<Map<String, dynamic>> adminBulkImportInventory(List<Map<String, dynamic>> items) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/inventory/bulk'), body: jsonEncode(items));
    return _handle(res);
  }

  Future<Map<String, dynamic>> adminAddInventoryItem(Map<String, dynamic> body) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/inventory/add'), body: jsonEncode(body));
    return _handle(res);
  }

  Future<List<dynamic>> adminListInventory() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/admin/inventory'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res); return [];
  }

  Future<void> adminDeleteInventoryItem(String itemId) async {
    final res = await _safeDelete(Uri.parse('$kBaseUrl/admin/inventory/$itemId'));
    if (res.statusCode != 204) _handle(res);
  }

  Future<List<dynamic>> getInventory() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/inventory'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res); return [];
  }

  // ── Admin: Users ──────────────────────────────────────────
  Future<List<dynamic>> adminListUsers() async {
    final res = await _safeGet(Uri.parse('$kBaseUrl/admin/users'));
    if (res.statusCode == 200) return jsonDecode(res.body) as List;
    _handle(res); return [];
  }

  Future<Map<String, dynamic>> adminCreateUser(Map<String, dynamic> body) async {
    final res = await _safePost(Uri.parse('$kBaseUrl/admin/users'), body: jsonEncode(body));
    return _handle(res);
  }

  Future<Map<String, dynamic>> adminUpdateUser(String userId, Map<String, dynamic> body) async {
    final res = await _safePatch(Uri.parse('$kBaseUrl/admin/users/$userId'), body: jsonEncode(body));
    return _handle(res);
  }

  Future<void> adminDeleteUser(String userId) async {
    final res = await _safeDelete(Uri.parse('$kBaseUrl/admin/users/$userId'));
    if (res.statusCode != 204) _handle(res);
  }

  // ── Edit & delete pending orders ─────────────────────────
  Future<Map<String, dynamic>> editOrder(String orderId, Map<String, dynamic> body) async {
    final res = await _safePatch(Uri.parse('$kBaseUrl/orders/$orderId'), body: jsonEncode(body));
    return _handle(res);
  }

  Future<void> deleteOrder(String orderId) async {
    final res = await _safeDelete(Uri.parse('$kBaseUrl/orders/$orderId'));
    if (res.statusCode != 204) _handle(res);
  }

  // ── Safe HTTP wrappers — SocketException + timeout ────────
  Future<http.Response> _safeGet(Uri uri) async {
    try {
      return await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
    } on SocketException { throw NetworkException(); }
      on TimeoutException { throw NetworkException(timeout: true); }
  }

  Future<http.Response> _safePost(Uri uri, {String? body}) async {
    try {
      return await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
    } on SocketException { throw NetworkException(); }
      on TimeoutException { throw NetworkException(timeout: true); }
  }

  Future<http.Response> _safePatch(Uri uri, {String? body}) async {
    try {
      return await http.patch(uri, headers: _headers, body: body).timeout(const Duration(seconds: 15));
    } on SocketException { throw NetworkException(); }
      on TimeoutException { throw NetworkException(timeout: true); }
  }

  Future<http.Response> _safeDelete(Uri uri) async {
    try {
      return await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
    } on SocketException { throw NetworkException(); }
      on TimeoutException { throw NetworkException(timeout: true); }
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
    case 'Admin':          return const Color(0xFFDC2626);
    case 'Sales Team':     return const Color(0xFF1A56DB);
    case 'Invoicing Team': return const Color(0xFF7E3AF2);
    case 'Manager':        return const Color(0xFF057A55);
    case 'Driver':         return const Color(0xFFE3A008);
    default:               return Colors.grey;
  }
}

IconData deptIcon(String dept) {
  switch (dept) {
    case 'Admin':          return Icons.admin_panel_settings_outlined;
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