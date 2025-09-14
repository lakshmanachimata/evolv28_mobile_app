import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/goal_insights_viewmodel.dart';

class GoalInsightsView extends StatelessWidget {
  const GoalInsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GoalInsightsViewModel(),
      child: const _GoalInsightsViewBody(),
    );
  }
}

class _GoalInsightsViewBody extends StatefulWidget {
  const _GoalInsightsViewBody();

  @override
  State<_GoalInsightsViewBody> createState() => _GoalInsightsViewBodyState();
}

class _GoalInsightsViewBodyState extends State<_GoalInsightsViewBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<GoalInsightsViewModel>(
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
      body: Consumer<GoalInsightsViewModel>(
        builder: (context, viewModel, child) {
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        _buildMindfulnessTimelineCard(viewModel),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 16, bottom: 0),
                          itemCount: viewModel.sessionCards.length,
                          itemBuilder: (context, index) {
                            return _buildSessionCard(
                              viewModel.sessionCards[index],
                              index,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomNavBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final restingHeartRate = Provider.of<GoalInsightsViewModel>(
      context,
      listen: false,
    ).restingHeartRate;
    return Container(
      color: const Color(0xFF6FC7B6),
      padding: const EdgeInsets.only(top: 36, left: 0, right: 0, bottom: 24),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => context.go(AppRoutes.mindfulScore),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      restingHeartRate.toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6FC7B6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Resting Heart Rate',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMindfulnessTimelineCard(GoalInsightsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000), // 0.05 opacity black
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 0),
          const Center(
            child: Text(
              'Mindfulness Timeline (This Week)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6FC7B6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 140, child: _MindfulnessTimelineChart()),
        ],
      ),
    );
  }

  Widget _buildSessionCard(SessionCardData card, int index) {
    String dateLabel = card.date;
    if (card.year != null && card.year!.isNotEmpty) {
      dateLabel = "${card.date} ${card.year}";
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D000000), // 0.05 opacity black
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Date and bpm
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16,
                top: 16,
                bottom: 16,
                right: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${card.heartRate} bpm resting',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 28,
                    child: MiniLineChart(card.heartRateData),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sleep Better Rate Improved by ${card.improvement}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Right: Duration and Sessions
          Container(
            width: 90,
            height: 80,
            margin: const EdgeInsets.only(right: 12, left: 0),
            decoration: BoxDecoration(
              color: const Color(0xFF6FC7B6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.duration,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${card.sessionCount} Sessions',
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(Icons.home, true),
          _buildNavBarItem(Icons.article_outlined, false),
          _buildNavBarItem(Icons.show_chart, false),
          _buildNavBarItem(Icons.person_outline, false),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(IconData icon, bool selected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: selected ? const Color(0xFF6FC7B6) : Colors.grey,
          size: 28,
        ),
        if (selected)
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF6FC7B6),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

// --- Custom Timeline Chart ---
class _MindfulnessTimelineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Example data: first 3 days have red bars, rest are gray
    final bars = [18, 12, 6, 0, 0];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y-axis
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '24',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6FC7B6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '18',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6FC7B6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '12',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6FC7B6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '06',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6FC7B6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '00',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6FC7B6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Bars
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final isRed = i < 3;
                  final barHeight = isRed ? (bars[i] * 4.0) : 24.0;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 12,
                        height: isRed ? barHeight : 24.0,
                        decoration: BoxDecoration(
                          color: isRed
                              ? const Color(0xFFF17961)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ['SUN', 'MON', 'TU', 'WED', 'THU', 'FRI', 'SAT'][i],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6FC7B6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Mini Line Chart for Session Cards ---
class MiniLineChart extends StatelessWidget {
  final List<int> data;
  const MiniLineChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MiniLineChartPainter(data),
      size: const Size(80, 28),
    );
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final List<int> data;
  _MiniLineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6FC7B6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // Draw background line
    final bgPath = Path();
    bgPath.moveTo(0, size.height / 2);
    bgPath.lineTo(size.width, size.height / 2);
    canvas.drawPath(bgPath, bgPaint);
    // Draw data line
    if (data.length < 2) return;
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() == 0 ? 1 : (maxVal - minVal).abs();
    final stepX = size.width / (data.length - 1);
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
