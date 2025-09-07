import 'package:flutter/material.dart';

class ProfileEditViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _firstName = 'Jane';
  String _lastName = 'Doe';
  String _emailOrMobile = 'jane.doe@example.com';
  String _selectedCountry = 'United States';
  DateTime? _dateOfBirth = DateTime(1990, 5, 15);

  // Countries list
  final List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'India',
    'Japan',
    'Brazil',
    'Mexico',
  ];

  // Getters
  bool get isLoading => _isLoading;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get emailOrMobile => _emailOrMobile;
  String get selectedCountry => _selectedCountry;
  DateTime? get dateOfBirth => _dateOfBirth;
  List<String> get countries => _countries;

  // Initialize the profile edit
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));

    _isLoading = false;
    notifyListeners();
  }

  // Update methods
  void updateFirstName(String value) {
    _firstName = value;
    notifyListeners();
  }

  void updateLastName(String value) {
    _lastName = value;
    notifyListeners();
  }

  void updateEmailOrMobile(String value) {
    _emailOrMobile = value;
    notifyListeners();
  }

  void updateCountry(String value) {
    _selectedCountry = value;
    notifyListeners();
  }

  void updateDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    notifyListeners();
  }

  // Get initials for avatar
  String getInitials() {
    final firstInitial = _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '';
    final lastInitial = _lastName.isNotEmpty ? _lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  // Change profile picture
  void changeProfilePicture() {
    print('Change profile picture');
    // Implement profile picture change logic here
  }

  // Save profile
  void saveProfile() {
    print('Save profile: $_firstName $_lastName');
    // Implement save profile logic here
  }
}
