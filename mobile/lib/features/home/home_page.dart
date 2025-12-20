import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../review_screen.dart';
import '../../upload.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_display_page.dart';
import '../review/received_review_list_page.dart';
import 'widgets/work_swipe_deck.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _index = 0;
  static const double _navBarHeight = 80;

  void _handleLogout() {
    ref.read(authControllerProvider.notifier).logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final titles = <String>['ホーム', 'レビューする', '投稿', '受信レビュー', 'プロフィール'];

    final body = <Widget>[
      const WorkSwipeDeck(),
      const ReviewListScreen(),
      const UploadArtworkPage(),
      const ReceivedReviewListPage(),
      ProfileDisplayPage(onLogout: _handleLogout),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(titles[_index]),
      ),
      body: SafeArea(
        child: IndexedStack(index: _index, children: body),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        height: _navBarHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: _NavBarStyle.indicatorColor,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'レビューする',
          ),
          NavigationDestination(
            icon: _PostNavIcon(isSelected: false),
            selectedIcon: _PostNavIcon(isSelected: true),
            label: '投稿',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: '受信レビュー',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}

class _PostNavIcon extends StatelessWidget {
  const _PostNavIcon({required this.isSelected});

  final bool isSelected;
  static const double _iconSize = 30;
  static const double _buttonSize = 52;
  static const double _liftOffset = -10;
  static const double _borderOpacity = 0.2;
  static const double _shadowOpacity = 0.15;
  static const double _shadowBlur = 12;
  static const double _shadowOffsetY = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillColor =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.surface;
    final iconColor =
        isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

    return Transform.translate(
      offset: const Offset(0, _liftOffset),
      child: Semantics(
        label: '投稿',
        selected: isSelected,
        button: true,
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(_borderOpacity),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_shadowOpacity),
                blurRadius: _shadowBlur,
                offset: const Offset(0, _shadowOffsetY),
              ),
            ],
          ),
          child: Icon(Icons.add, size: _iconSize, color: iconColor),
        ),
      ),
    );
  }
}

class _NavBarStyle {
  const _NavBarStyle._();

  static const Color indicatorColor = Color(0xFFEDE3FF);
}
