import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router_config.dart';

class QuestionnaireView extends StatefulWidget {
  const QuestionnaireView({super.key});

  @override
  State<QuestionnaireView> createState() => _QuestionnaireViewState();
}

class _QuestionnaireViewState extends State<QuestionnaireView> {
  List<int?> _answers = [
    1,
    2,
    null,
  ]; // Pre-filled answers for first two questions
  int _currentPage = 2; // Current page indicator
  int _totalPages = 6; // Total pages

  final List<Map<String, dynamic>> _questions = [
    {'question': 'I found it hard to wind down', 'answer': 1},
    {'question': 'I was aware of dryness of my mouth', 'answer': 2},
    {
      'question': 'I couldn\'t seem to experience any positive feeling at all',
      'answer': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E8), // Light teal-green
              Color(0xFFF0F8F0), // Very light green
              Colors.white, // White at bottom
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Rating Scale Explanation
                      _buildRatingScaleExplanation(),

                      const SizedBox(height: 30),

                      // Questionnaires Section
                      _buildQuestionnairesSection(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation
              _buildBottomNavigation(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E8), // Light blue-green background
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.go(AppRoutes.mindfulnessForm),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),

          const SizedBox(width: 16),

          // Title
          const Text(
            'Mindfulness',
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

  Widget _buildRatingScaleExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'The rating scale is as follows:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _buildScaleItem('0 - Not at all'),
        _buildScaleItem('1 - Sometimes'),
        _buildScaleItem('2 - Often'),
        _buildScaleItem('3 - Almost Always'),
      ],
    );
  }

  Widget _buildScaleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildQuestionnairesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Questionnaires',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),

        // Questions
        ...List.generate(_questions.length, (index) {
          return _buildQuestionItem(index);
        }),
      ],
    );
  }

  Widget _buildQuestionItem(int index) {
    final question = _questions[index];
    final currentAnswer = _answers[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        // Answer options
        Row(
          children: List.generate(4, (optionIndex) {
            final isSelected = currentAnswer == optionIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _answers[index] = optionIndex;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF07A60) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF07A60) : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    optionIndex.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        if (index < _questions.length - 1) const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => context.go(AppRoutes.mindfulnessForm),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.grey, size: 20),
            ),
          ),

          const Spacer(),

          // Page indicator
          Text(
            '$_currentPage/$_totalPages',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),

          const Spacer(),

          // Forward arrow
          GestureDetector(
            onTap: () => context.go(AppRoutes.mindHealthAnalysis),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF07A60),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
