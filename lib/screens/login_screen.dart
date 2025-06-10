import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' show Random;
import 'home_screen.dart';
import 'attendence_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/password_provider.dart';
import '../providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _selectedLoginType = 'owner';
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(Duration(milliseconds: 100));
    if (!mounted) return;

    final sessionState = ref.read(sessionProvider);
    if (sessionState.isLoggedIn && sessionState.loginType != null) {
      _navigateBasedOnLoginType(sessionState.loginType!);
    }
    setState(() => _isInitialized = true);
  }

  void _navigateBasedOnLoginType(String loginType) {
    if (!mounted) return;

    if (loginType == 'owner') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (loginType == 'attendance') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AttendanceScreen()),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_selectedLoginType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a login type'),
          backgroundColor: Color(0xFF8E2DE2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final passwordService = ref.read(passwordProvider);
      final isValid = await passwordService.verifyPassword(
        _selectedLoginType!,
        _passwordController.text,
      );

      if (isValid) {
        await ref.read(sessionProvider.notifier).login(_selectedLoginType!);
        if (mounted) {
          _navigateBasedOnLoginType(_selectedLoginType!);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid password'),
              backgroundColor: Color(0xFF8E2DE2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Color(0xFF8E2DE2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A2E),
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8E2DE2),
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A2E),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GymAtmospherePainter(),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: _buildResponsiveLayout(
                    size, isLandscape, isTablet, isDesktop),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
      Size size, bool isLandscape, bool isTablet, bool isDesktop) {
    if (isDesktop) {
      return Container(
        height: size.height - MediaQuery.of(context).padding.top,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _buildBanner(size, isDesktop: true),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitle(),
                    SizedBox(height: 60),
                    _buildLoginOptions(),
                    SizedBox(height: 40),
                    _buildPasswordField(),
                    SizedBox(height: 40),
                    _buildLoginButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isTablet && isLandscape) {
      return Container(
        height: size.height - MediaQuery.of(context).padding.top,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildBanner(size, isTablet: true),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitle(),
                    SizedBox(height: 40),
                    _buildLoginOptions(),
                    SizedBox(height: 24),
                    _buildPasswordField(),
                    SizedBox(height: 32),
                    _buildLoginButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isTablet) {
      return Container(
        height: size.height - MediaQuery.of(context).padding.top,
        child: Column(
          children: [
            _buildBanner(size, isTablet: true, heightRatio: 0.4),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTitle(),
                    SizedBox(height: 40),
                    _buildLoginOptions(),
                    SizedBox(height: 24),
                    _buildPasswordField(),
                    SizedBox(height: 32),
                    _buildLoginButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isLandscape) {
      return Container(
        height: size.height - MediaQuery.of(context).padding.top,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildBanner(size),
            ),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTitle(),
                      SizedBox(height: 20),
                      _buildLoginOptions(),
                      SizedBox(height: 16),
                      _buildPasswordField(),
                      SizedBox(height: 20),
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        constraints: BoxConstraints(
          minHeight: size.height - MediaQuery.of(context).padding.top,
        ),
        child: Column(
          children: [
            _buildBanner(size, heightRatio: 0.35),
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTitle(),
                  SizedBox(height: 30),
                  _buildLoginOptions(),
                  SizedBox(height: 24),
                  _buildPasswordField(),
                  SizedBox(height: 32),
                  _buildLoginButton(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBanner(Size size,
      {bool isTablet = false,
      bool isDesktop = false,
      double heightRatio = 0.3}) {
    return Animate(
      effects: [
        FadeEffect(duration: Duration(milliseconds: 800)),
      ],
      child: Container(
        height: isDesktop
            ? size.height * 0.9
            : isTablet
                ? size.height * heightRatio
                : size.height * heightRatio,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(isLandscape(context) ? 0 : 20),
            bottomRight: Radius.circular(isLandscape(context) ? 0 : 20),
            topRight: Radius.circular(isLandscape(context) ? 20 : 0),
          ),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/banner3.png'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF1A1A2E).withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).size.width >
        MediaQuery.of(context).size.height;
  }

  Widget _buildTitle() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Column(
      children: [
        Animate(
          effects: [
            SlideEffect(
              begin: Offset(0, -0.2),
              end: Offset.zero,
            ),
          ],
          child: Text(
            'V Shape U Fitness',
            style: GoogleFonts.anton(
              fontSize: isSmallScreen ? 30 : 36,
              color: Color(0xFFF5F5F5),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Color(0xFF8E2DE2).withOpacity(0.7),
                  offset: Offset(1, 1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Animate(
          effects: [
            SlideEffect(
              begin: Offset(0, -0.2),
              end: Offset.zero,
            ),
          ],
          child: Text(
            'A SMARTER WAY TO GET FIT',
            style: GoogleFonts.montserrat(
              fontSize: isSmallScreen ? 14 : 16,
              color: Color(0xFFB388FF),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginOptions() {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Animate(
      effects: [
        SlideEffect(
          begin: Offset(-0.2, 0),
          end: Offset.zero,
        ),
      ],
      child: isSmallScreen
          ? Column(
              children: [
                _buildLoginOption(
                  'Owner Login',
                  Icons.fitness_center,
                  'owner',
                ),
                SizedBox(height: 16),
                _buildLoginOption(
                  'Attendance Login',
                  Icons.how_to_reg,
                  'attendance',
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildLoginOption(
                    'Owner Login',
                    Icons.fitness_center,
                    'owner',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildLoginOption(
                    'Attendance Login',
                    Icons.how_to_reg,
                    'attendance',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoginOption(String title, IconData icon, String type) {
    final isSelected = _selectedLoginType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedLoginType = type),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      Color(0xFF8E2DE2),
                      Color(0xFF4A00E0),
                    ]
                  : [
                      Color(0xFF2A2A2A),
                      Color(0xFF222222),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: Color(0xFFB388FF), width: 1.5)
                : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Color(0xFF8E2DE2).withOpacity(0.15),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Color(0xFFF5F5F5)
                    : Color(0xFFB388FF).withOpacity(0.9),
                size: 28,
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: isSelected
                      ? Color(0xFFF5F5F5)
                      : Color(0xFFFFFFFF).withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Animate(
      effects: [
        SlideEffect(
          begin: Offset(0.2, 0),
          end: Offset.zero,
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: GoogleFonts.poppins(color: Color(0xFFF5F5F5)),
          decoration: InputDecoration(
            hintText: 'Enter Password',
            hintStyle: GoogleFonts.poppins(
              color: Color(0xFFF5F5F5).withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Color(0xFFB388FF).withOpacity(0.8),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFFB388FF).withOpacity(0.8),
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            filled: true,
            fillColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Animate(
      effects: [
        SlideEffect(
          begin: Offset(0, 0.2),
          end: Offset.zero,
        ),
      ],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8E2DE2),
                  Color(0xFF4A00E0),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF8E2DE2).withOpacity(0.15),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Color(0xFFF5F5F5),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'LOGIN',
                      style: GoogleFonts.montserrat(
                        color: Color(0xFFF5F5F5),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class GymAtmospherePainter extends CustomPainter {
  final Random random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    _drawSpotlights(canvas, size);
    _drawEmbers(canvas, size);
    _drawSmoke(canvas, size);
  }

  void _drawSpotlights(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.5,
        colors: [
          Color(0xFF8E2DE2).withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final spotlightPositions = [
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.8, 0),
    ];

    for (var position in spotlightPositions) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }
  }

  void _drawEmbers(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(0xFFB388FF).withOpacity(0.15);

    final particleCount =
        (size.width * size.height / 20000).clamp(10, 40).toInt();

    for (var i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  void _drawSmoke(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02);

    final smokeCount = (size.width * size.height / 50000).clamp(5, 15).toInt();

    for (var i = 0; i < smokeCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 40 + 20;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
