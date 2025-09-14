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
      final viewModel = Provider.of<GoalInsightsViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<GoalInsightsViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              // Header Section
              _buildHeader(context),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Resting Heart Rate Graph
                      _buildRestingHeartRateGraph(viewModel),
                      
                      const SizedBox(height: 20),
                      
                      // Mindfulness Timeline
                      _buildMindfulnessTimeline(viewModel),
                      
                      const SizedBox(height: 20),
                      
                      // Session Cards
                      _buildSessionCards(viewModel),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF4FC3F7), // Light teal
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.mindfulScore),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            
            // Heart Rate Display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Heart Rate Circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '72',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4FC3F7),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Resting Heart Rate Text
                    const Text(
                      'Resting Heart Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestingHeartRateGraph(GoalInsightsViewModel viewModel) {
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
          // Title
          const Text(
            'Resting Heart Rate (Today)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4FC3F7),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Graph
          SizedBox(
            height: 200,
            child: _buildHeartRateChart(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(GoalInsightsViewModel viewModel) {
    return Row(
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('90', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('80', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('70', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('60', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('50', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        
        const SizedBox(width: 8),
        
        // Chart
        Expanded(
          child: CustomPaint(
            painter: RestingHeartRateChartPainter(),
            size: const Size(300, 200),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // X-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('00', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('06', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('12', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('18', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('24', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMindfulnessTimeline(GoalInsightsViewModel viewModel) {
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
          // Title
          const Text(
            'Mindfulness Timeline (This Week)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4FC3F7),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Chart
          SizedBox(
            height: 200,
            child: _buildTimelineChart(viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart(GoalInsightsViewModel viewModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Y-axis labels
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('24', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('18', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('12', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('06', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('00', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        
        const SizedBox(width: 8),
        
        // Chart bars
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: viewModel.timelineData.map((dayData) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Bars for this day
                  SizedBox(
                    height: 150,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: dayData.sessions.map((session) {
                        final height = session.intensity * 30;
                        final color = session.intensity > 0.7 
                            ? const Color(0xFFF17961) 
                            : Colors.grey.shade300;
                        
                        return Container(
                          width: 8,
                          height: height,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Day label
                  Text(
                    dayData.day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCards(GoalInsightsViewModel viewModel) {
    return Column(
      children: viewModel.sessionCards.map((card) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
              // Left side - Date and Heart Rate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(
                      card.date,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    
                    if (card.year != null) ...[
                      Text(
                        card.year!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Heart Rate
                    Text(
                      '${card.heartRate} bpm resting',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Heart Rate Graph
                    SizedBox(
                      height: 30,
                      child: CustomPaint(
                        painter: HeartRateGraphPainter(card.heartRateData),
                        size: const Size(200, 30),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Improvement Text
                    Text(
                      'Sleep Better Rate Improved by ${card.improvement}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Right side - Session Info
              Container(
                width: 80,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC3F7),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    Text(
                      card.duration,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      '${card.sessionCount}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const Text(
                      'Sessions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Custom painter for resting heart rate chart
class RestingHeartRateChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw background grid lines
    paint.color = Colors.grey.shade200;
    paint.strokeWidth = 0.5;
    
    // Vertical grid lines (hourly)
    for (int i = 0; i <= 24; i++) {
      final x = (i / 24) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Heart rate data points (24-hour period)
    final heartRateData = [
      62, 61, 60, 59, 58, 57, 58, 60, 62, 65, 68, 70, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61
    ];
    
    // Draw main heart rate line
    paint.color = Colors.grey.shade400;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    
    final path = Path();
    for (int i = 0; i < heartRateData.length; i++) {
      final x = (i / (heartRateData.length - 1)) * size.width;
      final normalizedY = (90 - heartRateData[i]) / 40; // Normalize to 50-90 range
      final y = normalizedY * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw highlighted segment (14:00 to 17:00)
    paint.color = const Color(0xFF4FC3F7);
    paint.strokeWidth = 3;
    
    final highlightedPath = Path();
    final startHour = 14;
    final endHour = 17;
    
    for (int i = startHour; i <= endHour; i++) {
      final x = (i / (heartRateData.length - 1)) * size.width;
      final normalizedY = (90 - heartRateData[i]) / 40;
      final y = normalizedY * size.height;
      
      if (i == startHour) {
        highlightedPath.moveTo(x, y);
      } else {
        highlightedPath.lineTo(x, y);
      }
    }
    
    canvas.drawPath(highlightedPath, paint);
    
    // Draw circular markers at start and end of highlighted segment
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF4FC3F7);
    
    // Start marker (14:00)
    final startX = (startHour / (heartRateData.length - 1)) * size.width;
    final startY = ((90 - heartRateData[startHour]) / 40) * size.height;
    canvas.drawCircle(Offset(startX, startY), 4, paint);
    
    // End marker (17:00)
    final endX = (endHour / (heartRateData.length - 1)) * size.width;
    final endY = ((90 - heartRateData[endHour]) / 40) * size.height;
    canvas.drawCircle(Offset(endX, endY), 4, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom painter for heart rate graph
class HeartRateGraphPainter extends CustomPainter {
  final List<int> heartRateData;
  
  HeartRateGraphPainter(this.heartRateData);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    if (heartRateData.length < 2) return;
    
    final path = Path();
    final stepX = size.width / (heartRateData.length - 1);
    final minRate = heartRateData.reduce((a, b) => a < b ? a : b);
    final maxRate = heartRateData.reduce((a, b) => a > b ? a : b);
    final range = maxRate - minRate;
    
    for (int i = 0; i < heartRateData.length; i++) {
      final x = i * stepX;
      final normalizedY = range > 0 
          ? (heartRateData[i] - minRate) / range 
          : 0.5;
      final y = size.height - (normalizedY * size.height);
      
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
