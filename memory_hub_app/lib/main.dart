import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/api_config.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/password_reset_request_screen.dart';
import 'screens/auth/password_reset_confirm_screen.dart';
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
import 'screens/profile/settings_home_screen.dart';
import 'screens/profile/account_security_screen.dart';
import 'screens/profile/notifications_detail_screen.dart';
import 'screens/profile/personalization_screen.dart';
import 'screens/profile/support_legal_screen.dart';
import 'screens/social/hubs_screen.dart';
import 'screens/social/user_search_screen.dart';
import 'screens/social/user_profile_view_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/notifications/notification_detail_screen.dart';
import 'screens/collections/collections_screen.dart';
import 'screens/analytics/analytics_screen.dart';
import 'screens/activity/activity_feed_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_moderation_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/search/advanced_search_screen.dart';
import 'screens/tags/tags_screen.dart';
import 'screens/tags/tag_detail_screen.dart';
import 'screens/tags/tags_management_screen.dart';
import 'screens/stories/stories_screen.dart';
import 'screens/stories/create_story_screen.dart';
import 'screens/stories/story_viewer_screen.dart';
import 'screens/voice_notes/voice_notes_screen.dart';
import 'screens/voice_notes/create_voice_note_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/categories/category_detail_screen.dart';
import 'screens/reminders/reminders_screen.dart';
import 'screens/reminders/create_reminder_screen.dart';
import 'screens/export/export_screen.dart';
import 'screens/privacy/privacy_settings_screen.dart';
import 'screens/privacy/blocked_users_screen.dart';
import 'screens/places/places_screen.dart';
import 'screens/places/nearby_places_screen.dart';
import 'screens/places/place_detail_screen.dart';
import 'screens/places/create_place_screen.dart';
import 'screens/two_factor/two_factor_setup_screen.dart';
import 'screens/two_factor/two_factor_verify_screen.dart';
import 'screens/scheduled_posts/scheduled_posts_screen.dart';
import 'screens/scheduled_posts/create_scheduled_post_screen.dart';
import 'screens/templates/templates_screen.dart';
import 'screens/templates/template_editor_screen.dart';
import 'screens/comments/comments_screen.dart';
import 'screens/sharing/file_sharing_screen.dart';
import 'screens/sharing/shared_files_screen.dart';
import 'screens/sharing/qr_code_screen.dart';
import 'screens/sharing/share_management_screen.dart';
import 'screens/gdpr/consent_management_screen.dart';
import 'screens/gdpr/data_export_screen.dart';
import 'screens/gdpr/account_deletion_screen.dart';
import 'screens/reactions/reactions_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/family/family_hub_dashboard_screen.dart';
import 'screens/family/family_albums_screen.dart';
import 'screens/family/family_timeline_screen.dart';
import 'screens/family/family_calendar_screen.dart';
import 'screens/family/family_milestones_screen.dart';
import 'screens/family/family_recipes_screen.dart';
import 'screens/family/legacy_letters_screen.dart';
import 'screens/family/family_traditions_screen.dart';
import 'screens/family/parental_controls_screen.dart';
import 'screens/family/family_document_vault_screen.dart';
import 'screens/family/genealogy_tree_screen.dart';
import 'screens/family/health_records_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Hub',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
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
            return MaterialPageRoute(builder: (_) => const SettingsHomeScreen());
          case '/settings/old':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/settings/account-security':
            return MaterialPageRoute(builder: (_) => const AccountSecurityScreen());
          case '/settings/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsDetailScreen());
          case '/settings/personalization':
            return MaterialPageRoute(builder: (_) => const PersonalizationScreen());
          case '/settings/support':
            return MaterialPageRoute(builder: (_) => const SupportLegalScreen());
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
          case '/notifications/detail':
            final notificationId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => NotificationDetailScreen(notificationId: notificationId),
            );
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
          case '/search':
            return MaterialPageRoute(builder: (_) => const SearchScreen());
          case '/search/advanced':
            return MaterialPageRoute(builder: (_) => const AdvancedSearchScreen());
          case '/tags':
            return MaterialPageRoute(builder: (_) => const TagsScreen());
          case '/tags/detail':
            final tag = settings.arguments as String;
            return MaterialPageRoute(builder: (_) => TagDetailScreen(tag: tag));
          case '/tags/management':
            return MaterialPageRoute(builder: (_) => const TagsManagementScreen());
          case '/stories':
            return MaterialPageRoute(builder: (_) => const StoriesScreen());
          case '/stories/create':
            return MaterialPageRoute(builder: (_) => const CreateStoryScreen());
          case '/stories/view':
            final storyId = settings.arguments as String;
            return MaterialPageRoute(builder: (_) => StoryViewerScreen(storyId: storyId));
          case '/voice-notes':
            return MaterialPageRoute(builder: (_) => const VoiceNotesScreen());
          case '/voice-notes/create':
            return MaterialPageRoute(builder: (_) => const CreateVoiceNoteScreen());
          case '/categories':
            return MaterialPageRoute(builder: (_) => const CategoriesScreen());
          case '/categories/detail':
            final categoryId = settings.arguments as String;
            return MaterialPageRoute(builder: (_) => CategoryDetailScreen(categoryId: categoryId));
          case '/reminders':
            return MaterialPageRoute(builder: (_) => const RemindersScreen());
          case '/reminders/create':
            return MaterialPageRoute(builder: (_) => const CreateReminderScreen());
          case '/export':
            return MaterialPageRoute(builder: (_) => const ExportScreen());
          case '/privacy/settings':
            return MaterialPageRoute(builder: (_) => const PrivacySettingsScreen());
          case '/privacy/blocked':
            return MaterialPageRoute(builder: (_) => const BlockedUsersScreen());
          case '/places':
            return MaterialPageRoute(builder: (_) => const PlacesScreen());
          case '/places/nearby':
            return MaterialPageRoute(builder: (_) => const NearbyPlacesScreen());
          case '/places/detail':
            final placeId = settings.arguments as String;
            return MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: placeId));
          case '/places/create':
            return MaterialPageRoute(builder: (_) => const CreatePlaceScreen());
          case '/password-reset/request':
            return MaterialPageRoute(builder: (_) => const PasswordResetRequestScreen());
          case '/password-reset/confirm':
            final token = settings.arguments as String?;
            return MaterialPageRoute(builder: (_) => PasswordResetConfirmScreen(token: token));
          case '/admin/moderation':
            return MaterialPageRoute(builder: (_) => const AdminModerationScreen());
          case '/2fa/setup':
            return MaterialPageRoute(builder: (_) => const TwoFactorSetupScreen());
          case '/2fa/verify':
            return MaterialPageRoute(builder: (_) => const TwoFactorVerifyScreen());
          case '/scheduled-posts':
            return MaterialPageRoute(builder: (_) => const ScheduledPostsScreen());
          case '/scheduled-posts/create':
            return MaterialPageRoute(builder: (_) => const CreateScheduledPostScreen());
          case '/templates':
            return MaterialPageRoute(builder: (_) => const TemplatesScreen());
          case '/templates/create':
            return MaterialPageRoute(builder: (_) => const TemplateEditorScreen());
          case '/comments':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => CommentsScreen(
                targetId: args['targetId']!,
                targetType: args['targetType']!,
              ),
            );
          case '/sharing':
            return MaterialPageRoute(builder: (_) => const FileSharingScreen());
          case '/sharing/shared':
            return MaterialPageRoute(builder: (_) => const SharedFilesScreen());
          case '/sharing/management':
            return MaterialPageRoute(builder: (_) => const ShareManagementScreen());
          case '/sharing/qr-code':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => QRCodeScreen(
                shareUrl: args['shareUrl']!,
                title: args['title']!,
                description: args['description'],
              ),
            );
          case '/gdpr/consent':
            return MaterialPageRoute(builder: (_) => const ConsentManagementScreen());
          case '/gdpr/export':
            return MaterialPageRoute(builder: (_) => const DataExportScreen());
          case '/gdpr/delete':
            return MaterialPageRoute(builder: (_) => const AccountDeletionScreen());
          case '/reactions':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => ReactionsScreen(
                targetId: args['targetId']!,
                targetType: args['targetType']!,
              ),
            );
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/family':
            return MaterialPageRoute(builder: (_) => const FamilyHubDashboardScreen());
          case '/family/albums':
            return MaterialPageRoute(builder: (_) => const FamilyAlbumsScreen());
          case '/family/timeline':
            return MaterialPageRoute(builder: (_) => const FamilyTimelineScreen());
          case '/family/calendar':
            return MaterialPageRoute(builder: (_) => const FamilyCalendarScreen());
          case '/family/milestones':
            return MaterialPageRoute(builder: (_) => const FamilyMilestonesScreen());
          case '/family/recipes':
            return MaterialPageRoute(builder: (_) => const FamilyRecipesScreen());
          case '/family/letters':
            return MaterialPageRoute(builder: (_) => const LegacyLettersScreen());
          case '/family/traditions':
            return MaterialPageRoute(builder: (_) => const FamilyTraditionsScreen());
          case '/family/parental-controls':
            return MaterialPageRoute(builder: (_) => const ParentalControlsScreen());
          case '/family/vault':
            return MaterialPageRoute(builder: (_) => const FamilyDocumentVaultScreen());
          case '/family/genealogy':
            return MaterialPageRoute(builder: (_) => const GenealogyTreeScreen());
          case '/family/health':
            return MaterialPageRoute(builder: (_) => const HealthRecordsScreen());
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    try {
      // Debug: Log API configuration
      debugPrint('=== Memory Hub Startup Debug ===');
      debugPrint('API Config: ${ApiConfig.debugInfo}');
      debugPrint('Base URL: ${ApiConfig.baseUrl}');
      debugPrint('Environment: ${ApiConfig.currentEnvironment}');
      
      // Reduced delay for faster debugging
      await Future.delayed(const Duration(milliseconds: 1500));
      
      debugPrint('Checking authentication status...');
      final isLoggedIn = await _authService.isLoggedIn();
      debugPrint('Is logged in: $isLoggedIn');
      
      if (!mounted) {
        debugPrint('Widget not mounted, aborting navigation');
        return;
      }
      
      debugPrint('Navigating to ${isLoggedIn ? 'MainScreen' : 'LoginScreen'}');
      
      // Use Navigator.pushAndRemoveUntil for cleaner navigation
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? const MainScreen() : const LoginScreen(),
        ),
        (route) => false, // Remove all previous routes
      );
      
      debugPrint('Navigation completed successfully');
    } catch (e, stackTrace) {
      debugPrint('ERROR during _checkAuth: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Force navigation to login screen on error
      if (mounted) {
        try {
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          debugPrint('Emergency navigation to LoginScreen completed');
        } catch (navError) {
          debugPrint('CRITICAL: Navigation failed: $navError');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Memory Hub',
                    style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your Digital Legacy',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  late final List<Widget> _screens = [
    _buildErrorBoundary(0, const DashboardScreen()),
    _buildErrorBoundary(1, const FamilyHubDashboardScreen()),
    _buildErrorBoundary(2, const SocialTabScreen()),
    _buildErrorBoundary(3, const ProfileScreen()),
  ];

  Widget _buildErrorBoundary(int index, Widget child) {
    return ErrorBoundary(
      screenName: ['Home', 'Family', 'Social', 'Profile'][index],
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          height: 70,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.family_restroom_outlined),
              selectedIcon: Icon(Icons.family_restroom),
              label: 'Family',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Social',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class SocialTabScreen extends StatelessWidget {
  const SocialTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Social', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Hubs'),
              Tab(text: 'Discover'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ActivityFeedScreen(),
            HubsScreen(),
            UserSearchScreen(),
          ],
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String screenName;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.screenName,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = details.toString();
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error in ${widget.screenName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage.split('\n').first,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
