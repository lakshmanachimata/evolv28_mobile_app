import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';
import '../views/get_started_view.dart';

class GetStartedViewModel extends ChangeNotifier {
  int _currentQuestionIndex = 0;
  Map<int, String> _selectedAnswers = {};
  int _selectedTabIndex = 0;

  // Questions data matching the image flow
  final List<QuestionData> questions = [
    QuestionData(
      question: "What are your work timings?",
      options: ["8 AM - 5 PM", "9 AM - 6 PM", "11 AM - 8 PM"],
    ),
    QuestionData(
      question: "How much is your travelling time everyday?",
      options: ["30-45 mins", "45-60 mins", "More than 60 mins"],
    ),
    QuestionData(
      question: "How much time do you spend on meetings everyday?",
      options: ["1-3 hours", "3-5 hours", "More than 5 hours"],
    ),
    QuestionData(
      question: "What time do you get to bed everyday?",
      options: ["8 PM - 9 PM", "9 PM - 10 PM", "10 PM - 11 PM"],
    ),
  ];

  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, String> get selectedAnswers => _selectedAnswers;
  int get selectedTabIndex => _selectedTabIndex;

  void selectAnswer(int questionIndex, String answer) {
    _selectedAnswers[questionIndex] = answer;
    
    // Move to next question if not the last one
    if (questionIndex == _currentQuestionIndex && _currentQuestionIndex < questions.length - 1) {
      _currentQuestionIndex++;
    }
    
    notifyListeners();
  }

  void onTabSelected(int index) {
    _selectedTabIndex = index;
    notifyListeners();
    
    // Handle navigation based on tab selection
    switch (index) {
      case 0: // Home
        // Already on home/get started screen
        break;
      case 1: // Programs
        // Navigate to programs screen - context will be passed from the view
        break;
      case 2: // Device
        // Navigate to device screen
        break;
      case 3: // Profile
        // Navigate to profile screen (implement when available)
        break;
    }
  }

  void handleContinue(BuildContext context) {
    // All questions answered, navigate to programs screen
    context.go(AppRoutes.programs);
  }

  bool get isAllQuestionsAnswered {
    return _selectedAnswers.length == questions.length;
  }

  String? getAnswerForQuestion(int questionIndex) {
    return _selectedAnswers[questionIndex];
  }
}
