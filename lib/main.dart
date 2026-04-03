import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_state.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'widgets/logo_widget.dart';
import 'core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SlydeApp());
}

class SlydeApp extends StatefulWidget {
  const SlydeApp({super.key});

  @override
  State<SlydeApp> createState() => _SlydeAppState();
}

class _SlydeAppState extends State<SlydeApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.load().then((_) => _appState.checkDailyStreak());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<AppState>.value(value: _appState)],
      child: MaterialApp(
        title: 'Slyde',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: T.bg,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
          colorScheme: const ColorScheme.dark(
            primary: T.classic,
            surface: T.surface,
          ),
        ),
        home: const _AppRouter(),
      ),
    );
  }
}

// ── Router: checks prefs then decides first screen ───────────────────────────

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboardingSeen') ?? false;
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!mounted) return;

    Widget dest;
    if (!seen) {
      await prefs.setBool('onboardingSeen', true);
      dest = const OnboardingScreen();
    } else if (!loggedIn) {
      dest = const LoginScreen();
    } else {
      dest = const HomeScreen();
    }

    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (ctx, a, sec) => dest,
        transitionsBuilder: (ctx, a, sec, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: AnimatedBg(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SlydeLogo(size: 100),
              const SizedBox(height: 48),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.white10,
                        color: T.gold,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'LOADING...',
                    style: T.display(18).copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
