import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/pending_screen.dart';
import '../../features/auth/screens/subscription_screen.dart';
import '../../features/auth/screens/first_run_wizard_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/workout/screens/workout_screen.dart';
import '../../features/workout/screens/session_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/nutrition/screens/food_search_screen.dart';
import '../../features/nutrition/screens/meal_plan_screen.dart';
import '../../features/attendance/screens/attendance_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/progress/screens/measurements_screen.dart';
import '../../features/progress/screens/progress_photos_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/admin/screens/user_detail_screen.dart';
import '../../features/admin/screens/subscription_requests_screen.dart';
import '../../features/admin/screens/ban_management_screen.dart';
import '../../features/admin/screens/promo_codes_screen.dart';
import '../../features/admin/screens/audit_log_screen.dart';
import '../../widgets/shell/main_shell.dart';
import '../../providers/app_providers.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pending = '/pending';
  static const String rejected = '/rejected';
  static const String subscription = '/subscription';
  static const String firstRunWizard = '/first-run';
  static const String home = '/home';
  static const String workout = '/workout';
  static const String session = '/session';
  static const String nutrition = '/nutrition';
  static const String foodSearch = '/food-search';
  static const String mealPlan = '/meal-plan';
  static const String attendance = '/attendance';
  static const String progress = '/progress';
  static const String measurements = '/measurements';
  static const String progressPhotos = '/progress-photos';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String admin = '/admin';
  static const String userDetail = '/admin/user';
  static const String subscriptionRequests = '/admin/subscriptions';
  static const String banManagement = '/admin/bans';
  static const String promoCodes = '/admin/promos';
  static const String auditLog = '/admin/audit';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final loc = state.matchedLocation;

      final authRoutes = [
        AppRoutes.login, AppRoutes.register,
        AppRoutes.forgotPassword, AppRoutes.splash,
      ];

      if (!isLoggedIn && !authRoutes.contains(loc)) {
        return AppRoutes.login;
      }
      if (isLoggedIn && authRoutes.contains(loc)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashView(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.pending,
        builder: (_, __) => const PendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, state) => SubscriptionScreen(
          isRenewal: state.uri.queryParameters['renewal'] == 'true',
        ),
      ),
      GoRoute(
        path: AppRoutes.firstRunWizard,
        builder: (_, __) => const FirstRunWizardScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.workout,
            builder: (_, __) => const WorkoutScreen(),
            routes: [
              GoRoute(
                path: 'session/:sessionName',
                builder: (_, state) => SessionScreen(
                  sessionName: state.pathParameters['sessionName'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.nutrition,
            builder: (_, __) => const NutritionScreen(),
            routes: [
              GoRoute(
                path: 'search',
                builder: (_, state) => FoodSearchScreen(
                  mealType: state.uri.queryParameters['meal'],
                ),
              ),
              GoRoute(
                path: 'plan',
                builder: (_, __) => const MealPlanScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.attendance,
            builder: (_, __) => const AttendanceScreen(),
          ),
          GoRoute(
            path: AppRoutes.progress,
            builder: (_, __) => const ProgressScreen(),
            routes: [
              GoRoute(
                path: 'measurements',
                builder: (_, __) => const MeasurementsScreen(),
              ),
              GoRoute(
                path: 'photos',
                builder: (_, __) => const ProgressPhotosScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.chat,
            builder: (_, state) => ChatScreen(
              roomId: state.uri.queryParameters['room'] ?? 'general',
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.admin,
            builder: (_, __) => const AdminScreen(),
            routes: [
              GoRoute(
                path: 'user/:uid',
                builder: (_, state) => UserDetailScreen(
                  uid: state.pathParameters['uid'] ?? '',
                ),
              ),
              GoRoute(
                path: 'subscriptions',
                builder: (_, __) => const SubscriptionRequestsScreen(),
              ),
              GoRoute(
                path: 'bans',
                builder: (_, __) => const BanManagementScreen(),
              ),
              GoRoute(
                path: 'promos',
                builder: (_, __) => const PromoCodesScreen(),
              ),
              GoRoute(
                path: 'audit',
                builder: (_, __) => const AuditLogScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Error: ${state.error}')),
    ),
  );
});

class SplashView extends ConsumerWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
