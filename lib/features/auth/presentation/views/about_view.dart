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
              SafeArea(
                child: Column(
                  children: [
                    // Bottom sheet content
                    Expanded(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.85,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/images/modal-background.png'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header with close button
                            _buildBottomSheetHeader(context),
                            
                            // Main content
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      
                                      // App logo
                                      _buildAppLogo(),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // About content
                                      _buildAboutContent(),
                                      
                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

  Widget _buildBackground() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/images/modal-background.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildBottomSheetHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          // Close button
          GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/evolv_text.png',
          width: 200,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        const Text(
          'Version 1.0.0',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About evolv28',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'evolv28 is an innovative wearable device designed to enhance your mental well-being through advanced neurotechnology. Our cutting-edge device combines the latest in neuroscience research with user-friendly technology to help you achieve better mental health outcomes.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Safety & Effectiveness',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Our device has been extensively tested and validated through rigorous clinical trials. It is designed with your safety as the top priority, featuring multiple safety mechanisms and real-time monitoring to ensure optimal and secure operation.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Developed by Aether Mindtech',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'evolv28 is proudly developed by Aether Mindtech, a leading company in the field of neurotechnology and mental health innovation. Our team of experts includes neuroscientists, engineers, and healthcare professionals dedicated to improving lives through technology.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'For support, questions, or feedback, please contact us at:\n\nEmail: support@evolv28.com\nPhone: +1 (555) 123-4567\nWebsite: www.evolv28.com',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
