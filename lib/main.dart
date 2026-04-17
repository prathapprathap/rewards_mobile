import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load cached colors before app starts to avoid "Green flash"
  final prefs = await SharedPreferences.getInstance();
  final cachedColor = prefs.getString('cached_primary_color');
  if (cachedColor != null) {
    AppColors.updateColors(cachedColor);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rewards typographic pairing:
    //  • Plus Jakarta Sans — display / headlines / brand moments
    //  • Inter             — body / labels / data
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headlineFont  = GoogleFonts.plusJakartaSans();

    final textTheme = baseTextTheme.copyWith(
      displayLarge:  headlineFont.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5),
      displayMedium: headlineFont.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.0),
      displaySmall:  headlineFont.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineLarge: headlineFont.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium:headlineFont.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: headlineFont.copyWith(fontWeight: FontWeight.w700),
      titleLarge:    headlineFont.copyWith(fontWeight: FontWeight.w700),
      titleMedium:   headlineFont.copyWith(fontWeight: FontWeight.w600),
      titleSmall:    headlineFont.copyWith(fontWeight: FontWeight.w600),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          // Re-build theme every time settings (including primary_color) are loaded
          return MaterialApp(
            title: 'Rupi Rewards',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ).copyWith(
                primary: AppColors.primary,
                primaryContainer: AppColors.primaryContainer,
                secondary: AppColors.secondary,
                secondaryContainer: AppColors.secondaryContainer,
                tertiary: AppColors.tertiary,
                tertiaryContainer: AppColors.tertiaryContainer,
                surface: AppColors.surface,
                onSurface: AppColors.onSurface,
                outline: AppColors.outline,
                outlineVariant: AppColors.outlineVariant,
              ),
              textTheme: textTheme,
              scaffoldBackgroundColor: AppColors.background,
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white.withOpacity(0.92),
                indicatorColor: AppColors.primary,
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: Colors.white);
                  }
                  return const IconThemeData(color: Color(0xFF94A3B8));
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final base = GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  );
                  if (states.contains(WidgetState.selected)) {
                    return base.copyWith(color: AppColors.primary);
                  }
                  return base.copyWith(color: const Color(0xFF94A3B8));
                }),
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (userProvider.isLoading || settingsProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (userProvider.user != null) {
      return const MainLayout();
    }

    return const LoginScreen();
  }
}
