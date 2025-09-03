import 'package:flutter/material.dart';

extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  bool get isEmail {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(this);
  }

  bool get isPhone {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(this);
  }

  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }
}

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  bool get isKeyboardVisible => MediaQuery.of(this).viewInsets.bottom > 0;
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;
  bool get isLandscape => MediaQuery.of(this).orientation == Orientation.landscape;
  bool get isPortrait => MediaQuery.of(this).orientation == Orientation.portrait;
  bool get isTablet => MediaQuery.of(this).size.shortestSide >= 600;
  bool get isMobile => MediaQuery.of(this).size.shortestSide < 600;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  bool get isLightMode => Theme.of(this).brightness == Brightness.light;
  
  void showSnackBar(String message, {Color? backgroundColor, Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
  
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Theme.of(this).colorScheme.error);
  }
  
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }
  
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
  
  Future<T?> showAppDialog<T>(Widget child) {
    return showDialog<T>(
      context: this,
      builder: (context) => child,
    );
  }
  
  Future<T?> showAppBottomSheet<T>(Widget child) {
    return showModalBottomSheet<T>(
      context: this,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => child,
    );
  }
}

extension DateTimeExtensions on DateTime {
  String get formattedDate {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }
  
  String get formattedTime {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  String get formattedDateTime {
    return '$formattedDate $formattedTime';
  }
  
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
  
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }
}
