import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router_config.dart';
import '../viewmodels/get_started_viewmodel.dart';

class GetStartedView extends StatelessWidget {
  const GetStartedView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GetStartedViewModel(),
      child: const _GetStartedViewBody(),
    );
  }
}

class _GetStartedViewBody extends StatefulWidget {
  const _GetStartedViewBody();

  @override
  State<_GetStartedViewBody> createState() => _GetStartedViewBodyState();
}

class _GetStartedViewBodyState extends State<_GetStartedViewBody> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          _buildBackground(),

          // Main Content
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background Image
          Image.asset(
            'assets/images/shapes-background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // White overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Consumer<GetStartedViewModel>(
      builder: (context, viewModel, child) {
        return SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Chat Content Area
              Expanded(child: _buildChatContent(context, viewModel)),

              // Bottom Navigation
              _buildBottomNavigation(context, viewModel),
            ],
          ),
        );
      },
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
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          const Text(
            'Getting Started',
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

  Widget _buildChatContent(
    BuildContext context,
    GetStartedViewModel viewModel,
  ) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          // Decorative cloud shape with birds
          // _buildDecorativeCloud(),

          // const SizedBox(height: 40),

          // Chat bubbles for questions
          _buildQuestionBubbles(context, viewModel),

          const SizedBox(height: 20),

          // Continue Button (only show on last question)
          if (viewModel.currentQuestionIndex == viewModel.questions.length - 1)
            _buildContinueButton(context, viewModel),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDecorativeCloud() {
    return Container(
      height: 80,
      child: Stack(
        children: [
          // Cloud shape
          Positioned(
            left: 0,
            right: 0,
            top: 20,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), // Light blue
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Bird silhouettes
          Positioned(
            left: 20,
            top: 10,
            child: SvgPicture.asset(
              'assets/images/bird_silhouette.svg',
              width: 20,
              height: 20,
            ),
          ),
          Positioned(
            left: 60,
            top: 5,
            child: SvgPicture.asset(
              'assets/images/bird_silhouette.svg',
              width: 16,
              height: 16,
            ),
          ),
          Positioned(
            right: 30,
            top: 8,
            child: SvgPicture.asset(
              'assets/images/bird_silhouette.svg',
              width: 18,
              height: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBubbles(
    BuildContext context,
    GetStartedViewModel viewModel,
  ) {
    // Check if the last question was just answered
    final isLastQuestionAnswered =
        viewModel.currentQuestionIndex == viewModel.questions.length - 1 &&
        viewModel.selectedAnswers.containsKey(viewModel.questions.length - 1);

    // Scroll to bottom when last question is answered
    if (isLastQuestionAnswered) {
      _scrollToBottom();
    }

    return Column(
      children: List.generate(viewModel.currentQuestionIndex + 1, (index) {
        final question = viewModel.questions[index];
        final isCurrentQuestion = index == viewModel.currentQuestionIndex;

        return Column(
          children: [
            // Question bubble
            _buildQuestionBubble(question.question, index, viewModel),

            const SizedBox(height: 16),

            // Answer options - show all previous answers + current question options
            _buildAnswerOptions(
              context,
              viewModel,
              question,
              index,
              isCurrentQuestion,
            ),

            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }

  Widget _buildQuestionBubble(
    String question,
    int questionIndex,
    GetStartedViewModel viewModel,
  ) {
    final isAnswered = viewModel.selectedAnswers.containsKey(questionIndex);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: SvgPicture.asset(
              'assets/images/chat_qn_icon.svg',
              width: 30,
              height: 30,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Question bubble
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAnswered
                  ? Colors.transparent
                  : const Color(0xFFF17961), // Orange color or transparent
              borderRadius: BorderRadius.circular(20),
              border: isAnswered
                  ? Border.all(color: Colors.black, width: 1)
                  : null,
            ),
            child: Text(
              question,
              style: TextStyle(
                color: isAnswered ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerOptions(
    BuildContext context,
    GetStartedViewModel viewModel,
    QuestionData question,
    int questionIndex,
    bool isCurrentQuestion,
  ) {
    // Check if this question has been answered
    final isAnswered = viewModel.selectedAnswers.containsKey(questionIndex);

    // Display all options in a single horizontal row
    return Row(
      children: [
        // Answer options
        ...question.options.map((option) {
          final isSelected = viewModel.selectedAnswers[questionIndex] == option;
          final isPreviousQuestion = !isCurrentQuestion;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: isPreviousQuestion
                    ? null
                    : () => viewModel.selectAnswer(questionIndex, option),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF17A61) // Orange when selected
                        : Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF17A61)
                          : Colors.black,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),

        // Show user icon on the right when question is answered
        if (isAnswered)
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: SvgPicture.asset(
              'assets/images/get_started_user.svg',
              width: 30,
              height: 30,
            ),
          ),
      ],
    );
  }

  Widget _buildContinueButton(
    BuildContext context,
    GetStartedViewModel viewModel,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => viewModel.handleContinue(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF17961), // Orange color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'CONTINUE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    GetStartedViewModel viewModel,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(
              'Home',
              'assets/images/bottom_menu_home.svg',
              'assets/images/bottom_menu_home_selected.svg',
              0,
              viewModel,
            ),
            _buildBottomNavItem(
              'Programs',
              'assets/images/bottom_menu_programs.svg',
              'assets/images/bottom_menu_programs_selected.svg',
              1,
              viewModel,
            ),
            _buildBottomNavItem(
              'Device',
              'assets/images/bottom_menu_device.png',
              'assets/images/bottom_menu_device_selected.png',
              2,
              viewModel,
            ),
            _buildBottomNavItem(
              'Profile',
              'assets/images/bottom_menu_user.svg',
              'assets/images/bottom_menu_user_selected.svg',
              3,
              viewModel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    String label,
    String iconPath,
    String selectedIconPath,
    int index,
    GetStartedViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // Navigate to programs screen
          context.go(AppRoutes.programs);
        } else {
          viewModel.onTabSelected(index, context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                (iconPath.contains('bottom_menu_device') ||
                        selectedIconPath.contains('bottom_menu_device'))
                    ? Image.asset(
                        isSelected ? selectedIconPath : iconPath,
                        width: 50,
                        height: 50,
                      )
                    : SvgPicture.asset(
                        isSelected ? selectedIconPath : iconPath,
                        width: 30,
                        height: 30,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Data model for questions
class QuestionData {
  final String question;
  final List<String> options;

  QuestionData({required this.question, required this.options});
}
