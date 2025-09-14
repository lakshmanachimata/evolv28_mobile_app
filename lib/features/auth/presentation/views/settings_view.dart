import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/settings_viewmodel.dart';

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

              // Logout confirmation popup
              if (viewModel.showLogoutPopup)
                _buildLogoutPopup(context, viewModel),
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
        'assets/images/term-background.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, SettingsViewModel viewModel) {
    return Stack(
      children: [
        // evolv28 logo at top center
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: _buildTopLogo(context)),
        ),

        // Bottom sheet content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.86,
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/modal-background.png'),
                  fit: BoxFit.cover,
                  opacity: 0.9,
                ),
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Dark brown header bar
                  _buildDarkHeader(context, viewModel),

                  // Settings content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Main settings section
                          _buildMainSettingsSection(context, viewModel),

                          const SizedBox(height: 20),

                          // Other section header
                          _buildOtherSectionHeader(),

                          const SizedBox(height: 16),

                          // Other section
                          _buildOtherSection(context, viewModel),

                          const SizedBox(height: 20),

                          // Logout button
                          _buildLogoutButton(viewModel),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Center(
        child: Image.asset(
          'assets/images/evolv_text.png',
          width: MediaQuery.of(context).size.width * 0.25,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildDarkHeader(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Dark brown color
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => viewModel.closeSettings(context),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),

          // Settings title
          const Expanded(
            child: Center(
              child: Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Empty space to balance the close button
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildMainSettingsSection(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF6B7B8C,
        ).withOpacity(0.3), // Semi-transparent teal/grey
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            context,
            Icons.info_outline,
            'About',
            () => viewModel.navigateToAbout(context),
            isFirstItem: true,
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
            Icons.gavel,
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
            () => viewModel.handleBulkDownload(context),
          ),
          _buildDivider(),
          _buildLanguageItem(context, viewModel, isLastItem: true),
        ],
      ),
    );
  }

  Widget _buildOtherSectionHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Other',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOtherSection(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF6B7B8C,
        ).withOpacity(0.3), // Semi-transparent teal/grey
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            context,
            Icons.star_outline,
            'Rate Curie',
            viewModel.rateApp,
            isFirstItem: true,
          ),
          _buildDivider(),
          _buildSettingsItem(
            context,
            Icons.share_outlined,
            'Share the App',
            viewModel.shareApp,
            isLastItem: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(SettingsViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF07A60), // Coral/orange color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Log out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isFirstItem = false,
    bool isLastItem = false,
  }) {
    BorderRadius? borderRadius;

    if (isFirstItem && isLastItem) {
      // Both first and last item (single item)
      borderRadius = BorderRadius.circular(8);
    } else if (isFirstItem) {
      // First item only
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
      );
    } else if (isLastItem) {
      // Last item only
      borderRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF9FB6B9),
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
    BuildContext context,
    SettingsViewModel viewModel, {
    bool isLastItem = false,
  }) {
    BorderRadius? borderRadius;

    if (isLastItem) {
      borderRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    }

    return GestureDetector(
      onTap: viewModel.showLanguageSelection,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF9FB6B9),
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined, // Book with text icon
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                viewModel.selectedLanguage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      color: const Color(0xFF547D81),
    );
  }

  Widget _buildLanguagePopup(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: 280,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), // Light grey background
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => viewModel.hideLanguageSelection(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Language options
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    _buildLanguageOption('English', viewModel),
                    _buildLanguageOption('Hindi (हिंदी)', viewModel),
                    _buildLanguageOption('Spanish (español)', viewModel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, SettingsViewModel viewModel) {
    final isSelected = viewModel.selectedLanguage.contains(language);

    return GestureDetector(
      onTap: () => viewModel.selectLanguage(language),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF07A60) : const Color(0xFFE0E0E0), // Coral for selected, light grey for unselected
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            language,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutPopup(
    BuildContext context,
    SettingsViewModel viewModel,
  ) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => viewModel.hideLogoutConfirmation(),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF07A60),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Logging out?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Message
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Are you sure you want to logout from your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    // Cancel button
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => viewModel.hideLogoutConfirmation(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Continue button
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () => viewModel.confirmLogout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF07A60),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
