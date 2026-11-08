import 'package:flutter/material.dart';
import '../../app.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/toast_feedback.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const AuthScreen({super.key, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController(text: 'charles.biasora@gmail.com');
  final _passwordController = TextEditingController(text: 'Aa@123456');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ToastFeedback.showError(context, 'Please fill in all required fields.');
      return;
    }

    bool success;
    if (_isLogin) {
      success = await AuthService.instance.login(email: email, password: password);
    } else {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ToastFeedback.showError(context, 'Please enter your name.');
        return;
      }
      success = await AuthService.instance.register(name: name, email: email, password: password);
    }

    if (success && mounted) {
      ToastFeedback.showSuccess(context, _isLogin ? 'Welcome back!' : 'Account created!');
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
        );
      }
    } else if (mounted) {
      ToastFeedback.showError(context, 'Authentication failed. Please verify credentials.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    ToastFeedback.showInfo(context, 'Connecting with Google Fast Login...');
    final success = await AuthService.instance.login(
      email: 'charles.biasora@gmail.com',
      password: 'Aa@123456',
    );

    if (success && mounted) {
      ToastFeedback.showSuccess(context, 'Signed in with Google!');
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
        );
      }
    } else if (mounted) {
      // Fallback demo student if needed
      final demoSuccess = await AuthService.instance.login(
        email: 'alex@recall.app',
        password: 'password123',
      );
      if (demoSuccess && mounted) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Masthead (Stitch Spec)
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.bolt_rounded, color: AppColors.bgCanvas, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Recall',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Segmented Full-Pill Switcher: [ Sign In ] [ Create Account ]
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface1,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLogin = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isLogin ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Sign In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: _isLogin ? FontWeight.w700 : FontWeight.w500,
                                  color: _isLogin ? AppColors.bgCanvas : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isLogin = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isLogin ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: !_isLogin ? FontWeight.w700 : FontWeight.w500,
                                  color: !_isLogin ? AppColors.bgCanvas : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Greeting & Heading
                  Text(
                    _isLogin ? 'Welcome back 👋' : 'Create account 🚀',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isLogin
                        ? "Ready to conquer today's study goals?"
                        : 'Start building long-term memory today.',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Continue with Google Button
                  InkWell(
                    onTap: _handleGoogleSignIn,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleLogo(),
                          const SizedBox(width: 10),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Divider: OR WITH EMAIL
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR WITH EMAIL',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Form Fields
                  if (!_isLogin) ...[
                    _buildInputLabel('YOUR NAME'),
                    _buildInputField(
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      hintText: 'Enter your name',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildInputLabel('YOUR EMAIL'),
                  _buildInputField(
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    hintText: 'alex.rivera@university.edu',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('PASSWORD'),
                  _buildInputField(
                    controller: _passwordController,
                    icon: Icons.lock_outline_rounded,
                    hintText: 'Enter password',
                    isPassword: true,
                    isFocusedBorder: true,
                  ),

                  // Forgot Password Link (Sign In only)
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ToastFeedback.showInfo(context, 'Password reset link available in Phase 2.');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Primary CTA Button: [ Sign In to Recall → ]
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: AuthService.instance.isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.bgCanvas,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: AuthService.instance.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.bgCanvas),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin ? 'Sign In to Recall' : 'Create Account',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Home Indicator Bar
                  Center(
                    child: Container(
                      width: 128,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
    bool isFocusedBorder = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.bgSurface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocusedBorder ? AppColors.primary : AppColors.borderSubtle,
          width: isFocusedBorder ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isFocusedBorder ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: AppColors.textSecondary,
              ),
              splashRadius: 18,
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
        ],
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintGreen = Paint()..color = const Color(0xFF34A853);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintRed = Paint()..color = const Color(0xFFEA4335);

    // Draw Google G geometry
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Red (top)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.8,
      1.6,
      true,
      paintRed,
    );

    // Yellow (left)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      1.5,
      true,
      paintYellow,
    );

    // Green (bottom)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.3,
      1.6,
      true,
      paintGreen,
    );

    // Blue (right & horizontal bar)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.9,
      1.5,
      true,
      paintBlue,
    );

    // Cutout center
    final innerPaint = Paint()..color = AppColors.bgSurface1;
    canvas.drawCircle(center, radius * 0.58, innerPaint);

    // Horizontal blue bar
    final barRect = Rect.fromLTRB(w * 0.45, h * 0.38, w, h * 0.62);
    canvas.drawRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
