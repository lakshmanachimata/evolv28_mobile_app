import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';

class BulkDownloadView extends StatelessWidget {
  const BulkDownloadView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BulkDownloadViewBody();
  }
}

class _BulkDownloadViewBody extends StatelessWidget {
  const _BulkDownloadViewBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Main content
          _buildMainContent(context),
        ],
      ),
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

  Widget _buildMainContent(BuildContext context) {
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
                  // Dark header bar
                  _buildDarkHeader(context),

                  // Download content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Program list
                          _buildProgramList(context),

                          const SizedBox(height: 30),

                          // Download All button
                          _buildDownloadAllButton(context),

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

  Widget _buildDarkHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),

          // Title
          const Expanded(
            child: Center(
              child: Text(
                'Download Programs',
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

  Widget _buildProgramList(BuildContext context) {
    final programs = [
      {
        'title': 'Sleep Better',
        'iconPath': 'assets/images/bulk_sleep_better.svg',
        'description': 'Improve your sleep quality',
      },
      {
        'title': 'Improve Mood',
        'iconPath': 'assets/images/bulk_improve_mood.svg',
        'description': 'Boost your emotional well-being',
      },
      {
        'title': 'Improve Focus',
        'iconPath': 'assets/images/bulk_improve_focus.svg',
        'description': 'Enhance concentration and attention',
      },
      {
        'title': 'Reduce Anxiety',
        'iconPath': 'assets/images/bulk_reduce_anxiety.svg',
        'description': 'Manage anxiety and stress',
      },
      {
        'title': 'Remove Stress',
        'iconPath': 'assets/images/bulk_remove_stress.svg',
        'description': 'Relax and unwind',
      },
      {
        'title': 'Calm Your Mind',
        'iconPath': 'assets/images/bulk_calm_mind.svg',
        'description': 'Achieve mental clarity',
      },
    ];

    return Column(
      children: programs
          .map((program) => _buildProgramCard(context, program))
          .toList(),
    );
  }

  Widget _buildProgramCard(BuildContext context, Map<String, dynamic> program) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0), // Light grey background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          SvgPicture.asset(
            program['iconPath'] as String,
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(
              Color(0xFFF07A60), // Coral color
              BlendMode.srcIn,
            ),
          ),

          const SizedBox(width: 16),

          // Text content
          Expanded(
            child: Text(
              program['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadAllButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle download all action
          _showDownloadSuccessDialog(context, 'All Programs');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF17A61), // Coral color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'DOWNLOAD ALL',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  void _showDownloadSuccessDialog(BuildContext context, String programName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go(AppRoutes.settings);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF17A61),
                          borderRadius: BorderRadius.circular(20),
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

                const SizedBox(height: 16),

                // Success icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF17A61),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 30),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Download Complete',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  '$programName has been downloaded successfully',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // OK button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.settings);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF17A61),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
}
