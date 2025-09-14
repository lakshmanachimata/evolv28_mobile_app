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
  String _selectedTab = 'Weekly'; // Track selected tab
  String _selectedWeek = 'Week1'; // Track selected week for Monthly view
  
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab Navigation
          Container(
            color: const Color(0xFFA7E6D7),
            child: Row(
              children: [
                _buildTimelineTab('Weekly', _selectedTab == 'Weekly'),
                _buildTimelineTab('Monthly', _selectedTab == 'Monthly'),
                _buildTimelineTab('6 Months', _selectedTab == '6 Months'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Center(
            child: Text(
              _selectedTab == '6 Months' 
                ? 'Alleviate Stress (Timeline Last 6 Months - Until 01/08)'
                : _selectedTab == 'Monthly'
                  ? 'Alleviate Stress (Timeline This Month - $_selectedWeek)'
                  : 'Alleviate Stress ( Timeline This Week )',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6FC7B6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Week Selection for Monthly view
          if (_selectedTab == 'Monthly') ...[
            _buildWeekSelection(),
            const SizedBox(height: 16),
          ],
          // Chart
          SizedBox(height: 300, child: _buildStressTimelineChart(_selectedTab, _selectedWeek)),
        ],
      ),
    );
  }

  Widget _buildWeekSelection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildWeekOption('Week1'),
          _buildWeekOption('Week2'),
          _buildWeekOption('Week3'),
          _buildWeekOption('Week4'),
        ],
      ),
    );
  }

  Widget _buildWeekOption(String week) {
    final isSelected = _selectedWeek == week;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWeek = week;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6FC7B6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6FC7B6),
            width: 1,
          ),
        ),
        child: Text(
          week,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6FC7B6),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTab(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = title;
          });
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF3A6D6D),
                ),
              ),
              const SizedBox(height: 6),
              if (isSelected)
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFFF17961),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStressTimelineChart(String selectedTab, [String? selectedWeek]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: CustomPaint(
        painter: _StressTimelineChartPainterV2(selectedTab, selectedWeek),
        size: const Size(double.infinity, 220),
      ),
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

// Custom painter for stress timeline chart (updated to match image)
class _StressTimelineChartPainterV2 extends CustomPainter {
  final String selectedTab;
  final String? selectedWeek;
  
  _StressTimelineChartPainterV2(this.selectedTab, [this.selectedWeek]);
  
  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 36;
    final double bottomPadding = 32;
    final double topPadding = 12;
    final double chartHeight = size.height - bottomPadding - topPadding;
    final double chartWidth = size.width - leftPadding;
    
    // Data for different views
    final yLabels = selectedTab == '6 Months' 
        ? ['240h', '180h', '120h', '60h', '00h']
        : ['12h', '09h', '06h', '03h', '00h'];
    final ySteps = 4;
    
    List<String> xLabels;
    List<int> stressData;
    
    if (selectedTab == '6 Months') {
      xLabels = ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];
      stressData = [0, 0, 0, 75, 55, 0]; // Mar, Apr, May, Jun, Jul, Aug
    } else if (selectedTab == 'Monthly') {
      xLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      // Different data for each week
      switch (selectedWeek) {
        case 'Week1':
          stressData = [2, 4, 1, 3, 2, 1, 0]; // Week1 data
          break;
        case 'Week2':
          stressData = [3, 2, 5, 1, 4, 2, 1]; // Week2 data
          break;
        case 'Week3':
          stressData = [1, 3, 2, 4, 1, 3, 2]; // Week3 data
          break;
        case 'Week4':
          stressData = [4, 1, 3, 2, 5, 1, 3]; // Week4 data
          break;
        default:
          stressData = [2, 4, 1, 3, 2, 1, 0]; // Default Week1
      }
    } else {
      xLabels = ['TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN', 'MON'];
      stressData = [3, 0, 3, 0, 0, 0, 0]; // Weekly data
    }

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final barPaint = Paint()
      ..color = const Color(0xFF6FC7B6)
      ..style = PaintingStyle.fill;

    // Draw horizontal grid lines and y-axis labels
    for (int i = 0; i <= ySteps; i++) {
      final y = topPadding + (i / ySteps) * chartHeight;
      // Dotted line
      double dashWidth = 6, dashSpace = 6, startX = leftPadding;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset((startX + dashWidth).clamp(0, size.width), y),
          gridPaint,
        );
        startX += dashWidth + dashSpace;
      }
      // Y label
      final textSpan = TextSpan(
        text: yLabels[i],
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(leftPadding - tp.width - 8, y - tp.height / 2));
    }

    // Draw bars
    final barWidth = 18.0;
    final maxValue = selectedTab == '6 Months' ? 240.0 : 12.0;
    
    for (int i = 0; i < stressData.length; i++) {
      if (stressData[i] > 0) {
        final x = leftPadding + (i + 0.5) * (chartWidth / stressData.length);
        final barHeight = (stressData[i] / maxValue) * chartHeight;
        final barRect = Rect.fromLTWH(
          x - barWidth / 2,
          topPadding + chartHeight - barHeight,
          barWidth,
          barHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(6)),
          barPaint,
        );
      } else if (selectedTab == '6 Months' && stressData[i] == 0) {
        // Draw minimal horizontal dash for months with no data
        final x = leftPadding + (i + 0.5) * (chartWidth / stressData.length);
        final dashWidth = 8.0;
        
        final dashPaint = Paint()
          ..color = const Color(0xFF6FC7B6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        
        canvas.drawLine(
          Offset(x - dashWidth / 2, topPadding + chartHeight - 2),
          Offset(x + dashWidth / 2, topPadding + chartHeight - 2),
          dashPaint,
        );
      }
    }

    // Draw x-axis labels
    for (int i = 0; i < xLabels.length; i++) {
      final x = leftPadding + (i + 0.5) * (chartWidth / stressData.length);
      final textSpan = TextSpan(
        text: xLabels[i],
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      canvas.save();
      canvas.translate(x, topPadding + chartHeight + 8 + tp.height / 2);
      canvas.rotate(-0.3);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
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
