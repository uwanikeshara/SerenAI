import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/audio/widgets/mini_player.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  final _tabs = [
    (route: '/home',     icon: Icons.home_rounded,      label: 'Home'),
    (route: '/scan',     icon: Icons.face_retouching_natural, label: 'Scan'),
    (route: '/content',  icon: Icons.library_books_rounded, label: 'Library'),
    (route: '/progress', icon: Icons.bar_chart_rounded,  label: 'Progress'),
    (route: '/profile',  icon: Icons.person_rounded,     label: 'Profile'),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/scan')) return 1;
    if (location.startsWith('/content')) return 2;
    if (location.startsWith('/progress')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentIndex != 0) {
          context.go('/home');
        }
      },
      child: Scaffold(
        extendBody: true,
        body: widget.child,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            _buildNavBar(context, currentIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, int currentIndex) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) => _buildItem(context, i, currentIndex)),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, int currentIndex) {
    final tab      = _tabs[index];
    final selected = currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              tab.icon,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              size: 22,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
