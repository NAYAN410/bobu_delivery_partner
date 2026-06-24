import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppColors {
  static const Color tomatoRed = Color(0xFFC8281A);
  static const Color cream = Color(0xFFFAF5EC);
}

class SupabaseConfig {
  static String get url => dotenv.get('SUPABASE_URL', fallback: '');
  static String get anonKey => dotenv.get('SUPABASE_ANON_KEY', fallback: '');
}
