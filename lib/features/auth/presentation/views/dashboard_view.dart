import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/dashboard_viewmodel.dart';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/evolv_text.png',
                width: MediaQuery.of(context).size.width * 0.25,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey,
                  size: 20,
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
    return Container(
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
    );
  }

  Widget _buildInsightsCard(BuildContext context) {
    return Container(
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
                    print('Take Assessment tapped');
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
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFeatureIcon(
                'Better Sleep',
                'assets/images/sleep_better.svg',
              ),
              const SizedBox(width: 16),
              _buildFeatureIcon(
                'Improve Mood',
                'assets/images/improve_mood.svg',
              ),
              const SizedBox(width: 16),
              _buildFeatureIcon(
                'Improve Focus',
                'assets/images/focus_better.svg',
              ),
              const SizedBox(width: 16),
              _buildFeatureIcon(
                'Reduce Stress',
                'assets/images/remove_stress.svg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(String title, String iconPath) {
    return Column(
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
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(
              'Home',
              'assets/images/bottom_menu_home.svg',
              'assets/images/bottom_menu_home_selected.svg',
              0,
              viewModel,
            ),
            _buildBottomNavItem(
              'Programs',
              'assets/images/bottom_menu_programs.svg',
              'assets/images/bottom_menu_programs_selected.svg',
              1,
              viewModel,
            ),
            _buildBottomNavItem(
              'Device',
              'assets/images/bottom_menu_device.svg',
              'assets/images/bottom_menu_device_selected.svg',
              2,
              viewModel,
              hasNotification: true,
            ),
            _buildBottomNavItem(
              'Profile',
              'assets/images/bottom_menu_user.svg',
              'assets/images/bottom_menu_user_selected.svg',
              3,
              viewModel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    String label,
    String iconPath,
    String selectedIconPath,
    int index,
    DashboardViewModel viewModel, {
    bool hasNotification = false,
  }) {
    final isSelected = viewModel.selectedTabIndex == index;

    return GestureDetector(
      onTap: () => viewModel.onTabSelected(index, context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SvgPicture.asset(
                  isSelected ? selectedIconPath : iconPath,
                  width: 30,
                  height: 30,
                ),
                if (hasNotification && !isSelected)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB74D),
                  borderRadius: BorderRadius.all(Radius.circular(1)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
