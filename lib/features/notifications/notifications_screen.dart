import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/notification.dart' as models;
import '../../features/auth/auth_provider.dart';
import '../../localization/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  List<models.Notification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when user scrolls to 80% of the list
      if (_hasMore && !_isLoadingMore) {
        _loadNotifications();
      }
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _notifications = [];
        _hasMore = true;
      });
    }

    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      if (_page == 1) _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = authProvider.recyclingUnit?.phoneNumber;

      final response = await _notificationService.getNotifications(
        phoneNumber: phoneNumber,
        page: _page,
        pageSize: _pageSize,
      );

      if (response.isSuccess && response.data != null) {
        final newNotifications = response.data!.items;
        setState(() {
          if (_page == 1) {
            _notifications = newNotifications;
          } else {
            _notifications.addAll(newNotifications);
          }
          _hasMore = newNotifications.length >= _pageSize;
          _page++;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
        _loadUnreadCount();
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = response.error?.message ?? response.message ?? 'Failed to load notifications';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = authProvider.recyclingUnit?.phoneNumber;

      final response = await _notificationService.getUnreadCount(phoneNumber: phoneNumber);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _unreadCount = response.data!;
        });
      }
    } catch (e) {
      // Ignore errors for unread count
    }
  }

  Future<void> _markAsRead(models.Notification notification) async {
    if (notification.isRead) return;

    try {
      final response = await _notificationService.markAsRead(notification.id);
      if (response.isSuccess) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(isRead: true);
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          }
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = authProvider.recyclingUnit?.phoneNumber;

      final response = await _notificationService.markAllAsRead(phoneNumber: phoneNumber);

      if (response.isSuccess) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
          _unreadCount = 0;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  String _formatDate(DateTime date, AppLocalizations loc) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return loc.notificationsJustNow;
    } else if (difference.inMinutes < 60) {
      return loc.notificationsMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return loc.notificationsHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return loc.notificationsDaysAgo(difference.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'UNIT_APPROVED':
      case 'SHIPMENT_APPROVED':
      case 'APPROVED':
        return Colors.green;
      case 'UNIT_REJECTED':
      case 'SHIPMENT_REJECTED':
      case 'REJECTED':
        return Colors.red;
      case 'NEW_UNIT_REGISTRATION':
      case 'NEW_SHIPMENT_RECEIVED':
      case 'PROCESSED_SHIPMENT_SENT':
        return Colors.blue;
      case 'POINTS_ADDED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.notificationsTitle),
          actions: [
            if (_unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: _markAllAsRead,
                tooltip: localizations.notificationsMarkAllRead,
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadNotifications(refresh: true),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadNotifications(refresh: true),
                            child: Text(localizations.retry),
                          ),
                        ],
                      ),
                    )
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                localizations.notificationsNoNotifications,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _notifications.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _notifications.length) {
                              if (_isLoadingMore) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final notification = _notifications[index];
                            return Dismissible(
                              key: Key(notification.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.green,
                                child: const Icon(Icons.done, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                if (!notification.isRead) {
                                  _markAsRead(notification);
                                }
                              },
                              child: InkWell(
                                onTap: () {
                                  if (!notification.isRead) {
                                    _markAsRead(notification);
                                  }
                                },
                                child: Container(
                                  color: notification.isRead ? null : Colors.blue.shade50,
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6, right: 12),
                                        decoration: BoxDecoration(
                                          color: _getTypeColor(notification.type),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              localizations.getNotificationTitle(notification.type, notification.meta) ?? notification.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: notification.isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              localizations.getNotificationMessage(notification.type, notification.meta) ?? notification.message,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _formatDate(notification.createdAt, localizations),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}

