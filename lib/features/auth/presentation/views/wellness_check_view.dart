import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';

class WellnessCheckView extends StatelessWidget {
  const WellnessCheckView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8), // Light teal-green
              Color(0xFFF0F8F0), // Very light green
              Colors.white,       // White at bottom
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Wellness Cards
                      _buildMindfulnessCard(context),
                      
                      const SizedBox(height: 20),
                      
                      _buildSleepCard(context),
                      
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.transparent, // Fully transparent background
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.go(AppRoutes.dashboard),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          const Text(
            'Wellness check',
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

  Widget _buildMindfulnessCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.mindfulnessForm),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Mindfulness Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF07A60).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Color(0xFFF07A60),
                size: 30,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mindfulness',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start your mindfulness journey to improve focus and reduce stress.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.mindfulnessForm), // Same flow for now
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Sleep Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bedtime,
                color: Color(0xFF4A90E2),
                size: 30,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable sleep tracking to build better bedtime habits.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
