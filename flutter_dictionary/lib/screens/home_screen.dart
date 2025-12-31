import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'dictionaries_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SearchScreen(),
    const DictionariesScreen(),
    const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D0D1A),
              const Color(0xFF1A0D1A),
            ],
          ),
        ),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          color: const Color(0xFF0D0D1A).withOpacity(0.95),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF00CCFF).withOpacity(0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search, color: Color(0xFF00CCFF)),
              label: 'Поиск',
            ),
            NavigationDestination(
              icon: Icon(Icons.book),
              selectedIcon: Icon(Icons.book, color: Color(0xFF00CCFF)),
              label: 'Словари',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_border),
              selectedIcon: Icon(Icons.star, color: Color(0xFF00CCFF)),
              label: 'Избранное',
            ),
          ],
        ),
      ),
    );
  }
}
