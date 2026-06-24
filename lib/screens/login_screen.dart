import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor:
        isError ? Colors.red[400] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final double sw = size.width;
    final double sh = size.height;
    final double scale = (sw.clamp(0.0, 430.0) / 375).clamp(0.85, 1.1);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Warm rustic gradient — same family as Bobu Pizza
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F0),
              Color(0xFFFFF0DC),
              Color(0xFFFFE8C8),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: sh * 0.07),

                      // ── Hero icon ──
                      _buildHeroIcon(scale),

                      SizedBox(height: 28 * scale),

                      // ── Brand title ──
                      _buildBrandTitle(scale),

                      SizedBox(height: 36 * scale),

                      // ── Heading ──
                      Text(
                        'Welcome, Rider! 🛵',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24 * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D1A0E),
                        ),
                      ),
                      SizedBox(height: 6 * scale),
                      Text(
                        'Sign in to start delivering',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13 * scale,
                          color:
                          const Color(0xFF2D1A0E).withOpacity(0.5),
                        ),
                      ),

                      SizedBox(height: 36 * scale),

                      // ── Email field ──
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        scale: scale,
                      ),

                      SizedBox(height: 16 * scale),

                      // ── Password field ──
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        scale: scale,
                      ),

                      SizedBox(height: 28 * scale),

                      // ── Login button ──
                      authProvider.isLoading
                          ? _buildLoadingButton(scale)
                          : _buildLoginButton(authProvider, scale),

                      SizedBox(height: 28 * scale),

                      // ── Footer note ──
                      _buildFooterNote(scale),

                      SizedBox(height: 40 * scale),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hero icon ────────────────────────────────────────────────────

  Widget _buildHeroIcon(double scale) {
    return Container(
      width: 90 * scale,
      height: 90 * scale,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tomatoRed,
            Color.fromARGB(255,
              (AppColors.tomatoRed.red + 30).clamp(0, 255),
              AppColors.tomatoRed.green,
              AppColors.tomatoRed.blue,
            ),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.tomatoRed.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.delivery_dining_rounded,
        size: 46 * scale,
        color: Colors.white,
      ),
    );
  }

  // ─── Brand title ──────────────────────────────────────────────────

  Widget _buildBrandTitle(double scale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Bobu',
          style: GoogleFonts.hurricane(
            fontSize: 72 * scale,
            fontWeight: FontWeight.bold,
            color: AppColors.tomatoRed,
            height: 0.8,
            shadows: [
              Shadow(
                color: AppColors.tomatoRed.withOpacity(0.15),
                offset: Offset(2 * scale, 3 * scale),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28 * scale,
              height: 1.2,
              color: const Color(0xFF2E7D32).withOpacity(0.5),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Icon(
                Icons.delivery_dining_outlined,
                size: 13 * scale,
                color: const Color(0xFF2E7D32).withOpacity(0.7),
              ),
            ),
            Container(
              width: 28 * scale,
              height: 1.2,
              color: const Color(0xFF2E7D32).withOpacity(0.5),
            ),
          ],
        ),
        SizedBox(height: 2 * scale),
        Text(
          'Rider',
          style: GoogleFonts.italianno(
            fontSize: 32 * scale,
            color: const Color(0xFF2E7D32),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ─── Text field ───────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required double scale,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D5C0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4956A).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(
          fontSize: 14 * scale,
          color: const Color(0xFF2D1A0E),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF2D1A0E).withOpacity(0.35),
            fontSize: 14 * scale,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.tomatoRed.withOpacity(0.7),
            size: 20 * scale,
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF2D1A0E).withOpacity(0.4),
              size: 20 * scale,
            ),
            onPressed: () => setState(
                    () => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 20, vertical: 16 * scale),
        ),
      ),
    );
  }

  // ─── Loading button ───────────────────────────────────────────────

  Widget _buildLoadingButton(double scale) {
    return Container(
      width: double.infinity,
      height: 54 * scale,
      decoration: BoxDecoration(
        color: AppColors.tomatoRed.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.5),
        ),
      ),
    );
  }

  // ─── Login button ─────────────────────────────────────────────────

  Widget _buildLoginButton(AuthProvider authProvider, double scale) {
    return SizedBox(
      width: double.infinity,
      height: 54 * scale,
      child: ElevatedButton(
        onPressed: () async {
          if (_emailController.text.trim().isEmpty ||
              _passwordController.text.trim().isEmpty) {
            _showSnack('Please fill all fields');
            return;
          }
          final error = await authProvider.signIn(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
          if (error != null && mounted) {
            _showSnack(error);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tomatoRed,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: AppColors.tomatoRed.withOpacity(0.35),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          'Login',
          style: GoogleFonts.poppins(
            fontSize: 16 * scale,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─── Footer note ──────────────────────────────────────────────────

  Widget _buildFooterNote(double scale) {
    return Container(
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: AppColors.tomatoRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.tomatoRed.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.tomatoRed.withOpacity(0.6),
              size: 16 * scale),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              'This app is only for authorized Bobu Pizza delivery partners.',
              style: GoogleFonts.poppins(
                fontSize: 11 * scale,
                color: const Color(0xFF2D1A0E).withOpacity(0.55),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}