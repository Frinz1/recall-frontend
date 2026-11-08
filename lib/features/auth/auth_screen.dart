import 'package:flutter/material.dart';
import '../../core/config/env_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/toast_feedback.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _nameController = TextEditingController(text: 'Alex Cruz');
  final _emailController = TextEditingController(text: 'student@recall.app');
  final _passwordController = TextEditingController(text: 'password123');
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

    if (!success && mounted) {
      ToastFeedback.showError(context, 'Authentication failed. Please verify credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Brand Logo
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGlow,
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recall', style: AppTypography.displayMedium),
                          Text('Study smarter, remember longer.', style: AppTypography.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Cloud API Connection Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_done_rounded, size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Connected to: ${EnvConfig.baseUrl}',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tab switcher (Sign In / Register)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildAuthTab('Sign In', _isLogin, () {
                            setState(() => _isLogin = true);
                          }),
                        ),
                        Expanded(
                          child: _buildAuthTab('Create Account', !_isLogin, () {
                            setState(() => _isLogin = false);
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fields
                  if (!_isLogin) ...[
                    _buildInputField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Alex Cruz',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildInputField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'student@recall.app',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _buildInputField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onTogglePassword: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  const SizedBox(height: 28),

                  AnimatedBuilder(
                    animation: AuthService.instance,
                    builder: (context, _) {
                      return AppButton(
                        label: _isLogin ? 'Sign In' : 'Create Free Account',
                        isExpanded: true,
                        isLoading: AuthService.instance.isLoading,
                        onPressed: _handleSubmit,
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Universal Cloud Access • Works from any device',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
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

  Widget _buildAuthTab(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword && obscureText,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            filled: true,
            fillColor: AppColors.bgSurface1,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
