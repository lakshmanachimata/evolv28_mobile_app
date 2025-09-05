import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/programs_viewmodel.dart';

class ProgramsView extends StatelessWidget {
  const ProgramsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProgramsViewModel(),
      child: const _ProgramsViewBody(),
    );
  }
}

class _ProgramsViewBody extends StatefulWidget {
  const _ProgramsViewBody();

  @override
  State<_ProgramsViewBody> createState() => _ProgramsViewBodyState();
}

class _ProgramsViewBodyState extends State<_ProgramsViewBody> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          _buildBackground(),

          // Main Content
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/images/goals-background.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<ProgramsViewModel>(
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Programs List
              Expanded(child: _buildProgramsList(context, viewModel)),

              // Bottom Navigation
              _buildBottomNavigation(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.go(AppRoutes.dashboard),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          const Text(
            'All Programs',
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

  Widget _buildProgramsList(BuildContext context, ProgramsViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: viewModel.programs.map((program) => _buildProgramCard(context, program, viewModel)).toList(),
      ),
    );
  }

  Widget _buildProgramCard(BuildContext context, ProgramData program, ProgramsViewModel viewModel) {
    final isSelected = program.id == viewModel.selectedProgramId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => viewModel.selectProgram(program.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Program Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF17961) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      program.iconPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isSelected ? Colors.white : Colors.grey.shade600,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Program Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? const Color(0xFFF17961) : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommended Time: ${program.recommendedTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side elements
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Version badge (only for Sleep Better)
                    if (program.id == 'sleep_better')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '18.24 x 16',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),

                    const SizedBox(width: 8),

                    // Lock icon (for locked programs)
                    if (program.isLocked)
                      SvgPicture.asset(
                        'assets/images/locked_program_icon.svg',
                        width: 20,
                        height: 20,
                      ),

                    const SizedBox(width: 8),

                    // Favorite icon
                    GestureDetector(
                      onTap: () => viewModel.toggleFavorite(program.id),
                      child: SvgPicture.asset(
                        program.isFavorite ? 'assets/images/fav_filled.svg' : 'assets/images/fav_outline.svg',
                        width: 20,
                        height: 20,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Play button
                    GestureDetector(
                      onTap: () => viewModel.playProgram(program.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF17961),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
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

  Widget _buildBottomNavigation(BuildContext context, ProgramsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('assets/images/bottom_menu_home.svg', 0, viewModel),
          _buildNavItem('assets/images/bottom_menu_programs_selected.svg', 1, viewModel),
          _buildNavItem('assets/images/bottom_menu_device.svg', 2, viewModel),
          _buildNavItem('assets/images/bottom_menu_user.svg', 3, viewModel),
        ],
      ),
    );
  }

  Widget _buildNavItem(String iconPath, int index, ProgramsViewModel viewModel) {
    final isSelected = viewModel.selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () => viewModel.onTabSelected(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF17961),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
