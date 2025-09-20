import 'package:flutter/material.dart';

class HelpViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _selectedProblemType = 'Device';
  final TextEditingController _messageController = TextEditingController();

  // Problem types
  final List<String> _problemTypes = [
    'Device',
    'App',
    'Account',
    'Billing',
    'Technical',
    'Other',
  ];

  // Getters
  bool get isLoading => _isLoading;
  String get selectedProblemType => _selectedProblemType;
  List<String> get problemTypes => _problemTypes;
  TextEditingController get messageController => _messageController;

  // Initialize the help
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  // Update problem type
  void updateProblemType(String value) {
    _selectedProblemType = value;
    notifyListeners();
  }

  // Submit report
  void submitReport() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    
    // Implement report submission logic here
    
    // Clear form after submission
    _messageController.clear();
    _selectedProblemType = 'Device';
    notifyListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
