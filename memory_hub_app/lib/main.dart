import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/hub/hub_screen.dart';
import 'screens/memories/memories_list_screen.dart';
import 'screens/memories/memory_create_screen.dart';
import 'screens/memories/memory_detail_screen.dart';
import 'screens/vault/vault_list_screen.dart';
import 'screens/vault/vault_upload_screen.dart';
import 'screens/vault/vault_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/social/hubs_screen.dart';
import 'screens/social/user_search_screen.dart';
import 'screens/social/user_profile_view_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/collections/collections_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/activity/activity_feed_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Memory Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),  // Vibrant purple
          brightness: Brightness.light,
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFFEC4899),  // Pink accent
          tertiary: const Color(0xFF06B6D4),   // Cyan accent
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF7C3AED),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFEC4899),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 2, color: Color(0xFF7C3AED)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.dark,
          primary: const Color(0xFF9333EA),
          secondary: const Color(0xFFF472B6),
          tertiary: const Color(0xFF22D3EE),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF9333EA),
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF472B6),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1F2937),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(width: 2, color: Color(0xFF9333EA)),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/memories':
            return MaterialPageRoute(builder: (_) => const MemoriesListScreen());
          case '/memories/create':
            return MaterialPageRoute(builder: (_) => const MemoryCreateScreen());
          case '/memories/detail':
            final memoryId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => MemoryDetailScreen(memoryId: memoryId),
            );
          case '/vault':
            return MaterialPageRoute(builder: (_) => const VaultListScreen());
          case '/vault/upload':
            return MaterialPageRoute(builder: (_) => const VaultUploadScreen());
          case '/vault/detail':
            final fileId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => VaultDetailScreen(fileId: fileId),
            );
          case '/profile/edit':
            return MaterialPageRoute(builder: (_) => const EditProfileScreen());
          case '/profile/password':
            return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
          case '/profile/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/profile/view':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => UserProfileViewScreen(userId: userId),
            );
          case '/social/hubs':
            return MaterialPageRoute(builder: (_) => const HubsScreen());
          case '/social/search':
            return MaterialPageRoute(builder: (_) => const UserSearchScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
          case '/collections':
            return MaterialPageRoute(builder: (_) => const CollectionsScreen());
          case '/analytics':
            return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
          case '/activity':
            return MaterialPageRoute(builder: (_) => const ActivityFeedScreen());
          case '/admin':
            return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
          case '/admin/users':
            return MaterialPageRoute(builder: (_) => const AdminUsersScreen());
          default:
            return null;
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.memory,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'The Memory Hub',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HubScreen(),
    MemoriesListScreen(),
    VaultListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
