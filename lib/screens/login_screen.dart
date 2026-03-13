import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';
import 'auth_redirector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _phoneController = TextEditingController();

  bool isOtpLoading = false;
  bool isGoogleLoading = false;
  bool isOverlayLoading = false;

  String _verificationId = "";

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ================= OTP =================

  Future<void> _verifyPhone() async {
    setState(() => isOtpLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${_phoneController.text.trim()}',
      timeout: const Duration(seconds: 60),

      verificationCompleted: (cred) async {
        await _completeLogin(cred);
      },

      verificationFailed: (e) {
        setState(() => isOtpLoading = false);
        _showError(e.message ?? "OTP verification failed");
      },

      codeSent: (id, _) {
        setState(() {
          isOtpLoading = false;
          _verificationId = id;
        });
        _showOtpDialog();
      },

      codeAutoRetrievalTimeout: (_) {
        setState(() => isOtpLoading = false);
      },
    );
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Enter OTP"),
        content: TextField(
          controller: otpController,
          maxLength: 6,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(counterText: ""),
        ),
        actions: [
          TextButton(
            child: const Text("Verify"),
            onPressed: () async {
              Navigator.pop(context); // close dialog first
              setState(() => isOverlayLoading = true);

              try {
                final cred = PhoneAuthProvider.credential(
                  verificationId: _verificationId,
                  smsCode: otpController.text.trim(),
                );
                await _completeLogin(cred);
              } catch (_) {
                setState(() => isOverlayLoading = false);
                _showError("Invalid OTP");
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= GOOGLE =================

  Future<void> _googleLogin() async {
    setState(() => isGoogleLoading = true);

    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        setState(() => isGoogleLoading = false);
        return;
      }

      final auth = await user.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      await _completeLogin(cred);
    } catch (_) {
      setState(() => isGoogleLoading = false);
      _showError("Google sign-in failed");
    }
  }

  // ================= AUTH COMPLETE =================

  Future<void> _completeLogin(AuthCredential credential) async {
    try {
      setState(() => isOverlayLoading = true);

      final result = await _auth.signInWithCredential(credential);

      if (result.user == null) {
        throw Exception("Authentication failed");
      }

      if (!mounted) return;

      // ✅ STOP loaders BEFORE navigation
      setState(() {
        isGoogleLoading = false;
        isOverlayLoading = false;
      });

      // ✅ SINGLE SOURCE OF NAVIGATION
      await AuthRedirector.redirect(context);

    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGoogleLoading = false;
        isOverlayLoading = false;
      });

      _showError("Authentication failed. Please try again.");
    }
  }

  // ================= NAV =================



  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.white),
            onSelected: (value) {
              if (value == 'en') {
                DirectMarketApp.of(context)
                    ?.setLocale(const Locale('en'));
              } else {
                DirectMarketApp.of(context)
                    ?.setLocale(const Locale('hi'));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'en',
                child: Text("English"),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Text("हिंदी"),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFF81C784)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: _loginCard(),
                ),
              ),
            ),
          ),

          if (isOverlayLoading) _loadingOverlay(),
        ],
      ),
    );
  }

  Widget _loginCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(blurRadius: 25, color: Colors.black12, offset: Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/login_screen_photo.jpg', height: 90),
            const SizedBox(height: 12),
            Text("KrashiAI",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const Text("Direct Market Access for Farmers",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            _phoneField(),
            const SizedBox(height: 16),
            _otpButton(),

            const SizedBox(height: 16),
            const Text("OR", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            _googleButton(),
          ],
        ),
      ),
    );
  }

  Widget _phoneField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: const Text("+91",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Enter mobile number",
                counterText: "",
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpButton() {
    final valid = _phoneController.text.trim().length == 10;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: valid && !isOtpLoading ? _verifyPhone : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: valid ? Colors.green : Colors.grey,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isOtpLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : const Text("Get OTP",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: isGoogleLoading
            ? const SizedBox(
            height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Image.asset("assets/images/google_logo.jpeg", height: 18),
        label: const Text("Continue with Google"),
        onPressed: isGoogleLoading ? null : _googleLogin,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black38,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
