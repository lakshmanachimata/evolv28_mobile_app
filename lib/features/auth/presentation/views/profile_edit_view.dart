import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/profile_edit_viewmodel.dart';
import '../../../../core/routing/app_router_config.dart';

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
                                      
                                      // Profile avatar
                                      _buildProfileAvatar(context, viewModel),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Form fields
                                      _buildFormFields(context, viewModel),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Save button
                                      _buildSaveButton(context, viewModel),
                                      
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
      },
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
            'Profile',
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

  Widget _buildProfileAvatar(BuildContext context, ProfileEditViewModel viewModel) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF07A60),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                viewModel.getInitials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: viewModel.changeProfilePicture,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF07A60),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, ProfileEditViewModel viewModel) {
    return Column(
      children: [
        _buildTextField(
          'First Name',
          viewModel.firstName,
          viewModel.updateFirstName,
          Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Last Name',
          viewModel.lastName,
          viewModel.updateLastName,
          Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'Email or Mobile Number',
          viewModel.emailOrMobile,
          viewModel.updateEmailOrMobile,
          Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'Country',
          viewModel.selectedCountry,
          viewModel.countries,
          viewModel.updateCountry,
          Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildDateField(
          context,
          'Date of Birth',
          viewModel.dateOfBirth,
          viewModel.updateDateOfBirth,
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged,
    IconData icon,
  ) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF07A60)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: value.isEmpty ? null : value,
      onChanged: (newValue) => onChanged(newValue ?? ''),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF07A60)),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? value,
    Function(DateTime) onChanged,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value != null
                    ? '${value.day}/${value.month}/${value.year}'
                    : label,
                style: TextStyle(
                  fontSize: 16,
                  color: value != null ? Colors.black : Colors.grey.shade600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, ProfileEditViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF07A60),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
