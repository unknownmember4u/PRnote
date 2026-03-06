import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:prnote/features/home/screens/home_screen.dart';
import 'package:prnote/features/folders/screens/folders_screen.dart';
import 'package:prnote/features/settings/screens/settings_screen.dart';
import 'package:prnote/features/editor/screens/editor_screen.dart';
import 'package:prnote/features/splash/screens/splash_screen.dart';

/// Shell for bottom navigation (3 tabs: Home, Folders, Settings)
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    '/home',
    '/folders',
    '/settings',
  ];

  @override
  Widget build(BuildContext context) {
    // Sync index with current location
    final location = GoRouterState.of(context).uri.toString();
    var currentIndex = 0;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) {
        currentIndex = i;
        break;
      }
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          boxShadow: theme.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ]
              : null,
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index != currentIndex) {
              context.go(_tabs[index]);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.home_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.home_rounded, size: 24),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.folder_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.folder_rounded, size: 24),
              ),
              label: 'Folders',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.settings_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Icon(Icons.settings_rounded, size: 24),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

/// App router configuration
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/folders',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const FoldersScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const SettingsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/editor/new',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const EditorScreen(noteId: 'new'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            ),
      ),
    ),
    GoRoute(
      path: '/editor/:noteId',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: EditorScreen(noteId: state.pathParameters['noteId']!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            ),
      ),
    ),
  ],
);
