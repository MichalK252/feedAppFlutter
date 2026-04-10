import 'package:flutter/material.dart';
import 'package:nav_bars/screens/main_screen.dart';
import 'package:nav_bars/screens/profile_screen.dart';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:nav_bars/l10n/app_localizations.dart';

import 'package:nav_bars/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int currentPageIndex = 0;
  late final PageController _pageController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentPageIndex);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: currentPageIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
    _tabController.animateTo(index);
  }

  void _onNavTap(int index) {
    setState(() => currentPageIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [Icons.person_outline, Icons.home, Icons.settings],
        activeIndex: currentPageIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        onTap: _onNavTap,
        activeColor: Colors.blue,
        inactiveColor: Colors.grey,
      ),

      appBar: AppBar(title: Text(AppLocalizations.of(context)!.homeScreenTitle)),

      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: <Widget>[
          const ProfileScreen(),
          const MainScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
