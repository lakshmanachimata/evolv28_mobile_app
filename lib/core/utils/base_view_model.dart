import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  Future<void> executeWithLoading<T>(
    Future<T> Function() operation, {
    Function(T)? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      setLoading(true);
      clearError();
      
      final result = await operation();
      
      if (onSuccess != null) {
        onSuccess(result);
      }
    } catch (e) {
      final errorMessage = e.toString();
      setError(errorMessage);
      
      if (onError != null) {
        onError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  }


}
