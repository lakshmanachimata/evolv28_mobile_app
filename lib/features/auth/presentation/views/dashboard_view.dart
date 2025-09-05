import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardViewModel(),
      child: const _DashboardViewBody(),
    );
  }
}

class _DashboardViewBody extends StatefulWidget {
  const _DashboardViewBody();

  @override
  State<_DashboardViewBody> createState() => _DashboardViewBodyState();
}

class _DashboardViewBodyState extends State<_DashboardViewBody> {
  @override
  void initState() {
    super.initState();
    // Initialize the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          _buildBackground(),

          // Main Content
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/images/dashboard-background.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07A60)),
            ),
          );
        }

        return SafeArea(
          child: Column(
            children: [
              // Header with Logo
              _buildHeader(context, viewModel),

              // Main Content Area
              Expanded(child: _buildContentArea(context, viewModel)),

              // Bottom Navigation
              _buildBottomNavigation(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          // Logo
          Center(
            child: Image.asset(
              'assets/images/evolv_text.png',
              width: MediaQuery.of(context).size.width * 0.3,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 20),

          // Greeting
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Good Morning, \n${viewModel.userName}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, DashboardViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Get Started Button
          Center(
            child: GestureDetector(
              onTap: () {
                // Navigate to Get Started screen
                context.go(AppRoutes.getStarted);
              },
              child: SvgPicture.asset(
                'assets/images/get_started_circle.svg',
                width: 120,
                height: 120,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Top picks for you section
          _buildTopPicksSection(context),

          const SizedBox(height: 32),

          // Talk to an Expert section
          _buildTalkToExpertSection(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTopPicksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with flame icon
        Row(
          children: [
            const SizedBox(width: 8),
            Image.asset('assets/images/fire_items.png', width: 180, height: 36),
          ],
        ),

        const SizedBox(height: 20),

        // Feature icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildFeatureIcon(
              'Sleep\nBetter',
              'assets/images/sleep_better.svg',
            ),
            _buildFeatureIcon(
              'Focus\nBetter',
              'assets/images/focus_better.svg',
            ),
            _buildFeatureIcon(
              'Improve\nMood',
              'assets/images/improve_mood.svg',
            ),
            _buildFeatureIcon(
              'Reduce\nAnxiety',
              'assets/images/reduced_anxiety.png',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(String title, String iconPath) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFB74D), // Light orange border
              width: 2,
            ),
          ),
          child: Center(
            child: iconPath.contains('reduced_anxiety')
                ? Image.asset(iconPath, width: 40, height: 40)
                : SvgPicture.asset(iconPath, width: 40, height: 40),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTalkToExpertSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Talk to an Expert',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        // Expert card
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Light blue background
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            children: [
              // Illustration
              Expanded(
                flex: 2,
                child: Image.asset(
                  'assets/images/assesment_img.png',
                  width: 85,
                  height: 120,
                ),
              ),

              const SizedBox(width: 16),

              // Text content
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Express your feelings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Navigate difficult emotions, manage stressors, and establish Mindfulness.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Take Assessment button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          print('Take Assessment tapped');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Take Assessment',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(
              'Home',
              'assets/images/bottom_menu_home.svg',
              'assets/images/bottom_menu_home_selected.svg',
              0,
              viewModel,
            ),
            _buildBottomNavItem(
              'Programs',
              'assets/images/bottom_menu_programs.svg',
              'assets/images/bottom_menu_programs_selected.svg',
              1,
              viewModel,
            ),
            _buildBottomNavItem(
              'Device',
              'assets/images/bottom_menu_device.png',
              'assets/images/bottom_menu_device_selected.png',
              2,
              viewModel,
              hasNotification: true,
            ),
            _buildBottomNavItem(
              'Profile',
              'assets/images/bottom_menu_user.svg',
              'assets/images/bottom_menu_user_selected.svg',
              3,
              viewModel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    String label,
    String iconPath,
    String selectedIconPath,
    int index,
    DashboardViewModel viewModel, {
    bool hasNotification = false,
  }) {
    final isSelected = viewModel.selectedTabIndex == index;

    return GestureDetector(
      onTap: () => viewModel.onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                (iconPath.contains('bottom_menu_device') ||
                        selectedIconPath.contains('bottom_menu_device'))
                    ? Image.asset(
                        isSelected ? selectedIconPath : iconPath,
                        width: 50,
                        height: 50,
                      )
                    : SvgPicture.asset(
                        isSelected ? selectedIconPath : iconPath,
                        width: 30,
                        height: 30,
                      ),
              ],
            ),
            // const SizedBox(height: 4),
            // Text(
            //   label,
            //   style: TextStyle(
            //     fontSize: 10,
            //     fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            //     color: isSelected ? const Color(0xFFF07A60) : Colors.grey.shade600,
            //   ),
            // ),
            // if (isSelected)
            //   Container(
            //     margin: const EdgeInsets.only(top: 2),
            //     height: 2,
            //     width: 20,
            //     decoration: const BoxDecoration(
            //       color: Color(0xFFF07A60),
            //       borderRadius: BorderRadius.all(Radius.circular(1)),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
