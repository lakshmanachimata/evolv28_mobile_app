import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../viewmodels/devices_viewmodel.dart';

class DevicesView extends StatelessWidget {
  const DevicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DevicesViewModel()..initialize(),
      child: const _DevicesViewBody(),
    );
  }
}

class _DevicesViewBody extends StatelessWidget {
  const _DevicesViewBody();

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
              if (viewModel.showBluetoothPermissionDialog)
                _buildBluetoothPermissionDialog(context, viewModel),
              
              if (viewModel.showLocationPermissionDialog)
                _buildLocationPermissionDialog(context, viewModel),
              
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
      child: Image.asset(
        'assets/images/bg_three.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, DevicesViewModel viewModel) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            const SizedBox(height: 40),

            _buildHeader(viewModel),
            
            const SizedBox(height: 40),
          
            // Content based on state
            if (!viewModel.isBluetoothEnabled)
              _buildInitialState(context, viewModel)
            else if (viewModel.isScanning)
              _buildScanningState()
            else if (viewModel.nearbyDevices.isEmpty)
              _buildNoDevicesState(context, viewModel)
            else
              _buildDevicesList(context, viewModel),
            
            const Spacer(),
            
            // Bottom buttons
            _buildBottomButtons(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DevicesViewModel viewModel) {
    return Column(
      children: [
        // Evolv28 Logo
        Image.asset(
          'assets/images/evolv_text.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        
        const SizedBox(height: 20),
        
        // Welcome message
        Text(
          'Welcome ${viewModel.userName},\nselect your device',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }



  Widget _buildInitialState(BuildContext context, DevicesViewModel viewModel) {
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
        ElevatedButton(
          onPressed: () => viewModel.showBluetoothPermission(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF07A60),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Start Scanning',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          'Scanning for devices...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07A60)),
        ),
      ],
    );
  }

  Widget _buildNoDevicesState(BuildContext context, DevicesViewModel viewModel) {
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
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDevicesList(BuildContext context, DevicesViewModel viewModel) {
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
        ...viewModel.nearbyDevices.map((device) => _buildDeviceItem(context, viewModel, device)),
      ],
    );
  }

  Widget _buildDeviceItem(BuildContext context, DevicesViewModel viewModel, Map<String, dynamic> device) {
    final isConnected = device['isConnected'] as bool;
    final isConnecting = viewModel.isConnecting && viewModel.selectedDeviceId == device['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isConnected ? Border.all(color: const Color(0xFFF07A60), width: 2) : null,
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
                    color: isConnected ? const Color(0xFFF07A60) : Colors.black87,
                  ),
                ),
                Text(
                  'Signal: ${device['signalStrength']}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
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
            Icon(
              Icons.check_circle,
              color: const Color(0xFFF07A60),
              size: 24,
            )
          else
            ElevatedButton(
              onPressed: () => viewModel.connectToDevice(device['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF07A60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, DevicesViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: viewModel.cantFindDevice,
            child: Text(
              "Can't find your device?",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.tryAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF07A60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBluetoothPermissionDialog(BuildContext context, DevicesViewModel viewModel) {
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
                  'Allow Bluetooth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please allow bluetooth for establishing the connection with Evolv28',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.allowBluetoothPermission,
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

  Widget _buildLocationPermissionDialog(BuildContext context, DevicesViewModel viewModel) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Location Permission',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: viewModel.cancelLocationPermission,
                      child: Icon(
                        Icons.close,
                        color: const Color(0xFFF07A60),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'To find nearby devices, Evolv28 app needs Precised Location Permission',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: viewModel.cancelLocationPermission,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: viewModel.allowLocationPermission,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceActivatedDialog(BuildContext context, DevicesViewModel viewModel) {
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
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 30,
                  ),
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
