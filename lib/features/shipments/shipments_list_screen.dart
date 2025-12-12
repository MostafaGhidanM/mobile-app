import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/shipment_service.dart';
import '../../core/models/shipment.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'shipment_card.dart';
import 'package:go_router/go_router.dart';

class ShipmentsListScreen extends StatefulWidget {
  const ShipmentsListScreen({Key? key}) : super(key: key);

  @override
  State<ShipmentsListScreen> createState() => _ShipmentsListScreenState();
}

class _ShipmentsListScreenState extends State<ShipmentsListScreen> {
  final ShipmentService _shipmentService = ShipmentService();
  final TextEditingController _searchController = TextEditingController();
  
  List<RawMaterialShipmentReceived> _shipments = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'all';
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadShipments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShipments({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _shipmentService.listShipments(
        page: _currentPage,
        pageSize: 20,
      );

      if (response.isSuccess && response.data != null) {
        setState(() {
          if (refresh) {
            _shipments = response.data!.items;
          } else {
            _shipments.addAll(response.data!.items);
          }
          _hasMore = response.data!.items.length == 20;
          _currentPage++;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error?.message ?? 'Failed to load shipments';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<RawMaterialShipmentReceived> get _filteredShipments {
    if (_selectedFilter == 'all') return _shipments;
    
    return _shipments.where((shipment) {
      switch (_selectedFilter) {
        case 'open':
          return shipment.status == ShipmentStatus.pending;
        case 'in_progress':
          return shipment.status == ShipmentStatus.approved;
        case 'closed':
          return shipment.status == ShipmentStatus.rejected;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.myShipments),
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: localizations.search,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () {
                      // TODO: Show sort options
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            // Filter Tabs
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: localizations.all,
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: localizations.open,
                    isSelected: _selectedFilter == 'open',
                    onTap: () => setState(() => _selectedFilter = 'open'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: localizations.inProgress,
                    isSelected: _selectedFilter == 'in_progress',
                    onTap: () => setState(() => _selectedFilter = 'in_progress'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: localizations.closed,
                    isSelected: _selectedFilter == 'closed',
                    onTap: () => setState(() => _selectedFilter = 'closed'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Shipments List
            Expanded(
              child: _isLoading && _shipments.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _shipments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_errorMessage!),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadShipments(refresh: true),
                                child: Text(localizations.retry),
                              ),
                            ],
                          ),
                        )
                      : _filteredShipments.isEmpty
                          ? Center(child: Text(localizations.noData))
                          : RefreshIndicator(
                              onRefresh: () => _loadShipments(refresh: true),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredShipments.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredShipments.length) {
                                    _loadShipments();
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  return ShipmentCard(
                                    shipment: _filteredShipments[index],
                                    onTap: () {
                                      // TODO: Navigate to shipment details
                                    },
                                  );
                                },
                              ),
                            ),
            ),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/shipments/receive'),
                      icon: const Icon(Icons.download),
                      label: Text(localizations.receiveShipment),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to send shipment
                      },
                      icon: const Icon(Icons.upload),
                      label: Text(localizations.sendShipment),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                // Already on shipments
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

