import 'dart:async';
import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    _bootApp();
    AuthService.instance.addListener(_handleAuthChange);
  }

  Future<void> _bootApp() async {
    await Future.wait([
      AuthService.instance.initializeSession(),
      Future.delayed(const Duration(milliseconds: 1800)),
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
    AuthService.instance.removeListener(_handleAuthChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recall - Smart Flashcards & Learning Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= 520) {
              return child ?? const SizedBox.shrink();
            }

            const clampedWidth = 480.0;
            final mediaQuery = MediaQuery.of(context);
            return Container(
              color: const Color(0xFF090A0D),
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

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard_outlined),
              activeIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style_outlined),
              activeIcon: Icon(Icons.style_rounded),
              label: 'Decks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              activeIcon: Icon(Icons.insights_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
