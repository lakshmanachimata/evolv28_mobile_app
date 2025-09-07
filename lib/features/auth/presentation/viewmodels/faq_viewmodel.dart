import 'package:flutter/material.dart';

class FAQViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  Set<String> _expandedItems = {};

  // FAQ data
  final List<FAQItem> _faqItems = [
    FAQItem(
      id: 'safety',
      question: 'Is evolv28 safer to use?',
      answer: 'Yes, evolv28 is designed with multiple safety mechanisms and has undergone extensive clinical testing. The device includes real-time monitoring, automatic shutoff features, and is FDA-approved for consumer use. All sessions are monitored and can be stopped immediately if needed.',
    ),
    FAQItem(
      id: 'languages',
      question: 'What are the languages available to access the app?',
      answer: 'The evolv28 app is currently available in English, Hindi, Arabic, and Spanish. We are continuously working to add more languages based on user demand and feedback.',
    ),
    FAQItem(
      id: 'usage',
      question: 'How often should I use evolv28?',
      answer: 'For optimal results, we recommend using evolv28 for 20-30 minutes daily. However, the frequency can be adjusted based on your personal needs and goals. Our app will provide personalized recommendations based on your progress.',
    ),
    FAQItem(
      id: 'battery',
      question: 'How long does the battery last?',
      answer: 'The evolv28 device battery lasts approximately 8-10 hours of continuous use. The device charges via USB-C and takes about 2 hours to fully charge from empty.',
    ),
    FAQItem(
      id: 'data',
      question: 'Is my data secure and private?',
      answer: 'Absolutely. We take your privacy seriously. All data is encrypted and stored securely. We never share your personal information with third parties without your explicit consent. You can read our full privacy policy in the app settings.',
    ),
    FAQItem(
      id: 'compatibility',
      question: 'What devices are compatible with evolv28?',
      answer: 'evolv28 is compatible with smartphones running iOS 12+ or Android 8+. The app is available for download from the App Store and Google Play Store.',
    ),
    FAQItem(
      id: 'support',
      question: 'How can I get technical support?',
      answer: 'You can reach our support team through the Help section in the app, email us at support@evolv28.com, or call our support line at +1 (555) 123-4567. Our team is available 24/7 to assist you.',
    ),
    FAQItem(
      id: 'warranty',
      question: 'What is the warranty policy?',
      answer: 'evolv28 comes with a 1-year manufacturer warranty covering defects in materials and workmanship. Extended warranty options are available for purchase. Please refer to our terms and conditions for complete warranty details.',
    ),
  ];

  // Getters
  bool get isLoading => _isLoading;
  Set<String> get expandedItems => _expandedItems;
  List<FAQItem> get faqItems => _faqItems;

  // Initialize the FAQ
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  // Toggle expansion of FAQ item
  void toggleExpansion(String itemId) {
    if (_expandedItems.contains(itemId)) {
      _expandedItems.remove(itemId);
    } else {
      _expandedItems.add(itemId);
    }
    notifyListeners();
  }
}

class FAQItem {
  final String id;
  final String question;
  final String answer;

  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
  });
}
