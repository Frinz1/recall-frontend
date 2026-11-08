import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/deck/deck_list_screen.dart';

import 'features/splash/splash_screen.dart';

class RecallApp extends StatelessWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recall - Smart Flashcards & Learning Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(nextScreen: MainNavigationShell()),
    );
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
      ),
      const DeckListScreen(),
      const AnalyticsScreen(),
      const DefenseGuideScreen(),
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
              icon: Icon(Icons.verified_outlined),
              activeIcon: Icon(Icons.verified_rounded),
              label: 'Defense Guide',
            ),
          ],
        ),
      ),
    );
  }
}

class DefenseGuideScreen extends StatelessWidget {
  const DefenseGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capstone Defense & Cloud Specs', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              AuthService.instance.logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Session Card
            if (user != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: AppTypography.titleMedium),
                          Text(user.email, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => AuthService.instance.logout(),
                      child: const Text('Sign Out', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Cloud Backend Architecture Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Cloud Architecture (recall-backend)',
                          style: AppTypography.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Recall uses a decoupled two-tier architecture: Node.js + Express + Prisma ORM + PostgreSQL cloud backend with Bearer JWT auth, keeping the SM-2 mathematical state synchronized across all client devices.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildBullet('REST API Prefix', '/api/v1 (Versioned endpoints)'),
                  _buildBullet('Central SM-2 Engine', 'Computed server-side upon every rating submission'),
                  _buildBullet('Universal Access', 'Access from home, school, or on mobile data'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SuperMemo SM-2 Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.psychology_rounded, color: AppColors.primaryLight),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'SuperMemo-2 (SM-2) Spaced Repetition',
                          style: AppTypography.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Recall implements the scientific SM-2 algorithm to overcome the Ebbinghaus Forgetting Curve:',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildBullet('Quality Rating (q)', '1 (Again), 3 (Hard), 4 (Good), 5 (Easy).'),
                  _buildBullet('Ease Factor (EF)', 'EF\' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)). Minimum 1.3.'),
                  _buildBullet('Review Interval (I)', 'I(1) = 1 day, I(2) = 6 days, I(n) = round(I(n-1) * EF).'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primaryLight, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodyMedium,
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
