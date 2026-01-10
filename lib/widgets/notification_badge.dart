import 'package:flutter/material.dart';
import '../core/services/notification_service.dart';
import '../features/auth/auth_provider.dart';
import 'package:provider/provider.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Poll for unread count every 30 seconds
    _startPolling();
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadUnreadCount();
        _startPolling();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = authProvider.recyclingUnit?.phoneNumber;

      final response = await _notificationService.getUnreadCount(phoneNumber: phoneNumber);

      if (response.isSuccess && response.data != null) {
        if (mounted) {
          setState(() {
            _unreadCount = response.data!;
          });
        }
      }
    } catch (e) {
      // Ignore errors for unread count
      debugPrint('Failed to load unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

