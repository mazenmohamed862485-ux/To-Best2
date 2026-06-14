import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/routes.dart';
import '../../providers/app_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isOnline = ref.watch(isOnlineProvider);
    final unreadCount = ref.watch(unreadNotifCountProvider).valueOrNull ?? 0;
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';

    if (user == null) return const SizedBox.shrink();

    final location = GoRouterState.of(context).matchedLocation;

    final navItems = _buildNavItems(user.isAdminLike, isAr);
    final currentIndex = _computeIndex(location, navItems);

    return Scaffold(
      body: Column(
        children: [
          // ── Offline bar ─────────────────────
          if (!isOnline)
            Material(
              color: const Color(0xFFF44336),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        isAr ? 'أنت غير متصل — البيانات تُحفظ محلياً' : 'Offline — data saved locally',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          context.go(navItems[i].route);
        },
        destinations: navItems.map((item) {
          final isSelected = navItems.indexOf(item) == currentIndex;
          return NavigationDestination(
            icon: Badge(
              isLabelVisible: item.route == AppRoutes.home && unreadCount > 0,
              label: Text('$unreadCount'),
              child: Icon(item.icon),
            ),
            selectedIcon: Icon(item.selectedIcon ?? item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  List<_NavItem> _buildNavItems(bool isAdmin, bool isAr) {
    final items = [
      _NavItem(
        route: AppRoutes.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: isAr ? 'الرئيسية' : 'Home',
      ),
      _NavItem(
        route: AppRoutes.workout,
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        label: isAr ? 'التمرين' : 'Workout',
      ),
      _NavItem(
        route: AppRoutes.nutrition,
        icon: Icons.restaurant_outlined,
        selectedIcon: Icons.restaurant,
        label: isAr ? 'التغذية' : 'Nutrition',
      ),
      _NavItem(
        route: AppRoutes.attendance,
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        label: isAr ? 'الإلتزام' : 'Attendance',
      ),
      _NavItem(
        route: AppRoutes.progress,
        icon: Icons.trending_up_outlined,
        selectedIcon: Icons.trending_up,
        label: isAr ? 'التقدم' : 'Progress',
      ),
      _NavItem(
        route: AppRoutes.chat,
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        label: isAr ? 'الشات' : 'Chat',
      ),
      if (isAdmin)
        _NavItem(
          route: AppRoutes.admin,
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          label: isAr ? 'الإدارة' : 'Admin',
        ),
    ];
    return items;
  }

  int _computeIndex(String location, List<_NavItem> items) {
    for (int i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}
