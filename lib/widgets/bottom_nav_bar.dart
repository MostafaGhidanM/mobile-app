import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isRTL;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.isRTL = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: isRTL ? 'الرئيسية' : 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2),
          label: isRTL ? 'الشحنات' : 'Shipments',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment),
          label: isRTL ? 'الطلبات' : 'Orders',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.more_horiz),
          label: isRTL ? 'المزيد' : 'More',
        ),
      ],
    );
  }
}

