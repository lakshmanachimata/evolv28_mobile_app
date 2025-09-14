import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = ProfileViewModel();
        viewModel.initialize();
        return viewModel;
      },
      child: const _ProfileViewBody(),
    );
  }
}

class _ProfileViewBody extends StatelessWidget {
  const _ProfileViewBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Main content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Header with evolv28 logo and settings icon
                        _buildHeader(context),

                        const SizedBox(height: 24),

                        // User profile section
                        _buildUserProfile(context, viewModel),

                        const SizedBox(height: 24),

                        // Action buttons
                        _buildActionButtons(context, viewModel),

                        const SizedBox(height: 24),

                        // Daily Mindfulness Goal section
                        _buildDailyGoalSection(context, viewModel),

                        const SizedBox(height: 24),

                        // Connect to Application section
                        _buildConnectToAppSection(context, viewModel),

                        const SizedBox(height: 24),

                        // Family section
                        _buildFamilySection(context, viewModel),

                        // Add extra space at bottom to ensure content doesn't get cut off
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation
                _buildBottomNavigation(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 40), // Spacer to center the logo
        // evolv28 logo image
        Image.asset(
          'assets/images/evolv_text.png',
          width: MediaQuery.of(context).size.width * 0.25,
          fit: BoxFit.contain,
        ),
        // Settings icon
        GestureDetector(
          onTap: () {
            context.go(AppRoutes.settings);
          },
          child: SvgPicture.asset(
            'assets/images/profile_settings.svg',
            width: 24,
            height: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfile(BuildContext context, ProfileViewModel viewModel) {
    return Row(
      children: [
        // User name
        Expanded(
          child: Text(
            viewModel.userName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        // Profile avatar
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF07A60), // Orange color
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              viewModel.userInitials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileViewModel viewModel) {
    return Column(
      children: [
        // Edit Profile button
        _buildActionButton(
          context,
          'Edit profile',
          'assets/images/profile_edit.svg',
          () => viewModel.editProfile(context),
        ),
        const SizedBox(height: 16),
        // Badges & Leaderboard button
        _buildActionButton(
          context,
          'Badges & Leaderboard',
          'assets/images/profile_edit.svg', // Using same icon for now
          viewModel.openBadgesLeaderboard,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    String iconPath,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF07A60), // Orange color
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalSection(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Mindfulness Goal',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFF07A60)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  viewModel.dailyGoal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: viewModel.editDailyGoal,
                  child: SvgPicture.asset(
                    'assets/images/profile_edit.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectToAppSection(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect to Application',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFF07A60)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Google Fit
                _buildAppConnectionItem(
                  'Google Fit',
                  'assets/images/google_fitness.svg',
                  viewModel.googleFitConnected,
                  viewModel.toggleGoogleFit,
                ),
                const SizedBox(height: 16),
                // Apple Health
                _buildAppConnectionItem(
                  'Apple Health',
                  'assets/images/apple_health.svg',
                  viewModel.appleHealthConnected,
                  viewModel.toggleAppleHealth,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppConnectionItem(
    String appName,
    String iconPath,
    bool isConnected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            isConnected ? 'CONNECTED' : 'CONNECT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isConnected ? const Color(0xFFF07A60) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection(BuildContext context, ProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Family',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            GestureDetector(
              onTap: viewModel.addFamilyMember,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF07A60)),
                ),
                child: const Text(
                  'Add Member',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF07A60),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Family image
        Image.asset(
          'assets/images/profile_family.png',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem('assets/images/bottom_menu_home.svg', 0, context),
            _buildNavItem('assets/images/bottom_menu_programs.svg', 1, context),
            _buildNavItem('assets/images/bottom_menu_device.png', 2, context),
            _buildNavItem('assets/images/bottom_menu_user_selected.svg', 3, context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String iconPath,
    int index,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // Handle navigation based on tab selection
        switch (index) {
          case 0: // Home
            context.go(AppRoutes.dashboard);
            break;
          case 1: // Programs
            context.go(AppRoutes.programs);
            break;
          case 2: // Device
            context.go(AppRoutes.deviceConnected);
            break;
          case 3: // Profile
            // Already on profile screen
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconPath.endsWith('.png')
              ? Image.asset(iconPath, width: 40, height: 40)
              : SvgPicture.asset(iconPath, width: 30, height: 30),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
