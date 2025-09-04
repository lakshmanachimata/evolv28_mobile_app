import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_router_config.dart';
import '../../shared/widgets/splash_screen.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/onboarding_view.dart';
import '../../features/auth/presentation/views/devices_view.dart';
import '../../features/auth/presentation/views/dashboard_view.dart';

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
      // Devices Route
      GoRoute(
        path: AppRoutes.devices,
        name: AppRouteNames.devices,
        builder: (context, state) => const DevicesView(),
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
            // Custom evolv28 logo with smiley face in the 'o'
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'evolv',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Arial',
                    letterSpacing: 1.0,
                  ),
                ),
                // Custom 'o' with smiley face
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'o',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Arial',
                        letterSpacing: 1.0,
                      ),
                    ),
                    // Smiley face inside the 'o'
                    Positioned(
                      top: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left eye
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Right eye
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Smile
                    Positioned(
                      bottom: 8,
                      child: Container(
                        width: 16,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '28',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Arial',
                    letterSpacing: 1.0,
                  ),
                ),
              ],
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