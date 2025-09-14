import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/insights_viewmodel.dart';

class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InsightsViewModel(),
      child: const _InsightsViewBody(),
    );
  }
}

class _InsightsViewBody extends StatefulWidget {
  const _InsightsViewBody();

  @override
  State<_InsightsViewBody> createState() => _InsightsViewBodyState();
}

class _InsightsViewBodyState extends State<_InsightsViewBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<InsightsViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E8), // Light teal background
      body: Consumer<InsightsViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // Background with landscape
              _buildBackground(),
              
              // Main content
              _buildMainContent(context, viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: LandscapePainter(),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, InsightsViewModel viewModel) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            const SizedBox(height: 20),
            
            // Statistics Cards
            _buildStatisticsCards(viewModel),
            
            const SizedBox(height: 30),
            
            // User Profile Section
            _buildUserProfile(viewModel),
            
            const SizedBox(height: 30),
            
            // Progress Tracker
            _buildProgressTracker(viewModel),
            
            const SizedBox(height: 30),
            
            // Mood Breakdown
            _buildMoodBreakdown(viewModel),
            
            const SizedBox(height: 30),
            
            // Mindfulness Scores
            _buildMindfulnessScores(viewModel),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
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
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          const Text(
            'Insights',
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

  Widget _buildStatisticsCards(InsightsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'assets/images/insights_muscle.svg',
                  '${viewModel.numberOfSessions}',
                  'Number of session',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'assets/images/insights_zap.svg',
                  '${viewModel.levelsAchieved}',
                  'Levels achieved',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottom row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'assets/images/insights_badge.svg',
                  '${viewModel.totalBadges}',
                  'Total badges',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'assets/images/insights_reward.svg',
                  '${viewModel.totalPoints}',
                  'Total Points',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String iconPath, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 32,
            height: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(InsightsViewModel viewModel) {
    return Column(
      children: [
        // Profile Picture
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF17961),
              width: 3,
            ),
          ),
          child: const CircleAvatar(
            radius: 47,
            backgroundColor: Color(0xFFF5F5F5),
            child: Icon(
              Icons.person,
              size: 50,
              color: Color(0xFFF17961),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // User Name
        Text(
          viewModel.userName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Join Date
        Text(
          'Evolving since ${viewModel.joinDate}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTracker(InsightsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          const Text(
            'Good job!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Arc Progress
          SizedBox(
            width: 120,
            height: 60,
            child: CustomPaint(
              painter: ArcProgressPainter(
                progress: viewModel.progressPercentage,
                color: const Color(0xFFF17961),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            '${viewModel.daysCompleted}/${viewModel.totalDays} Days',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${viewModel.remainingDays} more days to go',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBreakdown(InsightsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In last 28 days',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodItem('😍', 'Amazing', viewModel.moodBreakdown['Amazing']!),
              _buildMoodItem('😊', 'Good', viewModel.moodBreakdown['Good']!),
              _buildMoodItem('😐', 'Okay', viewModel.moodBreakdown['Okay']!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodItem(String emoji, String label, int percentage) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF17961),
                    width: 3,
                  ),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF17961)),
                ),
              ),
              // Emoji
              Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '$percentage%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 4),
        
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMindfulnessScores(InsightsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Mindfulness Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.mindfulScore),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFF17961),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          ...viewModel.mindfulnessScores.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildMindfulnessItem(entry.key, entry.value),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMindfulnessItem(String program, int days) {
    return Row(
      children: [
        Expanded(
          child: Text(
            program,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        
        Expanded(
          flex: 2,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: days / 30, // Assuming 30 days max
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF17961),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        Text(
          '$days days',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Program icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFF17961),
              width: 2,
            ),
          ),
          child: Center(
            child: program == 'Better Sleep'
                ? SvgPicture.asset(
                    'assets/images/sleep_icon.svg',
                    width: 20,
                    height: 20,
                  )
                : const Icon(
                    Icons.mood,
                    size: 20,
                    color: Color(0xFFF17961),
                  ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for landscape background
class LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw hills
    paint.color = const Color(0xFFB8E6B8);
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.5, size.width * 0.6, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.4, size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
    
    // Draw sun
    paint.color = const Color(0xFFF17961);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.3),
      30,
      paint,
    );
    
    // Draw birds (simplified)
    paint.color = Colors.black;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    
    // Left birds
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.25, size.height * 0.38),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.38),
      Offset(size.width * 0.3, size.height * 0.4),
      paint,
    );
    
    // Right birds
    canvas.drawLine(
      Offset(size.width * 0.7, size.height * 0.35),
      Offset(size.width * 0.75, size.height * 0.33),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.33),
      Offset(size.width * 0.8, size.height * 0.35),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for arc progress
class ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  ArcProgressPainter({
    required this.progress,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;
    
    // Background arc
    paint.color = Colors.grey.shade300;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159, // -180 degrees
      3.14159,  // 180 degrees
      false,
      paint,
    );
    
    // Progress arc
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159, // -180 degrees
      3.14159 * progress, // Progress percentage
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
