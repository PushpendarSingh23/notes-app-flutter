class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User
  static const String profile = '/users/profile';

  // Notes
  static const String notes = '/notes';
  static String noteById(String id) => '/notes/$id';
  static String noteArchive(String id) => '/notes/$id/archive';
  static String notePin(String id) => '/notes/$id/pin';

  // Tasks
  static const String tasks = '/tasks';
  static String taskById(String id) => '/tasks/$id';
  static String taskStatus(String id) => '/tasks/$id/status';

  // Dashboard
  static const String dashboard = '/dashboard';
}
