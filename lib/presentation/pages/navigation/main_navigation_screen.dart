import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/settings/app_settings.dart';

import '../home/home_page.dart';
import '../favorites/favorites_page.dart';
import '../tickets/tickets_page.dart';
import '../profile/profile_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, pages.length - 1);
  }

  final pages = const [
    HomePage(),
    FavoritesPage(),
    TicketsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppSettings.language,
      builder: (context, language, child) {
        return Scaffold(
          body: pages[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFE53935),
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: AppStrings.t('home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.favorite_border),
                activeIcon: const Icon(Icons.favorite),
                label: AppStrings.t('favorites'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.confirmation_number_outlined),
                activeIcon: const Icon(Icons.confirmation_number),
                label: AppStrings.t('tickets'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: AppStrings.t('profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}