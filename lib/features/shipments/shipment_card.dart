import 'package:flutter/material.dart';
import '../../core/models/shipment.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/status_badge.dart';

class ShipmentCard extends StatelessWidget {
  final RawMaterialShipmentReceived shipment;
  final VoidCallback? onTap;

  const ShipmentCard({
    Key? key,
    required this.shipment,
    this.onTap,
  }) : super(key: key);

  String _getStatusText(ShipmentStatus status, AppLocalizations localizations) {
    switch (status) {
      case ShipmentStatus.pending:
        return localizations.translate('raw_status_sent_to_press');
      case ShipmentStatus.approved:
        return localizations.translate('raw_status_approved');
      case ShipmentStatus.rejected:
        return localizations.translate('raw_status_rejected');
      case ShipmentStatus.sentToFactory:
        return localizations.statusSentToFactory;
      case ShipmentStatus.receivedAtFactory:
        return localizations.statusReceivedAtFactory;
      case ShipmentStatus.sentToAdmin:
        return localizations.statusSentToAdmin;
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
      case ShipmentStatus.sentToFactory:
        return Colors.cyan;
      case ShipmentStatus.receivedAtFactory:
        return Colors.teal;
      case ShipmentStatus.sentToAdmin:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${localizations.shipment} ${shipment.shipmentNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(
                    status: _getStatusText(shipment.status, localizations),
                    color: _getStatusColor(shipment.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${localizations.shipmentSender} ${shipment.senderName ?? shipment.senderId}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${localizations.date} ${shipment.createdAt.year}-${shipment.createdAt.month.toString().padLeft(2, '0')}-${shipment.createdAt.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 14),
              ),
              if (shipment.senderMobile != null && shipment.senderMobile!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${localizations.phoneNumber} ${shipment.senderMobile}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${localizations.translate('plate_number')} -',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${localizations.shippedWeight} ${shipment.weight.toStringAsFixed(0)} ${localizations.kg}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
