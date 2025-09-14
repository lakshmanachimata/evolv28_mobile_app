import 'package:flutter/material.dart';

class GoalInsightsViewModel extends ChangeNotifier {
  // Current resting heart rate
  int _restingHeartRate = 72;
  
  // Mindfulness timeline data for the week
  final List<DayData> _timelineData = [
    DayData(day: 'SUN', sessions: [
      SessionData(hour: 12, intensity: 0.8),
      SessionData(hour: 18, intensity: 0.9),
    ]),
    DayData(day: 'MON', sessions: [
      SessionData(hour: 6, intensity: 0.3),
      SessionData(hour: 9, intensity: 0.4),
      SessionData(hour: 15, intensity: 0.5),
    ]),
    DayData(day: 'TU', sessions: [
      SessionData(hour: 8, intensity: 0.4),
      SessionData(hour: 14, intensity: 0.6),
    ]),
    DayData(day: 'WED', sessions: [
      SessionData(hour: 7, intensity: 0.5),
      SessionData(hour: 12, intensity: 0.4),
      SessionData(hour: 17, intensity: 0.3),
    ]),
    DayData(day: 'THU', sessions: [
      SessionData(hour: 9, intensity: 0.6),
      SessionData(hour: 16, intensity: 0.4),
    ]),
    DayData(day: 'FRI', sessions: [
      SessionData(hour: 8, intensity: 0.5),
      SessionData(hour: 13, intensity: 0.3),
      SessionData(hour: 19, intensity: 0.4),
    ]),
  ];
  
  // Daily session cards data
  final List<SessionCardData> _sessionCards = [
    SessionCardData(
      date: 'Today',
      heartRate: 72,
      improvement: 5,
      duration: '02:45 hrs',
      sessionCount: 2,
      heartRateData: [70, 72, 74, 72, 71, 73, 72],
    ),
    SessionCardData(
      date: 'Yesterday',
      heartRate: 70,
      improvement: 7,
      duration: '02:15 hrs',
      sessionCount: 2,
      heartRateData: [68, 70, 72, 70, 69, 71, 70],
    ),
    SessionCardData(
      date: '02 Jan',
      year: '2024',
      heartRate: 71,
      improvement: 9,
      duration: '02:00 hrs',
      sessionCount: 2,
      heartRateData: [69, 71, 73, 71, 70, 72, 71],
    ),
  ];
  
  // Getters
  int get restingHeartRate => _restingHeartRate;
  List<DayData> get timelineData => _timelineData;
  List<SessionCardData> get sessionCards => _sessionCards;
  
  // Initialize goal insights
  Future<void> initialize() async {
    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }
  
  // Update resting heart rate
  void updateRestingHeartRate(int heartRate) {
    _restingHeartRate = heartRate;
    notifyListeners();
  }
  
  // Update timeline data
  void updateTimelineData(List<DayData> data) {
    _timelineData.clear();
    _timelineData.addAll(data);
    notifyListeners();
  }
  
  // Update session cards
  void updateSessionCards(List<SessionCardData> cards) {
    _sessionCards.clear();
    _sessionCards.addAll(cards);
    notifyListeners();
  }
}

class DayData {
  final String day;
  final List<SessionData> sessions;
  
  DayData({
    required this.day,
    required this.sessions,
  });
}

class SessionData {
  final int hour;
  final double intensity; // 0.0 to 1.0
  
  SessionData({
    required this.hour,
    required this.intensity,
  });
}

class SessionCardData {
  final String date;
  final String? year;
  final int heartRate;
  final int improvement;
  final String duration;
  final int sessionCount;
  final List<int> heartRateData;
  
  SessionCardData({
    required this.date,
    this.year,
    required this.heartRate,
    required this.improvement,
    required this.duration,
    required this.sessionCount,
    required this.heartRateData,
  });
}
