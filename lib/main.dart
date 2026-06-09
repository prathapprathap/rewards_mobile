import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/colors.dart';
import 'constants/app_design.dart';
import 'widgets/ui/rupi_ui.dart';
import 'providers/user_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/app_gate_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'screens/maintenance_screen.dart';
import 'screens/force_update_screen.dart';
import 'services/fcm_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background isolate — Firebase must be initialized here too.
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load cached colors before app starts to avoid "Green flash"
  final prefs = await SharedPreferences.getInstance();
  final cachedColor = prefs.getString('cached_primary_color');
  if (cachedColor != null) {
    AppColors.updateColors(cachedColor);
  }

  // Initialize Firebase (uses google-services.json on Android)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme();
    final headlineFont = GoogleFonts.plusJakartaSans();

    final textTheme = baseTextTheme.copyWith(
      displayLarge: headlineFont.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5),
      displayMedium: headlineFont.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.0),
      displaySmall: headlineFont.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineLarge: headlineFont.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: headlineFont.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: headlineFont.copyWith(fontWeight: FontWeight.w700),
      titleLarge: headlineFont.copyWith(fontWeight: FontWeight.w700),
      titleMedium: headlineFont.copyWith(fontWeight: FontWeight.w600),
      titleSmall: headlineFont.copyWith(fontWeight: FontWeight.w600),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => AppGateProvider()..check()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
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
              progressIndicatorTheme: ProgressIndicatorThemeData(
                color: AppColors.primary,
                circularTrackColor: AppColors.primaryFixed,
              ),
              splashColor: AppColors.primaryFixed.withValues(alpha: 0.4),
              highlightColor: AppColors.primaryFixed.withValues(alpha: 0.3),
              dividerTheme: DividerThemeData(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                thickness: 1,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: AppColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(borderRadius: AppDesign.brLg),
              ),
              bottomSheetTheme: BottomSheetThemeData(
                backgroundColor: AppColors.surfaceContainerLowest,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.onSurface,
                contentTextStyle: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: AppDesign.brMd),
              ),
              chipTheme: ChipThemeData(
                backgroundColor: AppColors.primaryFixed,
                labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, color: AppColors.primary),
                shape: StadiumBorder(
                    side: BorderSide(color: AppColors.primaryFixedDim)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                hintStyle: GoogleFonts.inter(color: AppColors.outline),
                border: OutlineInputBorder(
                  borderRadius: AppDesign.brMd,
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDesign.brMd,
                  borderSide: BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDesign.brMd,
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _fcmInitialized = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final gate = Provider.of<AppGateProvider>(context);

    // Only block on user+settings. Version/maintenance check runs in the
    // background — once it lands, the gate screens take over if needed.
    if (userProvider.isLoading || settingsProvider.isLoading) {
      return const _SplashScreen();
    }

    // Hard blocks (only enforced once the gate check has resolved).
    if (gate.loaded && gate.state == AppGateState.maintenance) {
      return const MaintenanceScreen();
    }
    if (gate.loaded && gate.state == AppGateState.forceUpdate) {
      return const ForceUpdateScreen();
    }

    // Logged-out path.
    if (userProvider.user == null) {
      return const LoginScreen();
    }

    // Logged-in: start FCM (once) and show the app.
    if (!_fcmInitialized) {
      _fcmInitialized = true;
      FcmService().init(userId: userProvider.user!.id);
    }

    final showOptional =
        gate.state == AppGateState.optionalUpdate && !gate.optionalDismissed;

    return Stack(
      children: [
        const MainLayout(),
        if (showOptional)
          Positioned(
            left: 12,
            right: 12,
            bottom: 90,
            child: _OptionalUpdateBanner(),
          ),
      ],
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.headerGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: AppDesign.brXl,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: ClipRRect(
                  borderRadius: AppDesign.brLg,
                  child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: AppDesign.floatShadow,
                      ),
                      child: const Center(
                        child: Text('₹',
                            style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF7A5300))),
                      ),
                    ),
                  ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Rupi Rewards',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Play • Earn • Win',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              const RupiLoader(size: 44),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionalUpdateBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gate = context.watch<AppGateProvider>();
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            const Icon(Icons.system_update_alt_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update available',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'v${gate.latestVersion} is out. Tap to update.',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                if (gate.updateUrl.isNotEmpty) {
                  final uri = Uri.tryParse(gate.updateUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('UPDATE'),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => context.read<AppGateProvider>().dismissOptional(),
            ),
          ],
        ),
      ),
    );
  }
}
