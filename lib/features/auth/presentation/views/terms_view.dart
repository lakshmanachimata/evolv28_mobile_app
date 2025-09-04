import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class TermsView extends StatefulWidget {
  const TermsView({super.key});

  @override
  State<TermsView> createState() => _TermsViewState();
}

class _TermsViewState extends State<TermsView> {
  bool _agreedToPrivacyPolicy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background SVG
          SvgPicture.asset(
            'assets/images/bg_user.svg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header Section with evolv28 logo
                // _buildHeader(),

                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const Spacer(),

                        // Privacy Policy Card
                        _buildPrivacyPolicyCard(),

                        const Spacer(),
                        // Next Button
                        _buildNextButton(),
                        const SizedBox(height: 48),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F2), // Light pink/peach background
      ),
      child: Row(
        children: [
          // evolv28 Logo with smiley face in 'o'
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'evolv',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Arial',
                    letterSpacing: 0.5,
                  ),
                ),
                // Custom 'o' with smiley face
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'o',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Arial',
                        letterSpacing: 0.5,
                      ),
                    ),
                    // Smiley face inside the 'o'
                    Positioned(
                      top: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left eye
                          Container(
                            width: 2,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD4C7), // Lighter peach
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Right eye
                          Container(
                            width: 2,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD4C7), // Lighter peach
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Smile
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: 8,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFFFD4C7), // Lighter peach
                              width: 1,
                            ),
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '28',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Arial',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Abstract graphic elements (birds and cloud shapes)
          Row(
            children: [
              // Bird silhouettes
              SvgPicture.asset(
                'assets/images/bird_silhouette.svg',
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Colors.black54,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/images/bird_silhouette.svg',
                height: 12,
                colorFilter: const ColorFilter.mode(
                  Colors.black54,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12),
              // Cloud-like shapes
              Container(
                width: 20,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD4C7),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD4C7),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicyCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            // Shield icon with checkmark
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: SvgPicture.asset(
                  'assets/images/terms_icon.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Main title
            Text(
              'Lorem ipsum dolor sit amet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 4),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card content section
                  Text(
                    'Lorem ipsum dolor sit amet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Body text
                  Text(
                    'Lorem ipsum dolor sit amet consectetur. Ornare ullamcorper non orci cursus massa ante adipiscing.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Privacy Policy link
                  GestureDetector(
                    onTap: () {
                      // Handle privacy policy link tap
                    },
                    child: Text(
                      'Read our Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Agree checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _agreedToPrivacyPolicy = !_agreedToPrivacyPolicy;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF17961), // Light orange/peach
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _agreedToPrivacyPolicy
                                  ? Colors.white
                                  : Colors.transparent,
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _agreedToPrivacyPolicy
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Color(0xFFFF8A65),
                                  )
                                : null,
                          ),

                          const SizedBox(width: 12),

                          // Text
                          Expanded(
                            child: Text(
                              'Agree to our Privacy Policy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: _agreedToPrivacyPolicy
              ? () {
                  // Navigate to next screen
                  context.go('/home');
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF17961), // Light orange/peach
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
