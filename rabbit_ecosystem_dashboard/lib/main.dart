import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'shared/widgets/error_boundary.dart';
import 'core/router/app_router.dart';

class RabbitEcosystemDashboard extends StatefulWidget {
  const RabbitEcosystemDashboard({super.key});

  @override
  State<RabbitEcosystemDashboard> createState() => _RabbitEcosystemDashboardState();
}

class _RabbitEcosystemDashboardState extends State<RabbitEcosystemDashboard> {
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _loadInitialScreen();
  }

  Future<void> _loadInitialScreen() async {
    final screen = await AppRouter.getInitialScreen();
    setState(() {
      _initialScreen = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialScreen == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Rabbit Ecosystem - Admin Dashboard',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'SA'),
      ],
      locale: const Locale('en', 'US'),

      // Error handling
      builder: (context, child) {
        return ErrorBoundary(
          child: child ?? const SizedBox.shrink(),
        );
      },

      // Routes
      initialRoute: '/',
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: _initialScreen,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure URL strategy for web
  usePathUrlStrategy();

  // Initialize dependency injection
  await setupInjection();

  // Initialize app configuration
  await AppConfig.initialize();

  runApp(const RabbitEcosystemDashboard());
}