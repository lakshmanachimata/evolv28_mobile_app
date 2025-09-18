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
  void initState() {
    super.initState();
    // Initialize the programs view
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = Provider.of<ProgramsViewModel>(context, listen: false);
      // Initialize Bluetooth listener
      await viewModel.initialize();
      // Check if we should show player screen (coming from dashboard player card)
      if (ProgramsViewModel.programIdFromDashboard != null) {
        viewModel.navigateFromDashboardPlayer(
          ProgramsViewModel.programIdFromDashboard!,
        );
        ProgramsViewModel.clearProgramIdFromDashboard();
      }
    });
  }
  
  String _formatProgramName(String fileName) {
    // Remove .bcu extension and convert to title case
    String name = fileName.replaceAll('.bcu', '');
    // Replace underscores with spaces
    name = name.replaceAll('_', ' ');
    // Convert to title case (first letter of each word capitalized)
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  String _getIconPathForProgram(String programName) {
    // Map program names to icon paths (same as ProgramsViewModel)
    switch (programName) {
      case 'Sleep Better':
        return 'assets/images/sleep_better.svg';
      case 'Improve Mood':
        return 'assets/images/improve_mood.svg';
      case 'Focus Better':
        return 'assets/images/focus_better.svg';
      case 'Remove Stress':
        return 'assets/images/remove_stress.svg';
      case 'Calm Mind':
        return 'assets/images/calm_mind.svg';
      case 'Reduce Anxiety':
        return 'assets/images/reduce_anxiety.svg';
      default:
        return 'assets/images/sleep_better.svg';
    }
  }
  
  Widget _buildLoadingOverlay(BuildContext context, ProgramsViewModel viewModel) {
    // Show the actual program name being played
    final programName = viewModel.selectedBcuFile != null 
        ? _formatProgramName(viewModel.selectedBcuFile!)
        : 'Program';
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Loading indicator
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF4CAF50), // Green color
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Loading text
              Text(
                'Playing $programName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Starting your wellness program',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ProgramsViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // Background Image
              _buildBackground(viewModel),

              // Main Content
              _buildMainContent(context),
              
              // Loading Overlay
              Consumer<ProgramsViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isSendingPlayCommands) {
                    return _buildLoadingOverlay(context, viewModel);
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(ProgramsViewModel viewModel) {
    String backgroundImage;
    if (viewModel.isInFeedbackMode) {
      backgroundImage = 'assets/images/shapes-background.png';
    } else if (viewModel.isInPlayerMode) {
      backgroundImage = 'assets/images/player-background.png';
    } else {
      backgroundImage = 'assets/images/goals-background.png';
    }

    return Positioned.fill(
      child: Stack(
        children: [
          Image.asset(
            backgroundImage, 
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          if (viewModel.isInFeedbackMode)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white.withOpacity(0.9),
            ),
        ],
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

              const SizedBox(height: 20),

              // Content - Programs List, Player, or Feedback
              Expanded(
                child: viewModel.isInFeedbackMode
                    ? _buildFeedbackInterface(context, viewModel)
                    : viewModel.isInPlayerMode
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
          child: viewModel.isInFeedbackMode
              ? _buildFeedbackHeader(context, viewModel)
              : viewModel.isInPlayerMode
              ? _buildPlayerHeader(context, viewModel)
              : SizedBox.shrink(), // Remove programs header
        );
      },
    );
  }


  Widget _buildPlayerHeader(BuildContext context, ProgramsViewModel viewModel) {
    return Column(
      children: [
        SizedBox(height: 36),
        Image.asset(
          'assets/images/evolv_text.png',
          width: MediaQuery.of(context).size.width * 0.25,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildFeedbackHeader(
    BuildContext context,
    ProgramsViewModel viewModel,
  ) {
    return Column(
      children: [
        SizedBox(height: 36),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => viewModel.selectProgram(program.id),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Program Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: program.iconPath.endsWith('.png')
                        ? Image.asset(program.iconPath, width: 32, height: 32)
                        : SvgPicture.asset(
                            program.iconPath,
                            width: 32,
                            height: 32,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Recommended Time: ${program.recommendedTime}',
                        style: TextStyle(
                          fontSize: 14,
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
                    // Favorite icon
                    GestureDetector(
                      onTap: () => viewModel.toggleFavorite(program.id),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          program.isFavorite
                              ? 'assets/images/fav_filled.svg'
                              : 'assets/images/fav_outline.svg',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Play button
                    GestureDetector(
                      onTap: () {
                        print('🎵 Programs: Play button tapped for program: ${program.id}');
                        viewModel.playBluetoothProgram(program.id);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF17961),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
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

  Widget _buildPlayerInterface(
    BuildContext context,
    ProgramsViewModel viewModel,
  ) {
    ProgramData currentProgram;
    
    // Handle Bluetooth programs
    if (viewModel.isPlaySuccessful && viewModel.selectedBcuFile != null) {
      // Create a program data for the Bluetooth program
      final programName = _formatProgramName(viewModel.selectedBcuFile!);
      currentProgram = ProgramData(
        id: viewModel.selectedBcuFile!,
        title: programName,
        recommendedTime: '2 hrs',
        iconPath: _getIconPathForProgram(programName),
        isLocked: false,
        isFavorite: false,
      );
    } else {
      // Handle regular programs
      currentProgram = viewModel.programs.firstWhere(
        (program) => program.id == viewModel.currentPlayingProgramId,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Program Icon with Sleep Z's
          const SizedBox(height: 24),
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

          const SizedBox(height: 16),

          // Minimize Button
          _buildMinimizeButton(context),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlayerIcon(ProgramData program) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/sleep_icon.svg',
          width: 130,
          height: 130,
        ),
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
        inactiveTrackColor: Color(0xFFBDBDBD),
        thumbColor: const Color(0xFFF17961),
        thumbShape: const _CustomSliderThumbShape(),
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
      height: 40,
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

  Widget _buildMinimizeButton(BuildContext context) {
    return Consumer<ProgramsViewModel>(
      builder: (context, viewModel, child) {
        return SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: () => viewModel.minimizeToDashboard(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF17961),
              side: const BorderSide(color: Color(0xFFF17961), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.transparent,
            ),
            child: const Text(
              'Minimise',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333), // Dark gray text
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildFeedbackInterface(
    BuildContext context,
    ProgramsViewModel viewModel,
  ) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Completion Icon
              _buildCompletionIcon(),

              const SizedBox(height: 60),

              // Feedback Question
              const Text(
                'Slept Better?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const Text(
                'Take a moment to check-in with yourself.',
                style: TextStyle(fontSize: 14, color: Colors.black),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feedback Options
              _buildFeedbackOptions(viewModel),

              const SizedBox(height: 60),

              // Action Buttons
              _buildFeedbackActionButtons(context, viewModel),

              const SizedBox(height: 40),
            ],
          ),
        ),

        // Success Popup
        if (viewModel.showSuccessPopup) _buildSuccessPopup(context, viewModel),
      ],
    );
  }

  Widget _buildCompletionIcon() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/checkmark_icon.svg',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 32),
        const Text(
          'Nicely done!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackOptions(ProgramsViewModel viewModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeedbackOption(
          'Amazing',
          'assets/images/feedback_amaging.png',
          FeedbackType.amazing,
          viewModel,
        ),
        _buildFeedbackOption(
          'Good',
          'assets/images/feedback_good.png',
          FeedbackType.good,
          viewModel,
        ),
        _buildFeedbackOption(
          'Okay',
          'assets/images/feedback_okay.png',
          FeedbackType.okay,
          viewModel,
        ),
      ],
    );
  }

  Widget _buildFeedbackOption(
    String label,
    String imagePath,
    FeedbackType type,
    ProgramsViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedFeedback == type;

    return GestureDetector(
      onTap: () => viewModel.selectFeedback(type),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF17961)
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFF17961) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackActionButtons(
    BuildContext context,
    ProgramsViewModel viewModel,
  ) {
    return Column(
      children: [
        // Repeat Button
        SizedBox(
          width: double.infinity,
          height: 40,
          child: ElevatedButton(
            onPressed: () => viewModel.repeatProgram(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF17961),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Repeat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Close Button
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: () => viewModel.closeFeedback(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF17961),
              side: const BorderSide(color: Color(0xFFF17961), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF17961),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessPopup(BuildContext context, ProgramsViewModel viewModel) {
    return Container(
      color: Colors.black.withOpacity(0.5), // Semi-transparent background
      child: Center(
        child: Container(
          width: 280,
          height: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => viewModel.hideSuccessPopup(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF17961),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              // Success icon
              SvgPicture.asset(
                'assets/images/checkmark_icon.svg',
                width: 64,
                height: 64,
              ),

              const SizedBox(height: 24),

              // Success title
              const Text(
                'Success',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Success message
              const Text(
                'Feedback updated successfully',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // OK button
              SizedBox(
                width: 140,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => viewModel.onSuccessPopupOk(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF17961),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    ProgramsViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem('assets/images/bottom_menu_home.svg', 0, viewModel),
            _buildNavItem('assets/images/bottom_menu_programs_selected.svg', 1, viewModel),
            _buildNavItem('assets/images/bottom_menu_device.png', 2, viewModel),
            _buildNavItem('assets/images/bottom_menu_user.svg', 3, viewModel),
          ],
        ),
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
          iconPath.endsWith('.png')
              ? Image.asset(iconPath, width: 40, height: 40)
              : SvgPicture.asset(iconPath, width: 30, height: 30),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CustomSliderThumbShape extends SliderComponentShape {
  const _CustomSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(16, 16);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    // Create a custom painter that matches the progress_marker.svg design
    final Canvas canvas = context.canvas;

    // Draw drop shadow (simplified version of the SVG filter)
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    canvas.drawCircle(center, 6, shadowPaint);

    // Draw white circle (main body)
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, whitePaint);

    // Draw orange border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFF17961)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, 5.5, borderPaint);
  }
}
