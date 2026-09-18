import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'config/supabase_config.dart';
import 'services/ad_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // ── Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080D08),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Initialiser Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // ── Initialiser AdMob
  await AdService.initialize();

  runApp(const PronoXpertApp());
}

class PronoXpertApp extends StatelessWidget {
  const PronoXpertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── Infos app
      title: 'PronoXpert',
      debugShowCheckedModeBanner: false,

      // ── Thème global
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF080D08),

        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF00E664),
          secondary: Color(0xFF00B84D),
          surface:   Color(0xFF111911),
          error:     Color(0xFFFF4444),
        ),

        // Splash & highlight invisibles (évite les éclats blancs au tap)
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111911),
          foregroundColor: Color(0xFFE8F5E8),
          elevation: 0,
          centerTitle: true,
        ),

        // CircularProgressIndicator par défaut en vert
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF00E664),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E2E1E),
          thickness: 1,
        ),
      ),

      // ── Point d'entrée : SplashScreen
      home: const SplashScreen(),
    );
  }
}