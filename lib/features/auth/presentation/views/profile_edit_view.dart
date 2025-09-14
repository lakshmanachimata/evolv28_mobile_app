import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/profile_edit_viewmodel.dart';

class ProfileEditView extends StatelessWidget {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = ProfileEditViewModel();
        viewModel.initialize();
        return viewModel;
      },
      child: const _ProfileEditViewBody(),
    );
  }
}

class _ProfileEditViewBody extends StatelessWidget {
  const _ProfileEditViewBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileEditViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background
              _buildBackground(),

              // Main content
              _buildMainContent(context, viewModel),
            ],
          ),
        );
      },
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

  Widget _buildMainContent(
    BuildContext context,
    ProfileEditViewModel viewModel,
  ) {
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

                  // Profile content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Profile picture section
                          _buildProfilePictureSection(),

                          const SizedBox(height: 32),

                          // Form fields
                          _buildFormFields(context, viewModel),

                          const SizedBox(height: 32),

                          // Save button
                          _buildSaveButton(context, viewModel),

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
            onTap: () => context.go(AppRoutes.profile),
            child: const Icon(Icons.close, color: Colors.black, size: 24),
          ),

          // Profile title
          const Expanded(
            child: Center(
              child: Text(
                'PROFILE',
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


  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        // Profile picture placeholder
        GestureDetector(
          onTap: () {
            // Handle profile picture change
            print('Change profile picture');
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFF17961), // Orange color
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Edit Picture button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF17961), // Orange color
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Edit Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Friends icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.people,
                color: Colors.black,
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    ProfileEditViewModel viewModel,
  ) {
    return Column(
      children: [
        _buildFormField('FIRST NAME', 'usereve', Icons.person_outline),
        const SizedBox(height: 20),
        _buildFormField('LAST NAME', 'eve', Icons.person_outline),
        const SizedBox(height: 20),
        _buildFormField(
          'Email',
          'usereve@yopmail.com',
          Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          'Country',
          'Select Country',
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          'DATE OF BIRTH',
          'Enter Your Date of birth',
          Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          'GENDER',
          'Select Gender',
          Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildFormField(String label, String placeholder, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          style: const TextStyle(color: Colors.black, fontSize: 16),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildSaveButton(
    BuildContext context,
    ProfileEditViewModel viewModel,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle save profile
          print('Save profile');
          context.go(AppRoutes.profile);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF17961), // Orange color
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'SAVE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
