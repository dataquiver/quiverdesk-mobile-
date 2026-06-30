class ApiConfig {
  // Local network testing — IIS-hosted ASP.NET Core on laptop over Wi-Fi
  // Endpoints in ApiEndpoints already include the /api prefix, so baseUrl has none.
  static const String devBaseUrl  = 'http://192.168.1.11:7080';
  static const String prodBaseUrl = 'https://api.quiverdesk.com';

  static const bool isProduction = false;

  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
}
