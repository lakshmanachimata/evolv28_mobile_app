import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../viewmodels/devices_viewmodel.dart';

class DevicesView extends StatelessWidget {
  const DevicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = DevicesViewModel();
        viewModel.initialize(); // Don't await here, let it run asynchronously
        return viewModel;
      },
      child: const _DevicesViewBody(),
    );
  }
}

class _DevicesViewBody extends StatefulWidget {
  const _DevicesViewBody();

  @override
  State<_DevicesViewBody> createState() => _DevicesViewBodyState();
}

class _DevicesViewBodyState extends State<_DevicesViewBody> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check if we should show permission dialog on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<DevicesViewModel>(context, listen: false);
      viewModel.checkPermissionOnLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop BLE scanning when screen is disposed
    final viewModel = Provider.of<DevicesViewModel>(context, listen: false);
    viewModel.dispose();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recheck Bluetooth status when app resumes
      final viewModel = Provider.of<DevicesViewModel>(context, listen: false);
      viewModel.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DevicesViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background
              _buildBackground(),

              // Main content
              _buildMainContent(context, viewModel),

              // Dialogs
              if (viewModel.showBluetoothEnableDialog)
                _buildBluetoothEnableDialog(context, viewModel),

              if (viewModel.showBluetoothScanPermissionDialog)
                _buildBluetoothScanPermissionDialog(context, viewModel),

              if (viewModel.showDeviceActivatedDialog)
                _buildDeviceActivatedDialog(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset('assets/images/bg_three.png', fit: BoxFit.cover),
    );
  }

  Widget _buildMainContent(BuildContext context, DevicesViewModel viewModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            const SizedBox(height: 36),

            _buildHeader(context, viewModel),

            const SizedBox(height: 200),

            // Content based on state
            if (viewModel.isScanning)
              _buildScanningState()
            else if (viewModel.nearbyDevices.isEmpty && viewModel.isBluetoothEnabled)
              _buildNoDevicesState(context, viewModel)
            else if (viewModel.nearbyDevices.isNotEmpty)
              _buildDevicesList(context, viewModel)
            else
              _buildInitialState(context, viewModel),

            const Spacer(),

            // Bottom buttons
            _buildBottomButtons(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DevicesViewModel viewModel) {
    return Column(
      children: [
        // Evolv28 Logo
        Image.asset(
          'assets/images/evolv_text.png',
          width: MediaQuery.of(context).size.width * 0.25,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 36),

        // Welcome message
        Text(
          'Welcome ${viewModel.userName},\nselect your device',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInitialState(BuildContext context, DevicesViewModel viewModel) {
    // Auto-start scanning when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.startDeviceConnection();
    });
    
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Nearby devices',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _buildScanningAnimation(),
      ],
    );
  }

  Widget _buildScanningState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildScanningAnimation(),
      ],
    );
  }

  Widget _buildScanningAnimation() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedDots(),
            const SizedBox(width: 8),
            Text(
              'Scanning for devices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07A60)),
        ),
      ],
    );
  }

  Widget _buildAnimatedDots() {
    return _AnimatedDots();
  }

  Widget _buildNoDevicesState(
    BuildContext context,
    DevicesViewModel viewModel,
  ) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Nearby devices',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'No devices available',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildDevicesList(BuildContext context, DevicesViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () async {
        await viewModel.refreshScan();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Nearby devices',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ...viewModel.nearbyDevices.map(
              (device) => _buildDeviceItem(context, viewModel, device),
            ),
            // Add extra space to ensure pull-to-refresh works
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(
    BuildContext context,
    DevicesViewModel viewModel,
    Map<String, dynamic> device,
  ) {
    final isConnected = device['isConnected'] as bool;
    final isConnecting =
        viewModel.isConnecting && viewModel.selectedDeviceId == device['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isConnected
            ? Border.all(color: const Color(0xFFF07A60), width: 2)
            : null,
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
          Icon(
            Icons.bluetooth,
            color: isConnected ? const Color(0xFFF07A60) : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isConnected
                        ? const Color(0xFFF07A60)
                        : Colors.black87,
                  ),
                ),
                Text(
                  'Signal: ${device['signalStrength']}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isConnecting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07A60)),
              ),
            )
          else if (isConnected)
            Icon(Icons.check_circle, color: const Color(0xFFF07A60), size: 24)
          else
            SizedBox(
              width: 80,
              height: 32,
              child: ElevatedButton(
                onPressed: () => viewModel.connectToDevice(device['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF07A60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Connect', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, DevicesViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          height: 40,
          child: SizedBox(
            child: TextButton(
              onPressed: viewModel.cantFindDevice,
              style: TextButton.styleFrom(
                side: BorderSide(color: Color(0xFF547D81), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                "Can't find your device?",
                style: TextStyle(color: Color(0xFF547D81), fontSize: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 100,
          height: 40,
          child: ElevatedButton(
            onPressed: viewModel.tryAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF07A60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBluetoothEnableDialog(
    BuildContext context,
    DevicesViewModel viewModel,
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

  String _getBluetoothEnableMessage() {
    if (Platform.isAndroid) {
      return 'Please enable Bluetooth in your device settings to connect with Evolv28. Tap OK to open Bluetooth settings.';
    } else if (Platform.isIOS) {
      return 'Please enable Bluetooth in Settings > Bluetooth to connect with Evolv28. Tap OK to open Settings.';
    } else {
      return 'Please enable Bluetooth on your device to connect with Evolv28';
    }
  }

  Widget _buildBluetoothScanPermissionDialog(
    BuildContext context,
    DevicesViewModel viewModel,
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
                  'Bluetooth Permission',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Allow Evolv28 to discover nearby Bluetooth devices',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.allowBluetoothScanPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF07A60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Allow',
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

  Widget _buildDeviceActivatedDialog(
    BuildContext context,
    DevicesViewModel viewModel,
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
                // Success Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF07A60),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 30),
                ),

                const SizedBox(height: 16),

                // Success Message
                const Text(
                  'The device is connected successfully',
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
                    onPressed: viewModel.handleDeviceActivatedOk,
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

class _AnimatedDots extends StatefulWidget {
  @override
  _AnimatedDotsState createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (animationValue * 2 - 1).abs();
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF07A60),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
