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
      body: Consumer<ProgramsViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // Background Image
              _buildBackground(viewModel),

              // Main Content
              _buildMainContent(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(ProgramsViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        viewModel.isInPlayerMode
            ? 'assets/images/player-background.png'
            : 'assets/images/goals-background.png',
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

              const SizedBox(height: 24),

              // Content - either Programs List or Player
              Expanded(
                child: viewModel.isInPlayerMode
                    ? _buildPlayerInterface(context, viewModel)
                    : _buildProgramsList(context, viewModel),
              ),

              // Bottom Navigation
              _buildBottomNavigation(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<ProgramsViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: viewModel.isInPlayerMode
              ? _buildPlayerHeader(context, viewModel)
              : _buildProgramsHeader(context),
        );
      },
    );
  }

  Widget _buildProgramsHeader(BuildContext context) {
    return Row(
      children: [
        // Back Button
        GestureDetector(
          onTap: () => context.go(AppRoutes.dashboard),
          child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
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
    );
  }

  Widget _buildPlayerHeader(BuildContext context, ProgramsViewModel viewModel) {
    return Column(
      children: [
        SizedBox(height: 20),
        Image.asset(
          'assets/images/evolv_text.png',
          width: MediaQuery.of(context).size.width * 0.25,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildProgramsList(BuildContext context, ProgramsViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      child: Column(
        children: viewModel.programs
            .map((program) => _buildProgramCard(context, program, viewModel))
            .toList(),
      ),
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    ProgramData program,
    ProgramsViewModel viewModel,
  ) {
    final isSelected = program.id == viewModel.selectedProgramId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Color(0xFFEEEDEE),
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
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Program Icon
                    program.iconPath.endsWith('.png')
                        ? Image.asset(program.iconPath, width: 48, height: 48)
                        : SvgPicture.asset(
                            program.iconPath,
                            width: 48,
                            height: 48,
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
                              color: isSelected
                                  ? const Color(0xFFF17961)
                                  : Colors.black,
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
                        const SizedBox(width: 8),

                        // Favorite icon
                        GestureDetector(
                          onTap: () => viewModel.toggleFavorite(program.id),
                          child: SvgPicture.asset(
                            program.isFavorite
                                ? 'assets/images/fav_filled.svg'
                                : 'assets/images/fav_outline.svg',
                            width: 18,
                            height: 18,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Play button
                        GestureDetector(
                          onTap: () => viewModel.playProgram(program.id),
                          child: Container(
                            width: 24,
                            height: 24,
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
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              ),

              // Lock icon positioned at top right
              if (program.isLocked)
                Positioned(
                  top: 0,
                  right: 0,
                  child: SvgPicture.asset(
                    'assets/images/locked_program_icon.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInterface(
    BuildContext context,
    ProgramsViewModel viewModel,
  ) {
    final currentProgram = viewModel.programs.firstWhere(
      (program) => program.id == viewModel.currentPlayingProgramId,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Program Icon with Sleep Z's
          _buildPlayerIcon(currentProgram),

          const SizedBox(height: 12),

          // Program Title
          Text(
            currentProgram.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Status
          const Text(
            'Now playing',
            style: TextStyle(fontSize: 16, color: Colors.black),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Play/Pause Button
          _buildPlayPauseButton(viewModel),

          const SizedBox(height: 12),

          // Progress Bar
          _buildProgressBar(viewModel),

          const SizedBox(height: 0),

          // Time Display
          _buildTimeDisplay(viewModel),

          const SizedBox(height: 12),

          // Recommended Time
          Text(
            'Recommended Time: ${currentProgram.recommendedTime}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // I'm Done Button
          _buildImDoneButton(viewModel),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayerIcon(ProgramData program) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset('assets/images/sleep_well.png', width: 130, height: 130),
      ],
    );
  }

  Widget _buildPlayPauseButton(ProgramsViewModel viewModel) {
    return GestureDetector(
      onTap: () => viewModel.togglePlayPause(),
      child: SizedBox(
        width: 100,
        height: 100,
        child: Center(
          child: viewModel.isPlaying
              ? Image.asset(
                  'assets/images/stop_play.png',
                  width: 100,
                  height: 100,
                )
              : const Icon(Icons.play_arrow, color: Colors.white, size: 100),
        ),
      ),
    );
  }

  Widget _buildProgressBar(ProgramsViewModel viewModel) {
    final progress =
        viewModel.currentPosition.inSeconds / viewModel.totalDuration.inSeconds;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFFF17961),
        inactiveTrackColor: Colors.grey.shade300,
        thumbColor: const Color(0xFFF17961),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        trackHeight: 4,
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChanged: (value) {
          final newPosition = Duration(
            seconds: (value * viewModel.totalDuration.inSeconds).round(),
          );
          viewModel.updatePosition(newPosition);
        },
      ),
    );
  }

  Widget _buildTimeDisplay(ProgramsViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(viewModel.currentPosition),
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        Text(
          _formatDuration(viewModel.totalDuration),
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildImDoneButton(ProgramsViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => viewModel.finishProgram(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF17961),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          "I'm Done",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    ProgramsViewModel viewModel,
  ) {
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
          _buildNavItem(
            'assets/images/bottom_menu_programs_selected.svg',
            1,
            viewModel,
          ),
          _buildNavItem('assets/images/bottom_menu_device.svg', 2, viewModel),
          _buildNavItem('assets/images/bottom_menu_user.svg', 3, viewModel),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String iconPath,
    int index,
    ProgramsViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedTabIndex == index;

    return GestureDetector(
      onTap: () => viewModel.onTabSelected(index, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(iconPath, width: 24, height: 24),
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
