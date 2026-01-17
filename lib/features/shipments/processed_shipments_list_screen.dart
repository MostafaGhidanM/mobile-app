import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/shipment_service.dart';
import '../../core/models/shipment.dart';
import '../../core/api/api_response.dart';
import '../../features/auth/auth_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'processed_shipment_card.dart';
import 'package:go_router/go_router.dart';

void _debugLog(String location, String message, Map<String, dynamic> data, String hypothesisId) {
  try {
    final f = File(r'c:\Users\5eert\Desktop\alpha green\.cursor\debug.log');
    f.writeAsStringSync('${jsonEncode({"location":location,"message":message,"data":data,"timestamp":DateTime.now().millisecondsSinceEpoch,"sessionId":"debug-session","runId":"run1","hypothesisId":hypothesisId})}\n', mode: FileMode.append);
  } catch (_) {}
}

class ProcessedShipmentsListScreen extends StatefulWidget {
  const ProcessedShipmentsListScreen({Key? key}) : super(key: key);

  @override
  State<ProcessedShipmentsListScreen> createState() => _ProcessedShipmentsListScreenState();
}

class _ProcessedShipmentsListScreenState extends State<ProcessedShipmentsListScreen> {
  final ShipmentService _shipmentService = ShipmentService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ProcessedMaterialShipment> _shipments = [];
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
      // Check if this is a factory unit (shredder/washline)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final recyclingUnit = authProvider.recyclingUnit;
      final isFactoryUnit = recyclingUnit?.isFactoryUnit() ?? false;

      // #region agent log
      _debugLog('processed_shipments_list_screen.dart:69', '_loadShipments unit check', {'unitIsNull': recyclingUnit == null, 'unitType': recyclingUnit?.unitType?.toString(), 'isFactoryUnit': isFactoryUnit}, 'G');
      // #endregion

      ApiResponse<ProcessedMaterialShipmentListResponse> response;
      
      if (isFactoryUnit) {
        // Factory units should use pending-receipt endpoint to see shipments sent to them
        final pendingResponse = await _shipmentService.getPendingReceiptShipments();
        
        // #region agent log
        _debugLog('processed_shipments_list_screen.dart:81', 'Factory unit - pending receipts response', {'isSuccess': pendingResponse.isSuccess, 'itemsCount': pendingResponse.data?.length}, 'G');
        // #endregion
        
        if (pendingResponse.isSuccess && pendingResponse.data != null) {
          // Convert to list response format
          response = ApiResponse<ProcessedMaterialShipmentListResponse>(
            success: true,
            data: ProcessedMaterialShipmentListResponse(
              items: pendingResponse.data!,
              total: pendingResponse.data!.length,
              page: 1,
              pageSize: pendingResponse.data!.length,
            ),
          );
        } else {
          response = ApiResponse<ProcessedMaterialShipmentListResponse>(
            success: false,
            error: pendingResponse.error,
          );
        }
      } else {
        // Press units use regular list endpoint
        response = await _shipmentService.listProcessedMaterialShipments(
          page: _currentPage,
          pageSize: 20,
          status: _selectedFilter != 'all' ? _getStatusString(_selectedFilter) : null,
        );
        
        // #region agent log
        _debugLog('processed_shipments_list_screen.dart:110', 'Press unit - sent shipments response', {'isSuccess': response.isSuccess, 'itemsCount': response.data?.items?.length}, 'G');
        // #endregion
      }

      if (response.isSuccess && response.data != null) {
        setState(() {
          if (refresh) {
            _shipments = response.data!.items;
          } else {
            _shipments.addAll(response.data!.items);
          }
          // For factory units using pending-receipt, pagination doesn't apply
          _hasMore = isFactoryUnit ? false : response.data!.items.length == 20;
          if (!isFactoryUnit) {
            _currentPage++;
          }
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

  String? _getStatusString(String filter) {
    switch (filter) {
      case 'sent_to_factory':
        return 'SENT_TO_FACTORY';
      case 'sent_to_admin':
        return 'SENT_TO_ADMIN';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return null;
    }
  }

  List<ProcessedMaterialShipment> get _filteredShipments {
    if (_selectedFilter == 'all') return _shipments;
    
    return _shipments.where((shipment) {
      switch (_selectedFilter) {
        case 'sent_to_factory':
          return shipment.status == ProcessedMaterialShipmentStatus.sentToFactory;
        case 'sent_to_admin':
          return shipment.status == ProcessedMaterialShipmentStatus.sentToAdmin;
        case 'approved':
          return shipment.status == ProcessedMaterialShipmentStatus.approved;
        case 'rejected':
          return shipment.status == ProcessedMaterialShipmentStatus.rejected;
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
          title: const Text('Processed Material Shipments'),
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
                    onTap: () => setState(() {
                      _selectedFilter = 'all';
                      _loadShipments(refresh: true);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Sent to Factory',
                    isSelected: _selectedFilter == 'sent_to_factory',
                    onTap: () => setState(() {
                      _selectedFilter = 'sent_to_factory';
                      _loadShipments(refresh: true);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Sent to Admin',
                    isSelected: _selectedFilter == 'sent_to_admin',
                    onTap: () => setState(() {
                      _selectedFilter = 'sent_to_admin';
                      _loadShipments(refresh: true);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Approved',
                    isSelected: _selectedFilter == 'approved',
                    onTap: () => setState(() {
                      _selectedFilter = 'approved';
                      _loadShipments(refresh: true);
                    }),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Rejected',
                    isSelected: _selectedFilter == 'rejected',
                    onTap: () => setState(() {
                      _selectedFilter = 'rejected';
                      _loadShipments(refresh: true);
                    }),
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
                                  return ProcessedShipmentCard(
                                    shipment: _filteredShipments[index],
                                    onTap: () {
                                      // TODO: Navigate to shipment details
                                    },
                                  );
                                },
                              ),
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
