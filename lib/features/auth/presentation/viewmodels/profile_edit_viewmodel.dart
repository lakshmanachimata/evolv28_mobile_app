import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditViewModel extends ChangeNotifier {
  // State variables
  bool _isLoading = false;
  String _firstName = 'Jane';
  String _lastName = 'Doe';
  String _emailOrMobile = 'jane.doe@example.com';
  String _selectedCountry = 'United States';
  String _gender = '';
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
  String get gender => _gender;
  DateTime? get dateOfBirth => _dateOfBirth;
  List<String> get countries => _countries;

  // Initialize the profile edit
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Get user data
      final firstName = prefs.getString('user_first_name')?.trim() ?? '';
      final lastName = prefs.getString('user_last_name')?.trim() ?? '';
      final emailId = prefs.getString('user_email_id')?.trim() ?? '';
      final country = prefs.getString('user_country')?.trim() ?? '';
      final gender = prefs.getString('user_gender')?.trim() ?? '';
      final age = prefs.getString('user_age')?.trim() ?? '';
      
      // Set user data
      _firstName = firstName.isNotEmpty ? firstName : 'Jane';
      _lastName = lastName.isNotEmpty ? lastName : 'Doe';
      _emailOrMobile = emailId.isNotEmpty ? emailId : 'jane.doe@example.com';
      _selectedCountry = country.isNotEmpty ? country : 'United States';
      _gender = gender.isNotEmpty ? gender : '';
      
      // Parse age to date of birth if available
      if (age.isNotEmpty) {
        try {
          final currentYear = DateTime.now().year;
          final birthYear = currentYear - int.parse(age);
          _dateOfBirth = DateTime(birthYear, 1, 1); // Default to January 1st
        } catch (e) {
          print('🔐 ProfileEditViewModel: Error parsing age: $e');
          _dateOfBirth = DateTime(1990, 5, 15); // Default date
        }
      } else {
        _dateOfBirth = DateTime(1990, 5, 15); // Default date
      }
      
      print('🔐 ProfileEditViewModel: Loaded user data - FirstName: "$_firstName", LastName: "$_lastName", Email: "$_emailOrMobile", Country: "$_selectedCountry", Gender: "$gender", Age: "$age"');
      
    } catch (e) {
      print('🔐 ProfileEditViewModel: Error loading user data: $e');
      // Keep default values if loading fails
    }

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

  void updateGender(String value) {
    _gender = value;
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
