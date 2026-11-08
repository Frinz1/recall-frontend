/// Environment and Cloud API Configuration for Recall Mobile App.
class EnvConfig {
  EnvConfig._();

  /// Change this to your deployed cloud URL (e.g. on Render.com or Railway.app)
  /// Example: 'https://recall-backend-production.up.railway.app/api/v1'
  static const String productionApiUrl = 'https://recall-backend-one.vercel.app/api/v1';

  /// Android Emulator mapping for local development (10.0.2.2 routes to host localhost)
  static const String androidEmulatorApiUrl = 'http://10.0.2.2:5000/api/v1';

  /// Windows / macOS / Web localhost
  static const String desktopLocalApiUrl = 'http://localhost:5000/api/v1';

  /// Set to true to point to your live cloud backend
  static const bool useProductionCloud = true;

  static String get baseUrl {
    if (useProductionCloud) {
      return productionApiUrl;
    }
    return androidEmulatorApiUrl;
  }
}
