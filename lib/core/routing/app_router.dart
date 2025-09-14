import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_router_config.dart';
import '../../shared/widgets/splash_screen.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/onboarding_view.dart';
import '../../features/auth/presentation/views/onboard_device_view.dart';
import '../../features/auth/presentation/views/devices_view.dart';
import '../../features/auth/presentation/views/device_connected_view.dart';
import '../../features/auth/presentation/views/dashboard_view.dart';
import '../../features/auth/presentation/views/get_started_view.dart';
import '../../features/auth/presentation/views/programs_view.dart';
import '../../features/auth/presentation/views/insights_view.dart';
import '../../features/auth/presentation/views/mindful_score_view.dart';
import '../../features/auth/presentation/views/goal_insights_view.dart';
import '../../features/auth/presentation/views/profile_view.dart';
import '../../features/auth/presentation/views/settings_view.dart';
import '../../features/auth/presentation/views/profile_edit_view.dart';
import '../../features/auth/presentation/views/about_view.dart';
import '../../features/auth/presentation/views/faq_webview.dart';
import '../../features/auth/presentation/views/privacy_webview.dart';
import '../../features/auth/presentation/views/help_view.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash Route
      GoRoute(
        path: AppRoutes.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      // Login Route
      GoRoute(
        path: AppRoutes.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginView(),
      ),
      // Onboarding Route
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRouteNames.onboarding,
        builder: (context, state) => const OnboardingView(),
      ),
      // Onboard Device Route
      GoRoute(
        path: AppRoutes.onboardDevice,
        name: AppRouteNames.onboardDevice,
        builder: (context, state) => const OnboardDeviceView(),
      ),
      // Devices Route
      GoRoute(
        path: AppRoutes.devices,
        name: AppRouteNames.devices,
        builder: (context, state) => const DevicesView(),
      ),
      // Device Connected Route
      GoRoute(
        path: AppRoutes.deviceConnected,
        name: AppRouteNames.deviceConnected,
        builder: (context, state) => const DeviceConnectedView(),
      ),
      // Home Route
      GoRoute(
        path: AppRoutes.home,
        name: AppRouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      // Dashboard Route
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRouteNames.dashboard,
        builder: (context, state) => const DashboardView(),
      ),
      // Get Started Route
      GoRoute(
        path: AppRoutes.getStarted,
        name: AppRouteNames.getStarted,
        builder: (context, state) => const GetStartedView(),
      ),
      // Programs Route
      GoRoute(
        path: AppRoutes.programs,
        name: AppRouteNames.programs,
        builder: (context, state) => const ProgramsView(),
      ),
      // Insights Route
      GoRoute(
        path: AppRoutes.insights,
        name: AppRouteNames.insights,
        builder: (context, state) => const InsightsView(),
      ),
      // MindFulScore Route
      GoRoute(
        path: AppRoutes.mindfulScore,
        name: AppRouteNames.mindfulScore,
        builder: (context, state) => const MindfulScoreView(),
      ),
      // GoalInsights Route
      GoRoute(
        path: AppRoutes.goalInsights,
        name: AppRouteNames.goalInsights,
        builder: (context, state) => const GoalInsightsView(),
      ),
      // Profile Route
      GoRoute(
        path: AppRoutes.profile,
        name: AppRouteNames.profile,
        builder: (context, state) => const ProfileView(),
      ),
      // Settings Route
      GoRoute(
        path: AppRoutes.settings,
        name: AppRouteNames.settings,
        builder: (context, state) => const SettingsView(),
      ),
      // Profile Edit Route
      GoRoute(
        path: AppRoutes.profileEdit,
        name: AppRouteNames.profileEdit,
        builder: (context, state) => const ProfileEditView(),
      ),
      // About Route
      GoRoute(
        path: AppRoutes.about,
        name: AppRouteNames.about,
        builder: (context, state) => const AboutView(),
      ),
      // FAQ Route
      GoRoute(
        path: AppRoutes.faq,
        name: AppRouteNames.faq,
        builder: (context, state) => const FAQWebView(),
      ),
      // Privacy Route
      GoRoute(
        path: AppRoutes.privacy,
        name: AppRouteNames.privacy,
        builder: (context, state) => const PrivacyWebView(),
      ),
      // Help Route
      GoRoute(
        path: AppRoutes.help,
        name: AppRouteNames.help,
        builder: (context, state) => const HelpView(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  static GoRouter get router => _router;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // evolv28 logo
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child: Image.asset(
                'assets/images/evolv_text.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Ready to build your app!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '404',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}