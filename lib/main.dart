import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase with error handling
  try {
    await SupabaseService.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
    // Continue anyway - app will handle missing Supabase gracefully
  }
  
  // Run app with error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };
  
  runApp(const BloomApp());
}

class BloomApp extends StatelessWidget {
  const BloomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3ABA), // Primary color
          brightness: Brightness.light,
          primary: const Color(0xFF7C3ABA),
        ),
        textTheme: GoogleFonts.manropeTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFE9D5FF), // Light purple - matches splash screen gradient
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3ABA),
          brightness: Brightness.dark,
          primary: const Color(0xFF7C3ABA),
        ),
        textTheme: GoogleFonts.manropeTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFE9D5FF), // Light purple - matches splash screen gradient
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      builder: (context, child) {
        // Ensure splash screen background is visible immediately
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Color(0xFFFFF5F5), // Very light pink/peach
                Color(0xFFE9D5FF), // Light purple
              ],
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

