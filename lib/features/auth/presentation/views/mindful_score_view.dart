import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/mindful_score_viewmodel.dart';

class MindfulScoreView extends StatelessWidget {
  const MindfulScoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MindfulScoreViewModel(),
      child: const _MindfulScoreViewBody(),
    );
  }
}

class _MindfulScoreViewBody extends StatefulWidget {
  const _MindfulScoreViewBody();

  @override
  State<_MindfulScoreViewBody> createState() => _MindfulScoreViewBodyState();
}

class _MindfulScoreViewBodyState extends State<_MindfulScoreViewBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<MindfulScoreViewModel>(
        context,
        listen: false,
      );
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<MindfulScoreViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              // Background with waves
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
      child: CustomPaint(painter: WaveBackgroundPainter()),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    MindfulScoreViewModel viewModel,
  ) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Stress Alleviation Timeline
          _buildStressTimelineCard(viewModel),

          const SizedBox(height: 20),

          // Goals List
          Expanded(child: _buildGoalsList(viewModel)),
        ],
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
            onTap: () => context.go(AppRoutes.insights),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),

          const SizedBox(width: 16),

          // Title
          const Text(
            'MindFulScore',
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

  Widget _buildStressTimelineCard(MindfulScoreViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab Navigation
            Row(
              children: [
                Expanded(child: _buildTimelineTab('Weekly', true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTimelineTab('Monthly', false)),
                const SizedBox(width: 16),
                Expanded(child: _buildTimelineTab('6 Months', false)),
              ],
            ),

          const SizedBox(height: 20),

          // Title
          const Text(
            'Alleviate Stress (Timeline This Week)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4FC3F7),
            ),
          ),

          const SizedBox(height: 20),

          // Chart
          SizedBox(height: 200, child: _buildStressTimelineChart()),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4FC3F7) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF4FC3F7), 
          width: isSelected ? 0 : 1.5,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF4FC3F7).withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF4FC3F7),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF17961),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStressTimelineChart() {
    return Row(
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('12h', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('09h', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('06h', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('03h', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('00h', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),

        const SizedBox(width: 8),

        // Chart
        Expanded(
          child: CustomPaint(
            painter: StressTimelineChartPainter(),
            size: const Size(300, 200),
          ),
        ),

        const SizedBox(width: 8),

        // X-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Transform.rotate(
                  angle: -0.3,
                  child: const Text(
                    'TUE',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                Transform.rotate(
                  angle: -0.3,
                  child: const Text(
                    'WED',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                Transform.rotate(
                  angle: -0.3,
                  child: const Text(
                    'THU',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                Transform.rotate(
                  angle: -0.3,
                  child: const Text(
                    'FRI',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                Transform.rotate(
                  angle: -0.3,
                  child: const Text(
                    'SAT',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                Transform.rotate(
                  angle: -0.3,
                  child: const Text(
                    'SUN',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                Transform.rotate(
                  angle: -0.3,
                  child: const Text(
                    'MO',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalsList(MindfulScoreViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: viewModel.goals.length,
      itemBuilder: (context, index) {
        final goal = viewModel.goals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildGoalCard(goal),
        );
      },
    );
  }

  Widget _buildGoalCard(GoalData goal) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.goalInsights),
      child: Container(
        padding: const EdgeInsets.all(8.0),
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
            // Goal Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal Title
                  Text(
                    goal.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Progress Bar and Days Row
                  Row(
                    children: [
                      // Progress Bar
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: goal.progressPercentage,
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

                      // Days completed
                      Text(
                        '${goal.daysCompleted} days',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Goal Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF17961), width: 2),
              ),
              child: Center(
                child: goal.iconPath.endsWith('.svg')
                    ? SvgPicture.asset(goal.iconPath, width: 30, height: 30)
                    : Image.asset(goal.iconPath, width: 30, height: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for stress timeline chart
class StressTimelineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw background grid lines
    paint.color = Colors.grey.shade200;
    paint.strokeWidth = 0.5;

    // Horizontal grid lines (hour markers)
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical grid lines (month markers)
    for (int i = 0; i <= 6; i++) {
      final x = (i / 6) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Stress alleviation data for this week (TUE-MO)
    final stressData = [
      3, // TUE - 3 hours
      0, // WED - no data
      3, // THU - 3 hours
      0, // FRI - no data
      0, // SAT - no data
      0, // SUN - no data
      0, // MO - no data
    ];

    // Draw bars for each month
    paint.color = const Color(0xFF4FC3F7);
    paint.style = PaintingStyle.fill;

    for (int i = 0; i < stressData.length; i++) {
      if (stressData[i] > 0) {
        final x = (i / (stressData.length - 1)) * size.width;
        final barWidth = size.width / stressData.length * 0.6;
        final barHeight =
            (stressData[i] / 12) * size.height; // Normalize to 12h max

        // Draw vertical bar
        canvas.drawRect(
          Rect.fromLTWH(
            x - barWidth / 2,
            size.height - barHeight,
            barWidth,
            barHeight,
          ),
          paint,
        );
      } else {
        // Draw minimal horizontal dash for months with no data
        final x = (i / (stressData.length - 1)) * size.width;
        final dashWidth = size.width / stressData.length * 0.3;

        paint.strokeWidth = 2;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x - dashWidth / 2, size.height - 2),
          Offset(x + dashWidth / 2, size.height - 2),
          paint,
        );

        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for wave background
class WaveBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Create wave path
    final path = Path();

    // Start from top
    path.moveTo(0, size.height * 0.3);

    // Create wave curves
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.4,
      size.width,
      size.height * 0.3,
    );

    // Continue to bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Fill with light mint green
    paint.color = const Color(0xFFE8F5E8);
    canvas.drawPath(path, paint);

    // Add second wave for more depth
    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.4,
      size.width * 0.6,
      size.height * 0.5,
    );
    path2.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.6,
      size.width,
      size.height * 0.5,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    // Fill with slightly darker green
    paint.color = const Color(0xFFD4F1D4);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
