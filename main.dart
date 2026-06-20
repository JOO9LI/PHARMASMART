import 'package:flutter/material.dart';
import 'package:pharmasmart/home.dart';
import 'package:pharmasmart/historique.dart';
import 'package:pharmasmart/stock.dart';
import 'package:pharmasmart/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pharmasmart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0891B2)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const Login(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    Home(),
    Stock(),
    Historique(),
  ]; // Liste des pages correspondant à chaque onglet de navigation
  final List<_NavItem> navItems = const [
    _NavItem(
      // Définition des éléments de navigation avec leurs icônes et labels
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    _NavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Stock',
    ),
    _NavItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history_rounded,
      label: 'Historique',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          // Assure que le contenu ne soit pas sous les éléments système
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ), // Ajoute un peu de padding pour l'esthétique
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final bool isActive = currentIndex == index;

                return GestureDetector(
                  // Permet de détecter les taps sur l'item
                  onTap: () => setState(() => currentIndex = index),
                  behavior: HitTestBehavior
                      .opaque, // Permet de détecter les taps même sur les zones transparentes
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves
                        .easeOut, // Animation fluide lors du changement d'état
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0891B2).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? const Color(0xFF0891B2)
                              : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves
                              .easeOut, //Animation fluide pour l'apparition du label
                          child: isActive
                              ? Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0891B2),
                                      ),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  }); //Classe pour représenter les éléments de navigation
}
