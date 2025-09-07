import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router_config.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Main content
            Expanded(
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
