import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isAwaitingOtp = false;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _otpError;

  int _resendCooldown = 0;
  Timer? _resendTimer;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _resendTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  bool _validateInputs() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? nameErr;
    String? emailErr;
    String? passErr;

    if (!_isLogin && name.length < 2) {
      nameErr = 'Please enter your full name (at least 2 characters).';
    }

    if (email.isEmpty) {
      emailErr = 'Email address is required.';
    } else if (!_emailRegex.hasMatch(email)) {
      emailErr = 'Please enter a valid email address (e.g. name@gmail.com).';
    }

    if (password.isEmpty) {
      passErr = 'Password is required.';
    } else if (!_isLogin) {
      if (password.length < 8) {
        passErr = 'Password must be at least 8 characters long.';
      } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
        passErr = 'Password must include at least one uppercase letter.';
      } else if (!RegExp(r'[0-9]').hasMatch(password)) {
        passErr = 'Password must include at least one number.';
      }
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
    });

    return nameErr == null && emailErr == null && passErr == null;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_validateInputs()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      final result = await AuthService.instance.loginWithDetails(
        email: email,
        password: password,
      );
      if (!mounted) return;

      if (result.success) {
        ToastFeedback.showSuccess(context, result.message);
        _navigateOnAuthenticated();
      } else {
        setState(() => _passwordError = result.message);
        ToastFeedback.showError(context, result.message);
      }
    } else {
      final otpResult = await AuthService.instance.requestRegistrationOtp(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;

      if (otpResult.success) {
        setState(() {
          _isAwaitingOtp = true;
          _otpError = null;
          _otpController.clear();
        });
        _startResendCooldown();
        ToastFeedback.showInfo(context, otpResult.message);
      } else {
        ToastFeedback.showError(context, otpResult.message);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _otpError = 'Please enter the 6-digit verification code.');
      return;
    }

    setState(() => _otpError = null);
    final result = await AuthService.instance.verifyRegistrationOtp(
      email: _emailController.text.trim(),
      otp: otp,
    );
    if (!mounted) return;

    if (result.success) {
      ToastFeedback.showSuccess(context, result.message);
      _navigateOnAuthenticated();
    } else {
      setState(() => _otpError = result.message);
      ToastFeedback.showError(context, result.message);
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0 || AuthService.instance.isLoading) return;

    final otpResult = await AuthService.instance.requestRegistrationOtp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (otpResult.success) {
      setState(() {
        _otpError = null;
      });
      _startResendCooldown();
      ToastFeedback.showInfo(context, 'New 6-digit verification code sent!');
    } else {
      ToastFeedback.showError(context, otpResult.message);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    final result = await AuthService.instance.signInWithGoogle(isLogin: _isLogin);
    if (!mounted) return;

    if (result.success) {
      if (result.requiresOtpVerification) {
        setState(() {
          if (result.pendingEmail != null) {
            _emailController.text = result.pendingEmail!;
          }
          _isAwaitingOtp = true;
          _otpError = null;
          _otpController.clear();
        });
        _startResendCooldown();
        ToastFeedback.showInfo(context, result.message);
      } else {
        ToastFeedback.showSuccess(context, result.message);
        _navigateOnAuthenticated();
      }
    } else if (result.message != 'Google Sign-In was cancelled.') {
      ToastFeedback.showError(context, result.message);
    }
  }

  void _navigateOnAuthenticated() {
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final isLoading = AuthService.instance.isLoading;

        return Scaffold(
          backgroundColor: AppColors.bgCanvas,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _isAwaitingOtp
                      ? _buildOtpVerificationStep(isLoading)
                      : _buildMainAuthForm(isLoading),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpVerificationStep(bool isLoading) {
    final targetEmail = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        InkWell(
          onTap: isLoading
              ? null
              : () => setState(() {
                    _isAwaitingOtp = false;
                    _otpError = null;
                  }),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Back to account details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          ),
          child: const Center(
            child: Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 28),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Verify your email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit verification code sent to $targetEmail to activate your Recall account.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        _buildInputLabel('6-DIGIT VERIFICATION CODE'),
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.bgSurface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _otpError != null ? AppColors.danger : AppColors.primary,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_otpError != null) setState(() => _otpError = null);
            },
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 10,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '000000',
              hintStyle: TextStyle(
                fontSize: 22,
                letterSpacing: 10,
                color: AppColors.textMuted,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        if (_otpError != null) ...[
          const SizedBox(height: 6),
          Text(
            _otpError!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ],
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.bgCanvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.bgCanvas),
                    ),
                  )
                : const Text(
                    'Verify & Activate Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: (_resendCooldown > 0 || isLoading) ? null : _handleResendOtp,
            child: Text(
              _resendCooldown > 0
                  ? 'Resend code in ${_resendCooldown}s'
                  : 'Didn\'t receive the code? Resend',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _resendCooldown > 0 ? AppColors.textMuted : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainAuthForm(bool isLoading) {
    final passwordText = _passwordController.text;
    final hasMinLength = passwordText.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(passwordText);
    final hasNumber = RegExp(r'[0-9]').hasMatch(passwordText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Brand Masthead
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.bolt_rounded, color: AppColors.bgCanvas, size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Recall',
              style: TextStyle(
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
                  onTap: () => setState(() {
                    _isLogin = true;
                    _nameError = null;
                    _emailError = null;
                    _passwordError = null;
                  }),
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
                  onTap: () => setState(() {
                    _isLogin = false;
                    _nameError = null;
                    _emailError = null;
                    _passwordError = null;
                  }),
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
          _isLogin ? 'Welcome back' : 'Create your account',
          style: TextStyle(
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
              ? 'Sign in with your verified Recall credentials.'
              : 'Verify your email with a 6-digit code to start studying.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Continue with Google Button
        InkWell(
          onTap: isLoading ? null : _handleGoogleSignIn,
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
                Text(
                  'Continue with Google',
                  style: TextStyle(
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
            Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR WITH EMAIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.borderSubtle, thickness: 1)),
          ],
        ),
        const SizedBox(height: 18),

        // Form Fields
        if (!_isLogin) ...[
          _buildInputLabel('YOUR NAME'),
          _buildInputField(
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            hintText: 'Enter your full name',
            keyboardType: TextInputType.name,
            errorText: _nameError,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 16),
        ],

        _buildInputLabel('YOUR EMAIL'),
        _buildInputField(
          controller: _emailController,
          icon: Icons.mail_outline_rounded,
          hintText: 'you@gmail.com',
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: 16),

        _buildInputLabel('PASSWORD'),
        _buildInputField(
          controller: _passwordController,
          icon: Icons.lock_outline_rounded,
          hintText: _isLogin ? 'Enter your password' : 'Create a strong password',
          isPassword: true,
          errorText: _passwordError,
          onChanged: (_) {
            setState(() {
              if (_passwordError != null) _passwordError = null;
            });
          },
        ),

        // Password Strength Checklist on Create Account
        if (!_isLogin) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildPasswordRuleChip('8+ chars', hasMinLength),
              _buildPasswordRuleChip('1 Uppercase', hasUppercase),
              _buildPasswordRuleChip('1 Number', hasNumber),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Primary CTA Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.bgCanvas,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: isLoading
                ? SizedBox(
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
                      Flexible(
                        child: Text(
                          _isLogin ? 'Sign In to Recall' : 'Send 6-Digit Verification Code',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }

  Widget _buildPasswordRuleChip(String label, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isMet ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isMet ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
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
    String? errorText,
    ValueChanged<String>? onChanged,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: AppColors.bgSurface1,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: hasError ? AppColors.danger : AppColors.textSecondary,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    splashRadius: 18,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.borderSubtle,
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.borderSubtle,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ],
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

    final paintBlue = Paint()..color = AppColors.googleBlue;
    final paintGreen = Paint()..color = AppColors.googleGreen;
    final paintYellow = Paint()..color = AppColors.googleYellow;
    final paintRed = Paint()..color = AppColors.googleRed;

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.8,
      1.6,
      true,
      paintRed,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      1.5,
      true,
      paintYellow,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.3,
      1.6,
      true,
      paintGreen,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.9,
      1.5,
      true,
      paintBlue,
    );

    final innerPaint = Paint()..color = AppColors.bgSurface1;
    canvas.drawCircle(center, radius * 0.58, innerPaint);

    final barRect = Rect.fromLTRB(w * 0.45, h * 0.38, w, h * 0.62);
    canvas.drawRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
