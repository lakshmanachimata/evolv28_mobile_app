import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../../../../core/routing/app_router_config.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = SettingsViewModel();
        viewModel.initialize();
        return viewModel;
      },
      child: const _SettingsViewBody(),
    );
  }
}

class _SettingsViewBody extends StatelessWidget {
  const _SettingsViewBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background
              _buildBackground(),
              
              // Main content
              _buildMainContent(context, viewModel),
              
              // Language selection popup
              if (viewModel.showLanguagePopup)
                _buildLanguagePopup(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/images/login-background.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, SettingsViewModel viewModel) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context, viewModel),
          
          const SizedBox(height: 20),
          
          // Settings title
          _buildTitle(),
          
          const SizedBox(height: 24),
          
          // Settings content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Main settings card
                  _buildSettingsCard(context, viewModel),
                  
                  const SizedBox(height: 16),
                  
                  // Other section card
                  _buildOtherCard(context, viewModel),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation
          _buildBottomNavigation(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SettingsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          GestureDetector(
            onTap: viewModel.closeSettings,
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          // evolv28 logo
          Image.asset(
            'assets/images/evolv_text_white.png',
            width: MediaQuery.of(context).size.width * 0.25,
            fit: BoxFit.contain,
          ),
          
          // Settings icon
          SvgPicture.asset(
            'assets/images/profile_settings.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'SETTINGS',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSettingsItem(
              context,
              Icons.person_outline,
              'Profile',
              () => viewModel.navigateToProfile(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              Icons.info_outline,
              'About',
              () => viewModel.navigateToAbout(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              Icons.chat_bubble_outline,
              'FAQ',
              () => viewModel.navigateToFAQ(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              Icons.description_outlined,
              'Privacy & Legal Terms',
              () => viewModel.navigateToPrivacy(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              Icons.help_outline,
              'Help',
              () => viewModel.navigateToHelp(context),
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              Icons.download_outlined,
              'Bulk Download',
              viewModel.handleBulkDownload,
            ),
            _buildDivider(),
            _buildLanguageItem(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherCard(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Other',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              Icons.star_outline,
              'Rate Curie',
              viewModel.rateApp,
            ),
            _buildDivider(),
            _buildSettingsItem(
              context,
              Icons.share_outlined,
              'Share the App',
              viewModel.shareApp,
            ),
            const SizedBox(height: 20),
            // Logout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: viewModel.logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF07A60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, SettingsViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.showLanguageSelection,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.language_outlined,
              color: Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                viewModel.selectedLanguage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 1,
    );
  }

  Widget _buildLanguagePopup(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: 280,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Language',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildLanguageOption('English', viewModel),
                _buildLanguageOption('Hindi', viewModel),
                _buildLanguageOption('Arabic', viewModel),
                _buildLanguageOption('Spanish', viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, SettingsViewModel viewModel) {
    final isSelected = viewModel.selectedLanguage.contains(language);
    
    return GestureDetector(
      onTap: () => viewModel.selectLanguage('$language ($language)'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF07A60) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          language,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(
              'Home',
              'assets/images/bottom_menu_home_selected.svg',
              'assets/images/bottom_menu_home_selected.svg',
              0,
              context,
            ),
            _buildBottomNavItem(
              'Programs',
              'assets/images/bottom_menu_programs.svg',
              'assets/images/bottom_menu_programs_selected.svg',
              1,
              context,
            ),
            _buildBottomNavItem(
              'Device',
              'assets/images/bottom_menu_device.png',
              'assets/images/bottom_menu_device_selected.png',
              2,
              context,
              hasNotification: true,
            ),
            _buildBottomNavItem(
              'Profile',
              'assets/images/bottom_menu_user.svg',
              'assets/images/bottom_menu_user_selected.svg',
              3,
              context,
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
    BuildContext context, {
    bool hasNotification = false,
  }) {
    final isSelected = index == 0; // Home tab is selected

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
            context.go(AppRoutes.profile);
            break;
        }
      },
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
          ],
        ),
      ),
    );
  }
}
