import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../viewmodels/device_connected_viewmodel.dart';
import '../../../../core/routing/app_router_config.dart';

class DeviceConnectedView extends StatelessWidget {
  const DeviceConnectedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = DeviceConnectedViewModel();
        viewModel.initialize();
        return viewModel;
      },
      child: const _DeviceConnectedViewBody(),
    );
  }
}

class _DeviceConnectedViewBody extends StatelessWidget {
  const _DeviceConnectedViewBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceConnectedViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background
              _buildBackground(),
              
              // Main content
              _buildMainContent(context, viewModel),
              
              // Update success dialog
              if (viewModel.showUpdateSuccessDialog)
                _buildUpdateSuccessDialog(context, viewModel),
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

  Widget _buildMainContent(BuildContext context, DeviceConnectedViewModel viewModel) {
    return SafeArea(
      child: Column(
        children: [
          // Main content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  
                  // Header with evolv28 logo
                  _buildHeader(context),
                  
                  const SizedBox(height: 40),
                  
                  // Device image
                  _buildDeviceImage(context),
                  
                  const SizedBox(height: 24),
                  
                  // Device information
                  _buildDeviceInfo(context, viewModel),
                  
                  const SizedBox(height: 32),
                  
                  // Version information (only show if update is available)
                  if (viewModel.updateAvailable)
                    _buildVersionInfo(context, viewModel),
                  
                  const SizedBox(height: 32),
                  
                  // Action button
                  _buildActionButton(context, viewModel),
                  
                  const SizedBox(height: 16),
                  
                  // Help text
                  _buildHelpText(context, viewModel),
                  
                  // Add extra space at bottom to ensure content doesn't get cut off
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation (dashboard style)
          _buildBottomNavigation(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Image.asset(
      'assets/images/evolv_text.png',
      width: MediaQuery.of(context).size.width * 0.25,
      fit: BoxFit.contain,
    );
  }

  Widget _buildDeviceImage(BuildContext context) {
    return Image.asset(
      'assets/images/evolv28_device.png',
      width: MediaQuery.of(context).size.width * 0.6,
      fit: BoxFit.contain,
    );
  }

  Widget _buildDeviceInfo(BuildContext context, DeviceConnectedViewModel viewModel) {
    return Column(
      children: [
        // Device name
        Text(
          viewModel.deviceName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Battery level
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.battery_std,
              color: viewModel.batteryLevel > 20 ? Colors.red : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${viewModel.batteryLevel}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Connection status
        Text(
          'Device Connected',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo(BuildContext context, DeviceConnectedViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Version:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                viewModel.currentVersion,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest Version:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                viewModel.latestVersion,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DeviceConnectedViewModel viewModel) {
    if (viewModel.isUpdating) {
      return Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF07A60),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Updating Firmware...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (viewModel.updateAvailable) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: viewModel.startFirmwareUpdate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF07A60),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Update Firmware',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: viewModel.checkForUpdates,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFF07A60),
          side: const BorderSide(color: Color(0xFFF07A60), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Check Update',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHelpText(BuildContext context, DeviceConnectedViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.handleHelp,
      child: Text(
        'Having troubles?',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
          decoration: TextDecoration.underline,
        ),
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(
              'Home',
              'assets/images/bottom_menu_home.svg',
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
    final isSelected = index == 2; // Device tab is selected

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
            // Already on device screen
            break;
          case 3: // Profile
            // TODO: Navigate to profile screen (implement when available)
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

  Widget _buildUpdateSuccessDialog(
    BuildContext context,
    DeviceConnectedViewModel viewModel,
  ) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: 300,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF07A60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 30),
                ),

                const SizedBox(height: 16),

                // Success Message
                const Text(
                  'The device is updated successfully',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.handleUpdateSuccessOk,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF07A60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
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
        ),
      ),
    );
  }
}
