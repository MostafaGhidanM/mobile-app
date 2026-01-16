import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../features/auth/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/notification_badge.dart';
import '../../core/services/recycling_unit_service.dart';
import '../../core/models/recycling_unit.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RecyclingUnitService _recyclingUnitService = RecyclingUnitService();
  double? _credit;
  bool _loadingCredit = false;

  @override
  void initState() {
    super.initState();
    _loadCredit();
  }

  Future<void> _loadCredit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final unit = authProvider.recyclingUnit;

    // Load credit (stock) for PRESS units only
    // Credit is based on approved raw material shipments (1 kg = 1 credit)
    if (unit?.unitType == UnitType.press) {
      setState(() => _loadingCredit = true);
      try {
        final creditResponse = await _recyclingUnitService.getCredit();
        if (creditResponse.isSuccess && creditResponse.data != null) {
          final creditValue = creditResponse.data!['credit'];
          setState(() {
            _credit = creditValue != null ? (creditValue as num).toDouble() : 0.0;
            _loadingCredit = false;
          });
        } else {
          // If API call fails, set credit to 0
          setState(() {
            _credit = 0.0;
            _loadingCredit = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading credit: $e');
        setState(() {
          _credit = 0.0;
          _loadingCredit = false;
        });
      }
    } else {
      // Not a PRESS unit, no credit
      _credit = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final unit = authProvider.recyclingUnit;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                unit?.unitName ?? 'Recycling Unit',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                unit?.unitOwnerName ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          actions: [
            NotificationBadge(
              onTap: () {
                context.push('/notifications');
              },
              child: IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Banner/Logo Section
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.recycling,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      localizations.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Stock/Credit Card (for PRESS units only)
              // Shows stock based on approved raw material shipments (1 kg = 1 credit)
              if (unit?.unitType == UnitType.press)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localizations.inventory,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _loadingCredit
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              '${(_credit ?? 0).toStringAsFixed(0)} ${isRTL ? 'كيلو' : 'kg'}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  localizations.quickActions,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: isRTL ? TextAlign.right : TextAlign.left,
                ),
              ),
              const SizedBox(height: 16),
              // Quick Actions Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    // PRESS units: Receive Raw Shipment
                    if (unit?.unitType == UnitType.press)
                      _QuickActionCard(
                        icon: Icons.download,
                        label: localizations.receiveShipment,
                        onTap: () => context.push('/shipments/receive'),
                      ),
                    // PRESS units: Send Processed Shipment
                    if (unit?.unitType == UnitType.press)
                      _QuickActionCard(
                        icon: Icons.upload,
                        label: localizations.sendShipment,
                        onTap: () {
                          context.push('/shipments/send-processed');
                        },
                      ),
                    // Factory units: Receive Processed Shipment
                    if (unit?.unitType == UnitType.shredder || unit?.unitType == UnitType.washingLine)
                      _QuickActionCard(
                        icon: Icons.download,
                        label: isRTL ? 'استلام شحنة معالجة' : 'Receive Processed Shipment',
                        onTap: () => context.push('/shipments/receive-processed'),
                      ),
                    // All units: View Shipments
                    _QuickActionCard(
                      icon: Icons.visibility,
                      label: localizations.viewShipment,
                      onTap: () => context.push('/shipments'),
                    ),
                    // All units: Supply Requests (if needed)
                    _QuickActionCard(
                      icon: Icons.assignment,
                      label: localizations.supplyRequests,
                      onTap: () {
                        // TODO: Navigate to supply requests
                      },
                    ),
                    // All units: Register Vehicle
                    _QuickActionCard(
                      icon: Icons.directions_car,
                      label: localizations.registerVehicle,
                      onTap: () => context.push('/cars/register'),
                    ),
                    // PRESS units: Register Sender
                    if (unit?.unitType == UnitType.press)
                      _QuickActionCard(
                        icon: Icons.person_add,
                        label: localizations.registerSender,
                        onTap: () => context.push('/senders/register'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                // Already on home
                break;
              case 1:
                context.push('/shipments');
                break;
              case 2:
                // TODO: Navigate to orders
                break;
              case 3:
                context.push('/settings');
                break;
            }
          },
          isRTL: isRTL,
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

