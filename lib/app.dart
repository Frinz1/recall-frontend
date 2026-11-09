import 'dart:async';
import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'core/services/study_repository.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/theme_service.dart';
import 'core/widgets/quick_create_sheet.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/deck/deck_list_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';

enum AppFlowState { splash, onboarding, auth, authenticated }

class RecallApp extends StatefulWidget {
  const RecallApp({super.key});

  @override
  State<RecallApp> createState() => _RecallAppState();
}

class _RecallAppState extends State<RecallApp> {
  AppFlowState _flow = AppFlowState.splash;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _bootApp();
    AuthService.instance.addListener(_handleAuthChange);
    ThemeService.instance.addListener(_handleThemeChange);
  }

  void _handleThemeChange() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _bootApp() async {
    final splashCompleter = Completer<void>();
    _splashTimer = Timer(const Duration(milliseconds: 6000), () {
      if (!splashCompleter.isCompleted) {
        splashCompleter.complete();
      }
    });

    await Future.wait([
      AuthService.instance.initializeSession(),
      ThemeService.instance.initializeTheme(),
      splashCompleter.future,
    ]);

    if (!mounted) return;
    setState(() {
      if (AuthService.instance.isAuthenticated) {
        _flow = AppFlowState.authenticated;
      } else if (AuthService.instance.hasSeenOnboarding) {
        _flow = AppFlowState.auth;
      } else {
        _flow = AppFlowState.onboarding;
      }
    });
  }

  void _handleAuthChange() {
    if (!mounted) return;
    if (_flow == AppFlowState.splash) return;
    setState(() {
      if (AuthService.instance.isAuthenticated) {
        _flow = AppFlowState.authenticated;
      } else {
        _flow = AppFlowState.auth;
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    AuthService.instance.removeListener(_handleAuthChange);
    ThemeService.instance.removeListener(_handleThemeChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recall - Smart Flashcards & Learning Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeService.instance.themeMode,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 520) {
              return child ?? const SizedBox.shrink();
            }

            const clampedWidth = 480.0;
            final mediaQuery = MediaQuery.of(context);
            return Container(
              color: AppColors.bgCanvas,
              alignment: Alignment.center,
              child: Container(
                width: clampedWidth,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(
                      color: AppColors.borderSubtle.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRect(
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      size: Size(clampedWidth, mediaQuery.size.height),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_flow) {
      case AppFlowState.splash:
        return const SplashScreen();
      case AppFlowState.onboarding:
        return OnboardingScreen(
          onComplete: () {
            AuthService.instance.markOnboardingCompleted();
            if (mounted) setState(() => _flow = AppFlowState.auth);
          },
        );
      case AppFlowState.auth:
        return AuthScreen(
          onSuccess: () {
            if (mounted) setState(() => _flow = AppFlowState.authenticated);
          },
        );
      case AppFlowState.authenticated:
        return const MainNavigationShell();
    }
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _midnightTimer;
  late DateTime _lastSeenDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastSeenDay = _today();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Fires a refresh just after local midnight so the daily goal, Due Today,
  /// and calendar strip roll over even if the app stays open.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      _lastSeenDay = _today();
      StudyRepository.instance.refreshForCurrentDay();
      _scheduleMidnightRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Timers do not run reliably while backgrounded, so re-check the date on resume.
    final today = _today();
    final dayChanged = today != _lastSeenDay;
    _lastSeenDay = today;
    StudyRepository.instance.refreshForCurrentDay();
    if (dayChanged) _scheduleMidnightRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        final screens = [
          DashboardScreen(
            onNavigateToDecks: () => setState(() => _currentIndex = 1),
            onNavigateToSettings: () => setState(() => _currentIndex = 3),
          ),
          const DeckListScreen(),
          const AnalyticsScreen(),
          const SettingsScreen(),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: _SculptedAnchoredDock(
            currentIndex: _currentIndex,
            onTabSelected: (index) => setState(() => _currentIndex = index),
            onCenterCreatePressed: () {
              QuickCreateSheet.show(
                context,
                initialTab: _currentIndex == 1 ? 0 : 0,
              );
            },
          ),
        );
      },
    );
  }
}

class _SculptedAnchoredDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterCreatePressed;

  const _SculptedAnchoredDock({
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterCreatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const dockBarHeight = 70.0;
    const archOverhang = 14.0;
    final totalHeight = dockBarHeight + archOverhang + bottomPadding;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Full-width Anchored Sculpted Surface with 28px curved top corners + center cradle arch
          Positioned.fill(
            child: CustomPaint(
              painter: _SculptedDockPainter(
                archOverhang: archOverhang,
                isDarkMode: AppColors.isDarkMode,
              ),
            ),
          ),

          // Navigation Tab Row anchored inside the dock
          Positioned(
            top: archOverhang,
            left: 8,
            right: 8,
            bottom: bottomPadding,
            child: Row(
              children: [
                Expanded(
                  child: _buildDockTabItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                ),
                Expanded(
                  child: _buildDockTabItem(
                    index: 1,
                    icon: Icons.style_rounded,
                    label: 'Decks',
                  ),
                ),
                const SizedBox(width: 76), // Space for Center Action Cradle
                Expanded(
                  child: _buildDockTabItem(
                    index: 2,
                    icon: Icons.insights_rounded,
                    label: 'Stats',
                  ),
                ),
                Expanded(
                  child: _buildDockTabItem(
                    index: 3,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                  ),
                ),
              ],
            ),
          ),

          // Center Raised 56x56 Action Cradle Button
          Positioned(
            top: 2,
            child: GestureDetector(
              onTap: onCenterCreatePressed,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.cradleStart, AppColors.cradleEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cradleStart.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppColors.cradleEnd.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: isSelected
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badge.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SculptedDockPainter extends CustomPainter {
  final double archOverhang;
  final bool isDarkMode;

  const _SculptedDockPainter({
    required this.archOverhang,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final topY = archOverhang;
    const cornerRadius = 28.0;
    final centerX = w / 2;
    const cradleHalfWidth = 44.0;

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, topY + cornerRadius)
      ..quadraticBezierTo(0, topY, cornerRadius, topY)
      ..lineTo(centerX - cradleHalfWidth, topY)
      // Smooth sculpted raised cradle arch in the center
      ..cubicTo(
        centerX - 26,
        topY,
        centerX - 24,
        0,
        centerX,
        0,
      )
      ..cubicTo(
        centerX + 24,
        0,
        centerX + 26,
        topY,
        centerX + cradleHalfWidth,
        topY,
      )
      ..lineTo(w - cornerRadius, topY)
      ..quadraticBezierTo(w, topY, w, topY + cornerRadius)
      ..lineTo(w, h)
      ..close();

    // Upward dock shadow (subtle in light mode, deep in midnight mode)
    final shadowPaint = Paint()
      ..color = isDarkMode
          ? Colors.black.withValues(alpha: 0.48)
          : Colors.black.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Main Dock Fill
    final fillPaint = Paint()
      ..color = AppColors.bgSurface1
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Top Border Glow along the sculpted silhouette
    final borderPath = Path()
      ..moveTo(0, topY + cornerRadius)
      ..quadraticBezierTo(0, topY, cornerRadius, topY)
      ..lineTo(centerX - cradleHalfWidth, topY)
      ..cubicTo(
        centerX - 26,
        topY,
        centerX - 24,
        0,
        centerX,
        0,
      )
      ..cubicTo(
        centerX + 24,
        0,
        centerX + 26,
        topY,
        centerX + cradleHalfWidth,
        topY,
      )
      ..lineTo(w - cornerRadius, topY)
      ..quadraticBezierTo(w, topY, w, topY + cornerRadius);

    final borderPaint = Paint()
      ..color = AppColors.borderSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SculptedDockPainter oldDelegate) =>
      oldDelegate.archOverhang != archOverhang ||
      oldDelegate.isDarkMode != isDarkMode;
}

