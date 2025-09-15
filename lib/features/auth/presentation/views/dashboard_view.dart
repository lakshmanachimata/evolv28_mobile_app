import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/programs_viewmodel.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DashboardViewModel(),
      child: const _DashboardViewBody(),
    );
  }
}

class _DashboardViewBody extends StatefulWidget {
  const _DashboardViewBody();

  @override
  State<_DashboardViewBody> createState() => _DashboardViewBodyState();
}

class _DashboardViewBodyState extends State<_DashboardViewBody> {
  @override
  void initState() {
    super.initState();
    // Initialize the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<DashboardViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }

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
        'assets/images/dashboard-background.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF07A60)),
            ),
          );
        }

        return SafeArea(
          child: Column(
            children: [
              // Header with Logo
              _buildHeader(context, viewModel),

              // Main Content Area
              Expanded(child: _buildContentArea(context, viewModel)),

              // Player Card (if playing)
              if (viewModel.showPlayerCard) _buildPlayerCard(context, viewModel),

              // Bottom Navigation
              _buildBottomNavigation(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DashboardViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          // Logo and Notification Bell
          SizedBox(height: 30),
          Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/evolv_text.png',
                  width: MediaQuery.of(context).size.width * 0.25,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 0,
                right: 12,
                child: SvgPicture.asset(
                  'assets/images/noti_icon.svg',
                  width: 30,
                  height: 30,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Greeting
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Good Morning, ${viewModel.userName}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(BuildContext context, DashboardViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connect Card
          _buildConnectCard(context),
          
          const SizedBox(height: 16),

          // Wellness Programs Card
          _buildWellnessProgramsCard(context),
          
          const SizedBox(height: 16),

          // Insights Card
          _buildInsightsCard(context),
          
          const SizedBox(height: 20),

          // Top picks for you section
          _buildTopPicksSection(context),

          const SizedBox(height: 20),

          // Wellness Check Card
          _buildWellnessCheckCard(context),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildConnectCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(AppRoutes.onboardDevice);
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connect',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to connect your Evolv28 device',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            'assets/images/dashboard_ble.svg',
            width: 40,
            height: 40,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWellnessProgramsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(AppRoutes.programs);
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wellness Programs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a session that suits your mind today.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/images/dashboard_lotus.svg',
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go(AppRoutes.insights);
      },
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track how often you\'ve used Evolv28',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(
              'assets/images/dashboard_insights.svg',
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessCheckCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8), // Light teal background
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wellness Check',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take a quick check-in to know where you stand',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    context.go(AppRoutes.wellnessCheck);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Take Assessment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            'assets/images/dashboard_assesment.svg',
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPicksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Top picks for you',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 16),

        // Horizontal scrollable feature icons
        SizedBox(
          height: 100,
          child: Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFeatureIcon(
                    'Better Sleep',
                    'assets/images/sleep_better.svg',
                    viewModel,
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureIcon(
                    'Improve Mood',
                    'assets/images/improve_mood.svg',
                    viewModel,
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureIcon(
                    'Improve Focus',
                    'assets/images/focus_better.svg',
                    viewModel,
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureIcon(
                    'Reduce Stress',
                    'assets/images/remove_stress.svg',
                    viewModel,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(String title, String iconPath, DashboardViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        viewModel.playProgram(title);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFB74D), // Light orange border
                width: 2,
              ),
            ),
            child: Center(
              child: SvgPicture.asset(iconPath, width: 30, height: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgramIcon(String? programId) {
    String iconPath;
    
    switch (programId) {
      case 'sleep_better':
        iconPath = 'assets/images/sleep_icon.svg';
        break;
      case 'improve_mood':
        iconPath = 'assets/images/improve_mood.svg';
        break;
      case 'focus_better':
        iconPath = 'assets/images/focus_better.svg';
        break;
      case 'remove_stress':
        iconPath = 'assets/images/remove_stress.svg';
        break;
      default:
        iconPath = 'assets/images/sleep_icon.svg';
    }
    
    return SvgPicture.asset(
      iconPath,
      width: 50,
      height: 50,
    );
  }

  String _getProgramTitle(String? programId) {
    switch (programId) {
      case 'sleep_better':
        return 'Better Sleep';
      case 'improve_mood':
        return 'Improve Mood';
      case 'focus_better':
        return 'Improve Focus';
      case 'remove_stress':
        return 'Reduce Stress';
      default:
        return 'Better Sleep';
    }
  }

  Widget _buildPlayerCard(BuildContext context, DashboardViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        // Navigate to programs view and show player screen
        // Pass the current playing program ID
        if (viewModel.currentPlayingProgramId != null) {
          ProgramsViewModel.setProgramIdFromDashboard(viewModel.currentPlayingProgramId!);
        }
        context.go(AppRoutes.programs);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF17961), // Reddish-orange background
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Program Icon
            _buildProgramIcon(viewModel.currentPlayingProgramId),
            const SizedBox(width: 16),
            
            // Now Playing Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Now playing',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    _getProgramTitle(viewModel.currentPlayingProgramId),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Play/Pause Button
            GestureDetector(
              onTap: () {
                // Handle play/pause
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
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
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    DashboardViewModel viewModel,
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
            _buildNavItem('assets/images/bottom_menu_home_selected.svg', 0, viewModel),
            _buildNavItem('assets/images/bottom_menu_programs.svg', 1, viewModel),
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
    DashboardViewModel viewModel,
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
