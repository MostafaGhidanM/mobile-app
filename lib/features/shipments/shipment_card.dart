import 'package:flutter/material.dart';
import '../../core/models/shipment.dart';
import '../../localization/app_localizations.dart';

class ShipmentCard extends StatelessWidget {
  final RawMaterialShipmentReceived shipment;
  final VoidCallback? onTap;

  const ShipmentCard({
    Key? key,
    required this.shipment,
    this.onTap,
  }) : super(key: key);

  String _getStatusText(ShipmentStatus status, bool isRTL) {
    switch (status) {
      case ShipmentStatus.pending:
        return isRTL ? 'مفتوح' : 'Open';
      case ShipmentStatus.approved:
        return isRTL ? 'قيد العمل' : 'In Progress';
      case ShipmentStatus.rejected:
        return isRTL ? 'مغلق' : 'Closed';
    }
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.pending:
        return Colors.orange;
      case ShipmentStatus.approved:
        return Colors.blue;
      case ShipmentStatus.rejected:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(shipment.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(shipment.status, isRTL),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    shipment.shipmentNumber ?? shipment.id.substring(0, 8),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Shipment Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.shipmentSender,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shipment.senderName ?? shipment.senderId.substring(0, 8),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (shipment.senderMobile != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            shipment.senderMobile!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          localizations.shippedWeight,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${shipment.weight.toStringAsFixed(0)} ${isRTL ? 'كيلو' : 'kg'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isRTL ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        Text(
                          localizations.shippingDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: isRTL ? TextAlign.left : TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${shipment.createdAt.year}-${shipment.createdAt.month.toString().padLeft(2, '0')}-${shipment.createdAt.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: isRTL ? TextAlign.left : TextAlign.right,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          localizations.translate('plate_number'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: isRTL ? TextAlign.left : TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: isRTL ? TextAlign.left : TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

