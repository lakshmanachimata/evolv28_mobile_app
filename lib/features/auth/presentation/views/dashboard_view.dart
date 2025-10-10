import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../../../../core/utils/bluetooth_permission_helper.dart';
import '../../../../core/utils/location_permission_helper.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/programs_viewmodel.dart';

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
  late TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    print('🎵 Dashboard View: initState() called');
    // Initialize the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🎵 Dashboard View: PostFrameCallback executing...');
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      print('🎵 Dashboard View: Calling viewModel.initialize()...');
      await viewModel.initialize();
      print('🎵 Dashboard View: viewModel.initialize() completed');

      // Start permission flow in sequence: Location -> Bluetooth -> Scan
      await _startPermissionFlow(context);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// Start permission flow in the exact sequence requested:
  /// 1. Check if Bluetooth is enabled first
  /// 2. If Bluetooth is disabled, show popup and wait for user acknowledgment
  /// 3. Only start permission flow after Bluetooth is enabled
  /// 4. Skip permission flow if both permissions are already granted
  Future<void> _startPermissionFlow(BuildContext context) async {
    print(
      '🎵 Dashboard View: Checking Bluetooth state before starting permission flow...',
    );

    // Check if permission flow is already in progress
    final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
    if (viewModel.permissionFlowInProgress) {
      print(
        '🎵 Dashboard View: Permission flow already in progress, skipping...',
      );
      return;
    }

    // Check if Bluetooth is enabled first
    final isBluetoothEnabled = await _checkBluetoothEnabled();

    if (!isBluetoothEnabled) {
      print(
        '🎵 Dashboard View: Bluetooth is disabled - permission flow will be triggered after user enables Bluetooth',
      );
      return; // Don't start permission flow, wait for Bluetooth to be enabled
    }

    // Check if both permissions are already granted
    final hasLocationPermission =
        await LocationPermissionHelper.isLocationPermissionGranted();
    final hasBluetoothPermission =
        await BluetoothPermissionHelper.isBluetoothEnabled();

    print('🎵 Dashboard View: Permission status - Location: $hasLocationPermission, Bluetooth: $hasBluetoothPermission');

    if (hasLocationPermission && hasBluetoothPermission) {
      print(
        '🎵 Dashboard View: Both permissions already granted, skipping permission flow and starting device scanning...',
      );
      await viewModel.startAutomaticDeviceScanning();
      return;
    }

    print(
      '🎵 Dashboard View: Bluetooth is enabled but permissions missing - starting permission flow sequence...',
    );
    await _executePermissionFlow(context);
  }

  /// Execute the actual permission flow sequence
  /// Always shows all 4 dialogs in sequence:
  /// 1. Location permission app dialog
  /// 2. Location permission system dialog
  /// 3. Bluetooth permission app dialog
  /// 4. Bluetooth permission system dialog
  Future<void> _executePermissionFlow(BuildContext context) async {
    print('🎵 Dashboard View: Starting full permission flow sequence...');

    final viewModel = Provider.of<DashboardViewModel>(context, listen: false);

    // Check if permission flow is already in progress
    if (viewModel.permissionFlowInProgress) {
      print('🎵 Dashboard View: Permission flow already in progress, skipping...');
      return;
    }

    // Set permission flow in progress flag
    viewModel.setPermissionFlowInProgress(true);

    try {
      // Step 1 & 2: Location permission (app dialog -> system dialog)
      print('🎵 Dashboard View: Step 1-2: Requesting location permission...');
      final locationGranted =
          await LocationPermissionHelper.checkAndRequestLocationPermission(
            context,
          );

      if (!locationGranted) {
        print('🎵 Dashboard View: Location permission denied, stopping flow');
        return;
      }

      print(
        '🎵 Dashboard View: Location permission granted, proceeding to Bluetooth...',
      );

      // Step 3 & 4: Bluetooth permission (app dialog -> system dialog)
      print('🎵 Dashboard View: Step 3-4: Requesting Bluetooth permission...');
      final bluetoothGranted =
          await BluetoothPermissionHelper.checkAndRequestBluetoothPermission(
            context,
          );

      if (!bluetoothGranted) {
        print('🎵 Dashboard View: Bluetooth permission denied, stopping flow');
        return;
      }

      print(
        '🎵 Dashboard View: Both permissions granted, starting device scanning...',
      );

      // Step 5: Both permissions granted, start scanning
      await viewModel.startAutomaticDeviceScanning();
    } finally {
      // Clear permission flow in progress flag
      viewModel.setPermissionFlowInProgress(false);
    }
  }

  // Check if Bluetooth is enabled
  Future<bool> _checkBluetoothEnabled() async {
    try {
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      print('🎵 Dashboard View: Error checking Bluetooth state: $e');
      return false;
    }
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

          // Permission Flow Trigger Listener
          Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.shouldTriggerPermissionFlow &&
                  !viewModel.permissionFlowInProgress &&
                  !viewModel.permissionFlowCompleted) {
                // Clear the flag and trigger permission flow
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  // Double-check the state before executing
                  if (viewModel.shouldTriggerPermissionFlow && 
                      !viewModel.permissionFlowInProgress &&
                      !viewModel.permissionFlowCompleted) {
                    viewModel.clearPermissionFlowTrigger();
                    await _executePermissionFlow(context);
                  }
                });
              }
              return SizedBox.shrink();
            },
          ),

          // Loading Overlay
          Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              print(
                'DEBUG: isExecutingCommands: ${viewModel.isExecutingCommands}, isSendingPlayCommands: ${viewModel.isSendingPlayCommands}',
              );
              if (viewModel.isExecutingCommands ||
                  viewModel.isSendingPlayCommands) {
                return _buildLoadingOverlay(context);
              }
              return SizedBox.shrink();
            },
          ),

          // Scanning Overlay
          Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isBluetoothScanning) {
                return _buildScanningOverlay(context, viewModel);
              }
              return SizedBox.shrink();
            },
          ),

          // Permission Dialogs
          Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              // Show Bluetooth scan permission as bottom sheet
              if (viewModel.showBluetoothScanPermissionDialog) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Double-check the state before showing the bottom sheet
                  if (viewModel.showBluetoothScanPermissionDialog) {
                    showModalBottomSheet<bool>(
                      context: context,
                      isDismissible: false,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildBluetoothScanPermissionDialog(
                        context,
                        viewModel,
                      ),
                    ).then((_) {
                      // Ensure state is reset when bottom sheet is dismissed
                      if (viewModel.showBluetoothScanPermissionDialog) {
                        viewModel.denyBluetoothScanPermission();
                      }
                    });
                  }
                });
              }

              // Show unknown device list as bottom sheet
              if (viewModel.showUnknownDeviceDialog &&
                  !viewModel.unknownDeviceBottomSheetShown) {
                print('🎵 Dashboard UI: Showing unknown device bottom sheet');
                // Mark that the bottom sheet is being shown immediately
                viewModel.setUnknownDeviceBottomSheetShown(true);
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Double-check the state before showing the bottom sheet
                  if (viewModel.showUnknownDeviceDialog) {
                    print(
                      '🎵 Dashboard UI: Confirmed showing unknown device bottom sheet',
                    );
                    showModalBottomSheet<bool>(
                      context: context,
                      isDismissible: true, // Allow dismissal for error cases
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          _buildUnknownDeviceBottomSheet(context, viewModel),
                    ).then((_) {
                      // Handle bottom sheet dismissal
                      viewModel.setUnknownDeviceBottomSheetShown(false);
                    });
                  }
                });
              }

              // Show OTP confirmation as bottom sheet
              if (viewModel.showOtpConfirmationDialog &&
                  !viewModel.otpBottomSheetShown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Double-check the state before showing the bottom sheet
                  if (viewModel.showOtpConfirmationDialog &&
                      !viewModel.otpBottomSheetShown) {
                    showModalBottomSheet<bool>(
                      context: context,
                      isDismissible: false,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) =>
                          _buildOtpConfirmationBottomSheet(context, viewModel),
                    );
                    // Mark that the OTP bottom sheet has been shown
                    viewModel.setOtpBottomSheetShown(true);
                  }
                });
              }

              // Handle pending device mapping error
              if (viewModel.pendingDeviceMappingError != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Only pop if there's a modal to dismiss and we can pop
                  if (viewModel.showUnknownDeviceDialog && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  viewModel.closeUnknownDeviceDialog();
                  viewModel.showDeviceMappingErrorWithContext(
                    viewModel.pendingDeviceMappingError!,
                    context,
                  );
                  viewModel.clearPendingDeviceMappingError();
                });
              }

              return Stack(
                children: [
                  if (viewModel.showBluetoothEnableDialog)
                    _buildBluetoothEnableDialog(context, viewModel),

                  if (viewModel.showBluetoothPermissionErrorDialog)
                    _buildBluetoothPermissionErrorDialog(context, viewModel),

                  if (viewModel.showDeviceMappingErrorDialog)
                    _buildDeviceMappingErrorDialog(context, viewModel),
                ],
              );
            },
          ),
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

              // Player Card (after successful play response or for non-Bluetooth programs)
              Consumer<DashboardViewModel>(
                builder: (context, viewModel, child) {
                  print(
                    'DEBUG: showPlayerCard: ${viewModel.showPlayerCard}, isPlaySuccessful: ${viewModel.isPlaySuccessful}',
                  );
                  // Show player card if:
                  // 1. Bluetooth play was successful (isPlaySuccessful = true)
                  // 2. Non-Bluetooth program is playing (showPlayerCard = true)
                  final shouldShowPlayerCard =
                      viewModel.isPlaySuccessful || viewModel.showPlayerCard;
                  print('DEBUG: shouldShowPlayerCard: $shouldShowPlayerCard');
                  if (shouldShowPlayerCard) {
                    print('DEBUG: Building player card');
                    return _buildPlayerCard(context, viewModel);
                  }
                  print('DEBUG: Hiding player card');
                  return SizedBox.shrink();
                },
              ),

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
          // Logo and Notification Bell
          SizedBox(height: 30),
          Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/evolv_text.png',
                  width: MediaQuery.of(context).size.width * 0.25,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 0,
                right: 12,
                child: SvgPicture.asset(
                  'assets/images/noti_icon.svg',
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Greeting
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Good Morning, ${viewModel.userName}',
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
          // Connect Card
          _buildConnectCard(context, viewModel),

          const SizedBox(height: 16),

          // Wellness Programs Card
          _buildWellnessProgramsCard(context),

          const SizedBox(height: 16),

          // Insights Card
          _buildInsightsCard(context),

          const SizedBox(height: 20),

          // Top picks for you section
          _buildTopPicksSection(context),

          const SizedBox(height: 20),

          // Wellness Check Card
          _buildWellnessCheckCard(context),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildConnectCard(BuildContext context, DashboardViewModel viewModel) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        // Determine connection state
        String title;
        String subtitle;
        Color iconColor;
        IconData iconData;

        if (viewModel.connectionSuccessful) {
          title = 'Connected';
          subtitle = 'Your Evolv28 device is connected';
          iconColor = Colors.green;
          iconData = Icons.bluetooth_connected;
        } else if (viewModel.isConnecting) {
          title = 'Connecting';
          subtitle = 'Connecting to your device...';
          iconColor = Colors.orange;
          iconData = Icons.bluetooth_searching;
        } else if (viewModel.isBluetoothConnected) {
          title = 'Connected';
          subtitle = viewModel.bluetoothStatusMessage;
          iconColor = Colors.blue;
          iconData = Icons.bluetooth_connected;
        } else {
          title = 'Connect';
          subtitle = 'Tap to connect your Evolv28 device';
          iconColor = Colors.grey;
          iconData = Icons.bluetooth;
        }

        return GestureDetector(
          onTap: viewModel.connectionSuccessful
              ? null
              : () {
                  viewModel.connectBluetoothDevice();
                },
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (viewModel.bluetoothErrorMessage.isNotEmpty &&
                          !viewModel.connectionSuccessful) ...[
                        const SizedBox(height: 4),
                        Text(
                          viewModel.bluetoothErrorMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(iconData, color: iconColor, size: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBluetoothIcon(DashboardViewModel viewModel) {
    if (viewModel.bluetoothService.isScanning) {
      return _BlinkingBluetoothIcon();
    } else {
      return Icon(
        viewModel.isBluetoothConnected
            ? Icons.bluetooth_connected
            : Icons.bluetooth,
        color: viewModel.isBluetoothConnected ? Colors.blue : Colors.grey,
        size: 30,
      );
    }
  }

  Widget _buildWellnessProgramsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(AppRoutes.programs);
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wellness Programs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a session that suits your mind today.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/images/dashboard_lotus.svg',
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(AppRoutes.insights);
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track how often you\'ve used Evolv28',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/images/dashboard_insights.svg',
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessCheckCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8), // Light teal background
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wellness Check',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take a quick check-in to know where you stand',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    context.go(AppRoutes.wellnessCheck);
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
              ],
            ),
          ),
          SvgPicture.asset(
            'assets/images/dashboard_assesment.svg',
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPicksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Top picks for you',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal scrollable feature icons
        SizedBox(
          height: 100,
          child: Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              // Get filtered programs (union of music data and Bluetooth programs)
              final filteredPrograms = viewModel.filteredPrograms;

              // Extract program names and IDs from filtered programs
              final programNames = <String>[];
              final programIds = <String>[];

              for (final program in filteredPrograms) {
                if (program is Map<String, dynamic>) {
                  final programName =
                      program['bluetoothProgramName'] ??
                      program['name'] ??
                      program['title'] ??
                      'Unknown Program';
                  final programId =
                      program['bluetoothProgramId'] ??
                      program['id']?.toString() ??
                      '';

                  programNames.add(programName);
                  programIds.add(programId);
                }
              }

              // Use filtered programs if available, otherwise use default
              final topPicks = programNames.isNotEmpty
                  ? programNames.take(4).toList()
                  : [
                      'Sleep Better',
                      'Improve Mood',
                      'Focus Better',
                      'Remove Stress',
                    ];

              return ListView(
                scrollDirection: Axis.horizontal,
                children: topPicks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final programName = entry.value;
                  final programId = programIds.length > index
                      ? programIds[index]
                      : '';

                  return Row(
                    children: [
                      _buildFeatureIcon(
                        programName,
                        _getIconPathForProgram(programName),
                        viewModel,
                        programId: programId,
                      ),
                      if (index < topPicks.length - 1)
                        const SizedBox(width: 16),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(
    String title,
    String iconPath,
    DashboardViewModel viewModel, {
    String? programId,
  }) {
    return GestureDetector(
      onTap: () {
        // If Bluetooth is connected, play via Bluetooth, otherwise show popup
        if (viewModel.isBluetoothConnected) {
          viewModel.playBluetoothProgram(title);
        } else {
          _showConnectDevicePopup(context);
        }
      },
      child: Column(
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
              child: iconPath.endsWith('.svg')
                  ? SvgPicture.asset(iconPath, width: 30, height: 30)
                  : Image.asset(iconPath, width: 30, height: 30),
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
      ),
    );
  }

  String _getIconPathForProgram(String programName) {
    switch (programName) {
      case 'Sleep Better':
        return 'assets/images/sleep_better.svg';
      case 'Improve Mood':
        return 'assets/images/improve_mood.svg';
      case 'Focus Better':
        return 'assets/images/focus_better.svg';
      case 'Remove Stress':
        return 'assets/images/remove_stress.svg';
      case 'Calm Mind':
        return 'assets/images/calm_mind.svg';
      default:
        return 'assets/images/sleep_better.svg';
    }
  }

  Widget _buildProgramIcon(String? programId) {
    String iconPath;

    switch (programId) {
      case 'sleep_better':
        iconPath = 'assets/images/sleep_icon.svg';
        break;
      case 'improve_mood':
        iconPath = 'assets/images/improve_mood.svg';
        break;
      case 'focus_better':
        iconPath = 'assets/images/focus_better.svg';
        break;
      case 'remove_stress':
        iconPath = 'assets/images/remove_stress.svg';
        break;
      default:
        iconPath = 'assets/images/sleep_icon.svg';
    }

    return SvgPicture.asset(iconPath, width: 50, height: 50);
  }

  Widget _buildProgramIconForBluetooth(String bcuFileName) {
    // Convert bcu filename to program name and get icon
    final programName = bcuFileName.replaceAll('.bcu', '').replaceAll('_', ' ');
    final iconPath = _getIconPathForProgram(programName);

    return SvgPicture.asset(iconPath, width: 50, height: 50);
  }

  String _formatProgramName(String bcuFileName) {
    // Convert bcu filename to readable program name
    return bcuFileName
        .replaceAll('.bcu', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : word,
        )
        .join(' ');
  }

  String _getProgramTitle(String? programId) {
    switch (programId) {
      case 'sleep_better':
        return 'Better Sleep';
      case 'improve_mood':
        return 'Improve Mood';
      case 'focus_better':
        return 'Improve Focus';
      case 'remove_stress':
        return 'Reduce Stress';
      default:
        return 'Better Sleep';
    }
  }

  Widget _buildPlayerCard(BuildContext context, DashboardViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        // Navigate to programs view and show player screen
        // Pass the current playing program ID
        if (viewModel.currentPlayingProgramId != null) {
          ProgramsViewModel.setProgramIdFromDashboard(
            viewModel.currentPlayingProgramId!,
          );
        }
        context.go(AppRoutes.programs);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF17961), // Reddish-orange background
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Program Icon
            viewModel.isSendingPlayCommands
                ? _buildProgramIconForBluetooth(viewModel.selectedBcuFile)
                : viewModel.selectedBcuFile != null &&
                      viewModel.selectedBcuFile.isNotEmpty
                ? _buildProgramIconForBluetooth(viewModel.selectedBcuFile)
                : _buildProgramIcon(viewModel.currentPlayingProgramId),
            const SizedBox(width: 16),

            // Now Playing Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Now playing',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    viewModel.isPlaySuccessful
                        ? _formatProgramName(viewModel.selectedBcuFile)
                        : viewModel.isSendingPlayCommands
                        ? _formatProgramName(viewModel.selectedBcuFile)
                        : viewModel.selectedBcuFile != null &&
                              viewModel.selectedBcuFile.isNotEmpty
                        ? _formatProgramName(viewModel.selectedBcuFile)
                        : _getProgramTitle(viewModel.currentPlayingProgramId),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Play/Pause Button
            GestureDetector(
              onTap: () => viewModel.stopBluetoothProgram(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/stop_play.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ],
        ),
      ),
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
            _buildNavItem(
              'assets/images/bottom_menu_home_selected.svg',
              0,
              viewModel,
            ),
            _buildNavItem(
              'assets/images/bottom_menu_programs.svg',
              1,
              viewModel,
            ),
            _buildNavItem('assets/images/bottom_menu_device.png', 2, viewModel),
            _buildNavItem('assets/images/bottom_menu_user.svg', 3, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String iconPath,
    int index,
    DashboardViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedTabIndex == index;

    return GestureDetector(
      onTap: () => viewModel.onTabSelected(index, context),
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

  Widget _buildLoadingOverlay(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        String title;
        String subtitle;

        if (viewModel.isExecutingCommands) {
          title = 'Fetching Programs...';
          subtitle = 'Please wait while we retrieve your wellness programs';
        } else if (viewModel.isSendingPlayCommands) {
          // Show the actual program name being played
          final programName = viewModel.selectedBcuFile != null
              ? _formatProgramName(viewModel.selectedBcuFile!)
              : 'Program';
          title = 'Playing $programName';
          subtitle = 'Starting your wellness program';
        } else {
          title = 'Loading...';
          subtitle = 'Please wait';
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
          child: Center(
            child: Container(
              width:
                  MediaQuery.of(context).size.width *
                  0.8, // 80% of screen width
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Loading indicator
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4CAF50), // Green color
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Loading text
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanningOverlay(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(
        0.3,
      ), // Completely transparent to show all background content
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bluetooth scanning icon with animation
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing circle
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                    // Inner Bluetooth icon
                    Icon(
                      Icons.bluetooth_searching,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Scanning text
              Text(
                'Scanning for evolv28 devices',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              // Countdown text
              Text(
                viewModel.bluetoothScanCountdown > 0
                    ? '${viewModel.bluetoothScanCountdown} seconds remaining'
                    : 'Searching for devices...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Permission Dialog Methods
  Widget _buildBluetoothEnableDialog(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.5),
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
                Text(
                  'Enable Bluetooth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getBluetoothEnableMessage(),
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.handleBluetoothEnableOk,
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

  Widget _buildBluetoothScanPermissionDialog(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      viewModel.denyBluetoothScanPermission();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.red[600],
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Title
              const Text(
                'Allow Bluetooth',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Content
              const Text(
                'Please allow bluetooth for establishing the connection with Evolv28',
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.left,
              ),

              const SizedBox(height: 32),

              // Allow button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.allowBluetoothScanPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF17961),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothPermissionErrorDialog(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.5),
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
                Text(
                  'Bluetooth Permission Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bluetooth permission is required for device scanning. Please enable it in your device settings.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: viewModel.handleBluetoothPermissionErrorOk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: viewModel.openDeviceSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF07A60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getBluetoothEnableMessage() {
    if (Platform.isAndroid) {
      return 'Please enable Bluetooth in your device settings to connect with Evolv28. Tap OK to open Bluetooth settings.';
    } else if (Platform.isIOS) {
      return 'Please enable Bluetooth in Settings > Bluetooth to connect with Evolv28. Tap OK to open Settings.';
    } else {
      return 'Please enable Bluetooth on your device to connect with Evolv28';
    }
  }

  Widget _buildUnknownDeviceBottomSheet(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    final unknownDevices = viewModel.unknownDevices;
    if (unknownDevices.isEmpty) {
      return _buildNoDeviceFoundBottomSheet(context, viewModel);
    }

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        viewModel.closeUnknownDeviceDialog();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 24),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Title - Dynamic based on connection state
                        Text(
                          viewModel.connectionSuccessful
                              ? 'Welcome ${viewModel.userName}'
                              : 'Welcome ${viewModel.userName}\nselect your device',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Device Image
                        Container(
                          width: 120,
                          height: 120,
                          child: Center(
                            child: Image.asset(
                              'assets/images/evolv28_device.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Connection status or device list
                        if (viewModel.connectionSuccessful) ...[
                          // Success state
                          Text(
                            'Connected to ${unknownDevices.first['name']} successfully',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ] else ...[
                          // Device selection state
                          const Text(
                            'Nearby Devices',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Device list with checkboxes
                          Column(
                            children: unknownDevices
                                .map(
                                  (device) => _buildDeviceCheckboxItem(
                                    context,
                                    viewModel,
                                    device,
                                    setModalState,
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 20),

                          // Connect button - only show if devices are selected
                          if (viewModel.hasSelectedDevices) ...[
                            SizedBox(
                              width: 120,
                              child: ElevatedButton(
                                onPressed: viewModel.isConnecting
                                    ? null
                                    : () async {
                                        await viewModel
                                            .connectToSelectedDevices();
                                        setModalState(() {});
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFFF17961,
                                  ), // Orange-red
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  viewModel.isConnecting
                                      ? 'Connecting...'
                                      : 'Connect',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoDeviceFoundBottomSheet(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: viewModel.showTroubleshootingScreen
                ? MediaQuery.of(context).size.height * 0.8
                : MediaQuery.of(context).size.height * 0.4,
            minHeight: viewModel.showTroubleshootingScreen
                ? MediaQuery.of(context).size.height * 0.6
                : MediaQuery.of(context).size.height * 0.3,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: viewModel.showTroubleshootingScreen
                        ? _buildTroubleshootingContent(
                            context,
                            viewModel,
                            setModalState,
                          )
                        : _buildNoDeviceFoundContent(
                            context,
                            viewModel,
                            setModalState,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoDeviceFoundContent(
    BuildContext context,
    DashboardViewModel viewModel,
    StateSetter setModalState,
  ) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Close button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                viewModel.closeUnknownDeviceDialog();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red[600],
                  size: 20,
                ),
              ),
            ),
          ],
        ),

        // Main content
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
        // "Can't find your Device" message with info icon - clickable
        GestureDetector(
          onTap: () {
            viewModel.openTroubleshootingScreen();
            setModalState(() {});
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Can't find your Device",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                    fontWeight: FontWeight.w900,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Try Again button
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: () {
              // Close the bottom sheet first
              Navigator.of(context).pop();
              viewModel.closeUnknownDeviceDialog();
              // Then trigger device scan again
              viewModel.connectBluetoothDevice();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF17961), // Orange-red
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootingContent(
    BuildContext context,
    DashboardViewModel viewModel,
    StateSetter setModalState,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Title
          const Text(
            "Can't find your device?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Troubleshooting instructions
          const Text(
            "Make sure the Bluetooth is turned on your mobile phone.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),

          const SizedBox(height: 16),

          const Text(
            "Make sure the Bluetooth is turned on the evolv28 device.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),

          const SizedBox(height: 16),

          const Text(
            "Make sure your mobile phone and the evolv28 device are in each other's range.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),

          const SizedBox(height: 16),

          const Text(
            "Click on the learn more button to see how to turn on the Bluetooth of the evolv28-device.",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),

          const SizedBox(height: 40),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Back button (orange-red background)
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    viewModel.closeTroubleshootingScreen();
                    setModalState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF17961), // Orange-red
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDeviceCheckboxItem(
    BuildContext context,
    DashboardViewModel viewModel,
    Map<String, dynamic> device,
    StateSetter setModalState,
  ) {
    final deviceId = device['id'] ?? device['name'] ?? '';
    final isSelected = viewModel.isDeviceSelected(deviceId);

    return GestureDetector(
      onTap: () {
        viewModel.toggleDeviceSelection(deviceId);
        setModalState(() {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[300]! : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange[600] : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.orange[600]! : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),

            // Device name
            Expanded(
              child: Text(
                device['name'] ?? 'Unknown Device',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.orange[800] : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknownDeviceItem(
    BuildContext context,
    DashboardViewModel viewModel,
    Map<String, dynamic> device,
  ) {
    return GestureDetector(
      onTap: () {
        viewModel.selectUnknownDevice(device);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Device icon
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF2C2C2C),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/user_neck_device.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Device info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name'] ?? 'Unknown Device',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${device['id']}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${device['signalStrength']}%',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpConfirmationBottomSheet(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    final selectedDevice = viewModel.selectedUnknownDevice;
    if (selectedDevice == null) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          minHeight: 500.0,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Dismiss keyboard first
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pop();
                          viewModel.closeOtpConfirmationDialog();
                          // Don't dismiss the unknown device bottom sheet - let it remain visible
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.red[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Device info header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2C),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/user_neck_device.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Device',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              selectedDevice['name'] ?? 'Unknown Device',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Description
                  const Text(
                    'Enter the OTP code to add this device to your account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // OTP Input Field
                  TextFormField(
                    controller: _otpController,
                    onChanged: (value) {
                      // Convert alphabetic characters to uppercase
                      final upperValue = value.toUpperCase();

                      // Limit to 10 alphanumeric characters
                      if (upperValue.length <= 10 &&
                          RegExp(r'^[A-Z0-9]*$').hasMatch(upperValue)) {
                        // Update the controller with uppercase value
                        _otpController.value = _otpController.value.copyWith(
                          text: upperValue,
                          selection: TextSelection.collapsed(
                            offset: upperValue.length,
                          ),
                        );
                        viewModel.updateOtpCode(upperValue);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter OTP (up to 10 characters)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFF17961),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Colors.black,
                    ),
                    maxLength: 10,
                    autofocus: true,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) {
                          return Text(
                            '$currentLength/$maxLength',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                  ),

                  const SizedBox(height: 24),

                  // Error/Success message
                  if (viewModel.otpVerificationMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            viewModel.otpVerificationMessage!.contains(
                              'success',
                            )
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              viewModel.otpVerificationMessage!.contains(
                                'success',
                              )
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                        ),
                      ),
                      child: Text(
                        viewModel.otpVerificationMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              viewModel.otpVerificationMessage!.contains(
                                'success',
                              )
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: !viewModel.isVerifyingOtp
                          ? () async {
                              // Dismiss keyboard first
                              if (viewModel.otpVerificationMessage != null &&
                                  viewModel.otpVerificationMessage!.contains(
                                    'success',
                                  )) {
                                return;
                              }
                              FocusScope.of(context).unfocus();
                              bool isGood = await viewModel
                                  .verifyOtpAndAddDevice();
                              if (isGood) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF17961),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: viewModel.isVerifyingOtp
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Verifying...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Verify & Add Device',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // Dismiss keyboard first
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                        viewModel.closeOtpConfirmationDialog();
                        // Don't dismiss the unknown device bottom sheet - let it remain visible
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceMappingErrorDialog(
    BuildContext context,
    DashboardViewModel viewModel,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(height: 16),

              // Error title
              const Text(
                'Device Mapping Failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Error message
              Text(
                viewModel.deviceMappingError,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // OK button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    viewModel.closeDeviceMappingErrorDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF17961), // Orange-red
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
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectDevicePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Text(
            'Connect Device',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: const Text(
            'Please connect to the Evolv28 device to play programs.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFF17961), // Orange color
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BlinkingBluetoothIcon extends StatefulWidget {
  @override
  _BlinkingBluetoothIconState createState() => _BlinkingBluetoothIconState();
}

class _BlinkingBluetoothIconState extends State<_BlinkingBluetoothIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: const Icon(
            Icons.bluetooth_searching,
            color: Colors.orange,
            size: 30,
          ),
        );
      },
    );
  }
}
