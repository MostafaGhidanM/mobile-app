import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isRTL;
  final String? homeLabel;
  final String? shipmentsLabel;
  final String? supplyRequestsLabel;
  final String? moreLabel;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.isRTL = false,
    this.homeLabel,
    this.shipmentsLabel,
    this.supplyRequestsLabel,
    this.moreLabel,
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
          label: homeLabel ?? (isRTL ? 'الرئيسية' : 'Home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2),
          label: shipmentsLabel ?? (isRTL ? 'الشحنات' : 'Shipments'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment),
          label: supplyRequestsLabel ?? (isRTL ? 'طلبات التوريد' : 'Supply Requests'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.more_horiz),
          label: moreLabel ?? (isRTL ? 'المزيد' : 'More'),
        ),
      ],
    );
  }
}

