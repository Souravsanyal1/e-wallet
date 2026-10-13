abstract final class AppConfig {
  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String authDomain = String.fromEnvironment('AUTH_DOMAIN', defaultValue: 'elitechat.app');
  static const String walletProjectId = String.fromEnvironment('WALLET_PROJECT_ID', defaultValue: '');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-supabase');
}
