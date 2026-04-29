import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'dashboard.dart';

const List<String> kDepartments = [
  'Sales Team',
  'Invoicing Team',
  'Manager',
  'Driver',
];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isSignIn = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _isSignIn = _tabs.index == 0));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B2D),
      body: Stack(
        children: [
          // Top blue arc background
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.42,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A3A6B), Color(0xFF0F1B2D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Header / Logo area ──────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/invent.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'EPM ORDER DESK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Internal Operations Platform',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Card ────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 32,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tab bar inside card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              controller: _tabs,
                              indicator: BoxDecoration(
                                color: const Color(0xFF1A56DB),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1A56DB).withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: const Color(0xFF8094AE),
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
                              dividerColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                              tabs: const [
                                Tab(text: 'Sign In'),
                                Tab(text: 'Sign Up'),
                              ],
                            ),
                          ),
                        ),

                        // Tab content — expands to fill rest of card
                        Expanded(
                          child: TabBarView(
                            controller: _tabs,
                            children: const [
                              _LoginForm(),
                              _SignupForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
//  Shared field decoration
// ─────────────────────────────────────────────────────────────
InputDecoration _field(String label, IconData icon) => InputDecoration(
  labelText: label,
  labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
  prefixIcon: Icon(icon, size: 19, color: const Color(0xFF8094AE)),
  filled: true,
  fillColor: const Color(0xFFF7F9FC),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE4EAF4), width: 1.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 1.8),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.red, width: 1.5),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Colors.red, width: 1.8),
  ),
);

Widget _submitBtn(String label, VoidCallback? onTap, bool loading) =>
    SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56DB),
          disabledBackgroundColor: const Color(0xFF1A56DB).withOpacity(0.6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
            : Text(label),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: Color(0xFF0F1B2D))),
            const SizedBox(height: 4),
            Text('Sign in to your account',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 22),
            TextFormField(
              controller: _userCtrl,
              decoration: _field('Username', Icons.alternate_email),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl,
              decoration: _field('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: const Color(0xFF8094AE),
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
            const SizedBox(height: 28),
            _submitBtn('Sign In', _loading ? null : _login, _loading),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Signup Form
// ─────────────────────────────────────────────────────────────
class _SignupForm extends StatefulWidget {
  const _SignupForm();
  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _dept;
  bool _obscure = true, _loading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dept == null) {
      showSnack(context, 'Please select your department', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ApiService().signup(
        username: _userCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
        password: _passCtrl.text,
        department: _dept!,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                    color: Color(0xFF0F1B2D))),
            const SizedBox(height: 4),
            Text('Fill in your details below',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameCtrl,
              decoration: _field('Full Name', Icons.badge_outlined),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter your full name' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _userCtrl,
              decoration: _field('Username', Icons.alternate_email),
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().length < 3) ? 'Min 3 characters' : null,
            ),
            const SizedBox(height: 12),

            // Department dropdown styled to match fields
            DropdownButtonFormField<String>(
              value: _dept,
              decoration: _field('Department', Icons.business_outlined),
              dropdownColor: Colors.white,
              iconEnabledColor: const Color(0xFF8094AE),
              style: const TextStyle(
                  color: Color(0xFF0F1B2D), fontSize: 14, fontWeight: FontWeight.w500),
              items: kDepartments.map((d) => DropdownMenuItem(
                value: d,
                child: Row(
                  children: [
                    Icon(deptIcon(d), size: 16, color: deptColor(d)),
                    const SizedBox(width: 10),
                    Text(d),
                  ],
                ),
              )).toList(),
              onChanged: (v) => setState(() => _dept = v),
              validator: (v) => v == null ? 'Select department' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _passCtrl,
              decoration: _field('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19,
                    color: const Color(0xFF8094AE),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 24),

            _submitBtn('Create Account', _loading ? null : _signup, _loading),
          ],
        ),
      ),
    );
  }
}