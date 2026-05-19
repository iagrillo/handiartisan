import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/paystack_service.dart';

import 'providers/auth_provider.dart';
import 'providers/wallet_security_provider.dart';
import 'features/directory/directory_page.dart';
import 'features/directory/store_filter_page.dart';
import 'features/directory/register_type_page.dart';
import 'features/profile/submit_profile.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/artisan_register_page.dart';
import 'features/auth/password_reset_page.dart';
import 'features/jobs/jobs_page.dart';
import 'features/equipment/equipment_page.dart';
import 'features/services/services_page.dart';
import 'features/wallet/wallet_page.dart';
import 'features/utils/supabase.dart';
import 'features/directory/artisan_provider.dart';
import 'features/ui/app_theme.dart';
import 'theme/blue_onyx_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Route<dynamic>? _buildAuthCallbackRoute(RouteSettings settings) {
  final routeName = settings.name ?? '';
  final decodedRouteName = Uri.decodeFull(routeName).toLowerCase();
  final isAuthCallback = decodedRouteName.contains('code=') ||
      decodedRouteName.contains('access_token=') ||
      decodedRouteName.contains('refresh_token=') ||
      decodedRouteName.contains('token_hash=') ||
      decodedRouteName.contains('type=recovery') ||
      decodedRouteName.contains('login-callback');

  if (!isAuthCallback) return null;

  return MaterialPageRoute(
    settings: const RouteSettings(name: '/password-reset'),
    builder: (_) => PasswordResetPage(
        email: Supabase.instance.client.auth.currentUser?.email),
  );
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  String supabaseUrl;
  String supabaseKey;
  String paystackPublicKey;

  if (kIsWeb) {
    await dotenv.load(fileName: ".env");
  } else {
    await dotenv.load();
  }
  supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  paystackPublicKey = dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';

  debugPrint('Initializing Supabase with URL: $supabaseUrl');


  await SupabaseUtils.init(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => PasswordResetPage(email: data.session?.user.email),
        ),
      );
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WalletSecurityProvider>(
          create: (_) => WalletSecurityProvider(),
          update: (_, authProvider, walletSecurityProvider) {
            final provider = walletSecurityProvider ?? WalletSecurityProvider();
            provider.attachAuthProvider(authProvider);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ArtisanProvider()),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        title: 'HandiArtisan',
        theme: BlueOnyxTheme.lightTheme,
        darkTheme: BlueOnyxTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: DirectoryPage(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) => _buildAuthCallbackRoute(settings),
        onUnknownRoute: (settings) {
          final authCallbackRoute = _buildAuthCallbackRoute(settings);
          if (authCallbackRoute != null) {
            return authCallbackRoute;
          }

          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                    const SizedBox(height: 16),
                    Text('Page not found: ${settings.name}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/directory'),
                      child: const Text('Go Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        routes: {
          '/directory': (context) => DirectoryPage(),
          '/store': (context) => const StoreFilterPage(showAppBar: true),
          '/stores': (context) => const StoreFilterPage(showAppBar: true),
          '/equipment': (context) => const EquipmentPage(),
          '/profile': (context) => SubmitProfile(),
          '/login': (context) => LoginScreen(),
          '/password-reset': (context) => const PasswordResetPage(),
          '/register': (context) => const RegisterTypePage(),
          '/artisan-register': (context) => const ArtisanRegisterPage(),
          '/jobs': (context) => JobsPage(),
          '/services': (context) => const ServicesPage(),
          '/wallet': (context) => const WalletPage(),
          '/admin-dashboard': (context) => AdminDashboard(),
        },
      ),
    );
  }
}
