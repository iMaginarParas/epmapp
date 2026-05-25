import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _contentCtrl;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Stack(
        children: [
          // ── Soft wave shapes in background (top-right & bottom-left) ──
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6E4FF).withOpacity(0.6),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBDD5FF).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6E4FF).withOpacity(0.5),
              ),
            ),
          ),

          SafeArea(
            child: SlideTransition(
              position: _contentSlide,
              child: FadeTransition(
                opacity: _contentOpacity,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // ── Logo section ──────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                            child: Column(
                              children: [
                                // Logo image
                                Image.asset(
                                  'assets/invent.png',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                // App name
                                const Text(
                                  'EPM',
                                  style: TextStyle(
                                    color: Color(0xFF1A3A6B),
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    height: 1,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 1.5,
                                      color: const Color(0xFF8094AE),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        'O R D E R S',
                                        style: TextStyle(
                                          color: Color(0xFF5A7AA8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 3,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 30,
                                      height: 1.5,
                                      color: const Color(0xFF8094AE),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Order. Track. Deliver.',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── White login card ──────────────────────
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A56DB).withOpacity(0.08),
                                    blurRadius: 32,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const _LoginForm(),
                            ),
                          ),

                          // ── Footer ────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.verified_user_outlined,
                                  color: Color(0xFF1A56DB),
                                  size: 22,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Secure. Reliable. Built for Performance.',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '© 2024 EPM Orders. All rights reserved.',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 10,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Field decoration
// ─────────────────────────────────────────────────────────────
InputDecoration _field(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1A56DB)),
      filled: true,
      fillColor: const Color(0xFFF7F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4EAF4), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.8),
      ),
    );

// ─────────────────────────────────────────────────────────────
//  Login Form
// ─────────────────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true, _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().login(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await _save(data);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> d) async {
    final prefs = await SharedPreferences.getInstance();
    final token = d['access_token'] as String;
    await prefs.setString('token', token);
    await prefs.setString('department', d['department'] as String);
    await prefs.setString('full_name', d['full_name'] as String);
    await prefs.setString('username', d['username'] as String);
    ApiService().setToken(token);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            department: d['department'] as String,
            fullName: d['full_name'] as String,
            username: d['username'] as String,
            token: token,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Heading ──────────────────────────────────────
            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1B2D),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please sign in to continue',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 28),

            // ── Username field ────────────────────────────────
            TextFormField(
              controller: _userCtrl,
              decoration: _field('Username', Icons.person_outline),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
            ),
            const SizedBox(height: 16),

            // ── Password field ────────────────────────────────
            TextFormField(
              controller: _passCtrl,
              decoration: _field('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),

            const SizedBox(height: 32),

            // ── LOGIN button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3A6B),
                  disabledBackgroundColor:
                      const Color(0xFF1A3A6B).withOpacity(0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('LOGIN'),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Divider ───────────────────────────────────────
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
              ],
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'Contact your administrator to get access.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}