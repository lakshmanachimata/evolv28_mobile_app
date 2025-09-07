import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router_config.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

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
                    
                    // Privacy title
                    _buildTitle(),
                    
                    const SizedBox(height: 24),
                    
                    // Privacy content
                    _buildPrivacyContent(),
                    
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
            'Privacy & Legal Terms',
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

  Widget _buildTitle() {
    return const Text(
      'Privacy Policy & Legal Terms',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          'Information We Collect',
          'We collect the following types of information:\n\n• Email address and contact information\n• Age and demographic information\n• Usage history and app interactions\n• Mental health data and progress tracking\n• Device information and technical data\n• Location data (with your permission)\n• Feedback and support communications',
        ),
        const SizedBox(height: 24),
        _buildSection(
          'How We Use Your Information',
          'Your information is used to:\n\n• Provide and improve our services\n• Personalize your experience\n• Track your progress and provide insights\n• Send important updates and notifications\n• Provide customer support\n• Conduct research and development\n• Ensure app security and prevent fraud',
        ),
        const SizedBox(height: 24),
        _buildSection(
          'Data Security',
          'We implement industry-standard security measures to protect your data:\n\n• End-to-end encryption for sensitive data\n• Secure data storage and transmission\n• Regular security audits and updates\n• Access controls and authentication\n• Data backup and recovery procedures\n• Compliance with international security standards',
        ),
        const SizedBox(height: 24),
        _buildSection(
          'Data Sharing',
          'We do not sell your personal information. We may share data only in these circumstances:\n\n• With your explicit consent\n• To comply with legal obligations\n• To protect our rights and safety\n• With trusted service providers (under strict agreements)\n• In case of business transfers or mergers\n• For research purposes (anonymized data only)',
        ),
        const SizedBox(height: 24),
        _buildSection(
          'Your Rights',
          'You have the right to:\n\n• Access your personal data\n• Correct inaccurate information\n• Delete your account and data\n• Export your data\n• Opt out of certain data processing\n• Withdraw consent at any time\n• File complaints with regulatory authorities',
        ),
        const SizedBox(height: 24),
        _buildSection(
          'Legal Terms',
          'By using evolv28, you agree to:\n\n• Use the device responsibly and as intended\n• Not misuse or tamper with the device\n• Follow all safety guidelines and instructions\n• Respect intellectual property rights\n• Comply with applicable laws and regulations\n• Accept our terms of service and privacy policy',
        ),
        const SizedBox(height: 24),
        _buildSection(
          'Contact Us',
          'For questions about this privacy policy or your data:\n\nEmail: privacy@evolv28.com\nPhone: +1 (555) 123-4567\nAddress: Aether Mindtech Inc.\n123 Innovation Drive\nTech City, TC 12345',
        ),
        const SizedBox(height: 24),
        const Text(
          'Last Updated: December 2024',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
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
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
