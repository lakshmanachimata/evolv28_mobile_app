import 'package:flutter/material.dart';

class InsightsViewModel extends ChangeNotifier {
  // User statistics
  int _numberOfSessions = 84;
  int _levelsAchieved = 4;
  int _totalBadges = 4;
  int _totalPoints = 760;

  // User profile
  String _userName = 'Jai SriRam';
  String _joinDate = 'Feb 2023';

  // Progress tracking
  int _daysCompleted = 7;
  int _totalDays = 28;

  // Mood breakdown
  Map<String, int> _moodBreakdown = {'Amazing': 40, 'Good': 35, 'Okay': 25};

  // Mindfulness scores
  Map<String, int> _mindfulnessScores = {
    'Better Sleep': 18,
    'Improve Mood': 24,
  };

  // Getters
  int get numberOfSessions => _numberOfSessions;
  int get levelsAchieved => _levelsAchieved;
  int get totalBadges => _totalBadges;
  int get totalPoints => _totalPoints;
  String get userName => _userName;
  String get joinDate => _joinDate;
  int get daysCompleted => _daysCompleted;
  int get totalDays => _totalDays;
  Map<String, int> get moodBreakdown => _moodBreakdown;
  Map<String, int> get mindfulnessScores => _mindfulnessScores;

  // Calculate progress percentage
  double get progressPercentage => _daysCompleted / _totalDays;

  // Calculate remaining days
  int get remainingDays => _totalDays - _daysCompleted;

  // Initialize insights
  Future<void> initialize() async {
    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  // Update user statistics
  void updateStatistics({
    int? sessions,
    int? levels,
    int? badges,
    int? points,
  }) {
    if (sessions != null) _numberOfSessions = sessions;
    if (levels != null) _levelsAchieved = levels;
    if (badges != null) _totalBadges = badges;
    if (points != null) _totalPoints = points;
    notifyListeners();
  }

  // Update progress
  void updateProgress(int daysCompleted) {
    _daysCompleted = daysCompleted;
    notifyListeners();
  }

  // Update mood breakdown
  void updateMoodBreakdown(Map<String, int> breakdown) {
    _moodBreakdown = breakdown;
    notifyListeners();
  }

  // Update mindfulness scores
  void updateMindfulnessScores(Map<String, int> scores) {
    _mindfulnessScores = scores;
    notifyListeners();
  }
}
