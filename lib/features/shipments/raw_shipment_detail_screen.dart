import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/shipment_service.dart';
import '../../core/models/shipment.dart';

/// Read-only raw material shipment detail. Navigate from list or notification.
class RawShipmentDetailScreen extends StatefulWidget {
  final String shipmentId;

  const RawShipmentDetailScreen({
    Key? key,
    required this.shipmentId,
  }) : super(key: key);

  @override
  State<RawShipmentDetailScreen> createState() => _RawShipmentDetailScreenState();
}

class _RawShipmentDetailScreenState extends State<RawShipmentDetailScreen> {
  final ShipmentService _shipmentService = ShipmentService();
  RawMaterialShipmentReceived? _shipment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _shipmentService.getShipmentById(widget.shipmentId);
      if (mounted) {
        setState(() {
          _shipment = response.data;
          _loading = false;
          _error = response.isSuccess ? null : (response.error?.message ?? 'Failed to load');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isRTL ? 'تفاصيل الشحنة' : 'Shipment detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _shipment == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isRTL ? 'تفاصيل الشحنة' : 'Shipment detail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Not found', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(localizations.retry),
              ),
            ],
          ),
        ),
      );
    }

    final s = _shipment!;
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRTL ? 'تفاصيل الشحنة' : 'Shipment detail'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(
                label: localizations.translate('raw_status_sent_to_press'),
                value: _statusText(s.status, localizations, isRTL),
              ),
              _DetailRow(label: localizations.shipmentNumber, value: s.shipmentNumber ?? '-'),
              _DetailRow(label: localizations.translate('raw_sender'), value: s.senderName ?? s.senderId),
              _DetailRow(label: localizations.translate('raw_weight_kg'), value: '${s.weight} kg'),
              if (s.wasteTypeName != null) _DetailRow(label: localizations.translate('raw_waste_type'), value: s.wasteTypeName!),
              if (s.recyclingUnitName != null) _DetailRow(label: isRTL ? 'الوحدة' : 'Unit', value: s.recyclingUnitName!),
              _DetailRow(label: isRTL ? 'التاريخ' : 'Date', value: '${s.createdAt.day}/${s.createdAt.month}/${s.createdAt.year}'),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(ShipmentStatus status, AppLocalizations loc, bool isRTL) {
    switch (status) {
      case ShipmentStatus.pending:
        return loc.translate('raw_status_sent_to_press');
      case ShipmentStatus.approved:
        return loc.translate('raw_status_approved');
      case ShipmentStatus.rejected:
        return loc.translate('raw_status_rejected');
      default:
        return status.name;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
