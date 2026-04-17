import 'package:flutter/foundation.dart';

class ApiConstants {
  // Adaptive Base URL
  static String get baseUrl {
    return 'https://rewards-backend-zkhh.onrender.com/api';
  }

  static String get loginEndpoint => '$baseUrl/users/google-login';
  static String get userProfileEndpoint => '$baseUrl/users';
  static String get offersEndpoint => '$baseUrl/admin/offers';
  static String get tasksEndpoint => '$baseUrl/admin/tasks';
}
