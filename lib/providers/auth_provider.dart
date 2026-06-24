import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _user = _supabaseService.client.auth.currentUser;
    if (_user != null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    _profile = await _supabaseService.getProfile(_user!.id);
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabaseService.signIn(email, password);
      _user = response.user;
      if (_user != null) {
        final profile = await _supabaseService.getProfile(_user!.id);
        if (profile != null && profile['is_delivery'] == true) {
          _profile = profile;
          _isLoading = false;
          notifyListeners();
          return null; // Success
        } else {
          await _supabaseService.signOut();
          _user = null;
          _isLoading = false;
          notifyListeners();
          return 'Access denied: Not a delivery partner.';
        }
      }
      _isLoading = false;
      notifyListeners();
      return 'Login failed.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    _user = null;
    _profile = null;
    notifyListeners();
  }
}
