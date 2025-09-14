import 'package:flutter/material.dart';

class MindfulScoreViewModel extends ChangeNotifier {
  // Goal data
  final List<GoalData> _goals = [
    GoalData(
      id: 'better_sleep',
      title: 'Better Sleep',
      daysCompleted: 12,
      totalDays: 20,
      icon: '😴',
      iconPath: 'assets/images/sleep_icon.svg',
    ),
    GoalData(
      id: 'improve_mood',
      title: 'Improve Mood',
      daysCompleted: 15,
      totalDays: 21,
      icon: '😊',
      iconPath: 'assets/images/improve_mood.svg',
    ),
    GoalData(
      id: 'improve_focus',
      title: 'Improve Focus',
      daysCompleted: 18,
      totalDays: 25,
      icon: '🎯',
      iconPath: 'assets/images/focus_better.svg',
    ),
    GoalData(
      id: 'reduce_anxiety',
      title: 'Reduce Anxiety',
      daysCompleted: 24,
      totalDays: 30,
      icon: '😌',
      iconPath: 'assets/images/reduced_anxiety.png',
    ),
    GoalData(
      id: 'remove_stress',
      title: 'Remove Stress',
      daysCompleted: 18,
      totalDays: 30,
      icon: '🧘',
      iconPath: 'assets/images/remove_stress.svg',
    ),
    GoalData(
      id: 'calm_mind',
      title: 'Calm Your Mind',
      daysCompleted: 16,
      totalDays: 23,
      icon: '🧠',
      iconPath: 'assets/images/calm_mind.svg',
    ),
  ];

  // Getters
  List<GoalData> get goals => _goals;

  // Initialize mindful score
  Future<void> initialize() async {
    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  // Update goal progress
  void updateGoalProgress(String goalId, int daysCompleted) {
    final goalIndex = _goals.indexWhere((goal) => goal.id == goalId);
    if (goalIndex != -1) {
      _goals[goalIndex] = _goals[goalIndex].copyWith(daysCompleted: daysCompleted);
      notifyListeners();
    }
  }

  // Get goal by ID
  GoalData? getGoalById(String goalId) {
    try {
      return _goals.firstWhere((goal) => goal.id == goalId);
    } catch (e) {
      return null;
    }
  }
}

class GoalData {
  final String id;
  final String title;
  final int daysCompleted;
  final int totalDays;
  final String icon;
  final String iconPath;

  GoalData({
    required this.id,
    required this.title,
    required this.daysCompleted,
    required this.totalDays,
    required this.icon,
    required this.iconPath,
  });

  // Calculate progress percentage
  double get progressPercentage => daysCompleted / totalDays;

  // Calculate remaining days
  int get remainingDays => totalDays - daysCompleted;

  // Copy with method for updates
  GoalData copyWith({
    String? id,
    String? title,
    int? daysCompleted,
    int? totalDays,
    String? icon,
    String? iconPath,
  }) {
    return GoalData(
      id: id ?? this.id,
      title: title ?? this.title,
      daysCompleted: daysCompleted ?? this.daysCompleted,
      totalDays: totalDays ?? this.totalDays,
      icon: icon ?? this.icon,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
