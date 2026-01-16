import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;
import 'core/theme/app_theme.dart';
import 'core/utils/constants.dart';
import 'localization/app_localizations.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/shipments/shipments_list_screen.dart';
import 'features/shipments/receive_shipment_screen.dart';
import 'features/shipments/send_processed_shipment_screen.dart';
import 'features/shipments/receive_processed_shipment_screen.dart';
import 'features/shipments/processed_shipments_list_screen.dart';
import 'features/senders/register_sender_screen.dart';
import 'features/cars/register_car_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/auth/register_unit_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'core/services/push_notification_service.dart';
import 'widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app
  runApp(const AppWithSplash());
}

class AppWithSplash extends StatefulWidget {
  const AppWithSplash({Key? key}) : super(key: key);

  @override
  State<AppWithSplash> createState() => _AppWithSplashState();
}

class _AppWithSplashState extends State<AppWithSplash> {
  bool _showSplash = true;

  void _onSplashComplete() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(onAnimationComplete: _onSplashComplete),
      );
    }
    return const MyApp();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Locale _locale = const Locale('ar'); // Default to Arabic

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedLocale();
    _initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check for notifications when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      PushNotificationService.checkOnAppResume();
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await PushNotificationService.initialize();
      // Foreground polling is handled internally by PushNotificationService
      // Also checks when app resumes from background
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _getSavedLocale();
    if (savedLocale != null) {
      setState(() {
        _locale = savedLocale;
      });
    }
  }

  Future<Locale?> _getSavedLocale() async {
    // Load from SharedPreferences if needed
    return null; // Default to Arabic
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
      ],
      child: MaterialApp.router(
        title: 'Alfa Green',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getLightTheme(isRTL: _locale.languageCode == 'ar'),
        locale: _locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
          Locale('ar', ''),
        ],
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';
    final isRegisterUnitRoute = state.matchedLocation == '/register-unit';

    // Allow access to registration screen without login
    if (isRegisterUnitRoute) {
      return null;
    }

    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }
    if (isLoggedIn && isLoginRoute) {
      return '/dashboard';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/shipments',
      builder: (context, state) => const ShipmentsListScreen(),
    ),
    GoRoute(
      path: '/shipments/receive',
      builder: (context, state) => const ReceiveShipmentScreen(),
    ),
    GoRoute(
      path: '/shipments/send-processed',
      builder: (context, state) => const SendProcessedShipmentScreen(),
    ),
    GoRoute(
      path: '/shipments/receive-processed',
      builder: (context, state) => const ReceiveProcessedShipmentScreen(),
    ),
    GoRoute(
      path: '/shipments/processed',
      builder: (context, state) => const ProcessedShipmentsListScreen(),
    ),
    GoRoute(
      path: '/senders/register',
      builder: (context, state) => const RegisterSenderScreen(),
    ),
    GoRoute(
      path: '/cars/register',
      builder: (context, state) => const RegisterCarScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/register-unit',
      builder: (context, state) => const RegisterUnitScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);

