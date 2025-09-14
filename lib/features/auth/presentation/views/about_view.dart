import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router_config.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Header bar
                  _buildHeader(context),

                  // About content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // About content
                          _buildAboutContent(),

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
      child: Row(
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
            child: const Icon(Icons.settings, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
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
            child: const Icon(Icons.close, color: Colors.black, size: 24),
          ),

          // About title
          const Expanded(
            child: Center(
              child: Text(
                'ABOUT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
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

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'evolv28 is a state-of-the-art innovative wearable device that helps the human cope with issues related to Mental Well-being like work stress, anxiety, restlessness, lack of focus, irregular sleeping patterns, and a slew of other day-to-day problems associated with a restless brain.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'evolv28 is a safe and environment-friendly supportive device, aiming to bring harmony to your mind and body.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'evolv28 is part of InnoPark group of companies, based out of Hyderabad and is a 6-year-old organization comprising highly successful tech companies with a key focus on gaming. Innopark ventured into the Preventive healthcare portfolio by developing products in Medtech Mental wellness and Nutraceutical space.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        // App version section
        const Center(
          child: Column(
            children: [
              Text(
                'evolv28',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'App Version 3.12',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
