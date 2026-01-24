import 'package:flutter/material.dart';
import '../../core/models/shipment.dart';
import '../../widgets/status_badge.dart';
import '../../localization/app_localizations.dart';

class ProcessedShipmentCard extends StatelessWidget {
  final ProcessedMaterialShipment shipment;
  final VoidCallback onTap;

  const ProcessedShipmentCard({
    Key? key,
    required this.shipment,
    required this.onTap,
  }) : super(key: key);

  String _getStatusText(ProcessedMaterialShipmentStatus status, AppLocalizations localizations) {
    switch (status) {
      case ProcessedMaterialShipmentStatus.pending:
        return localizations.statusPending;
      case ProcessedMaterialShipmentStatus.sentToFactory:
        return localizations.statusSentToFactory;
      case ProcessedMaterialShipmentStatus.receivedAtFactory:
        return localizations.statusReceivedAtFactory;
      case ProcessedMaterialShipmentStatus.sentToAdmin:
        return localizations.statusSentToAdmin;
      case ProcessedMaterialShipmentStatus.approved:
        return localizations.statusApproved;
      case ProcessedMaterialShipmentStatus.rejected:
        return localizations.statusRejected;
    }
  }

  Color _getStatusColor(ProcessedMaterialShipmentStatus status) {
    switch (status) {
      case ProcessedMaterialShipmentStatus.pending:
        return Colors.orange;
      case ProcessedMaterialShipmentStatus.sentToFactory:
        return Colors.blue;
      case ProcessedMaterialShipmentStatus.receivedAtFactory:
        return Colors.cyan;
      case ProcessedMaterialShipmentStatus.sentToAdmin:
        return Colors.purple;
      case ProcessedMaterialShipmentStatus.approved:
        return Colors.green;
      case ProcessedMaterialShipmentStatus.rejected:
        return Colors.red;
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
              if (shipment.materialTypeName != null)
                Text(
                  '${localizations.material} ${shipment.materialTypeName}',
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 4),
              Text(
                '${localizations.weightLabel}: ${shipment.weight} ${localizations.kg}',
                style: const TextStyle(fontSize: 14),
              ),
              if (shipment.netWeight != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${localizations.netWeight} ${shipment.netWeight!.toStringAsFixed(3)} ${localizations.kg}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${localizations.date} ${shipment.dateOfSending.year}-${shipment.dateOfSending.month.toString().padLeft(2, '0')}-${shipment.dateOfSending.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 14),
              ),
              if (shipment.pressUnitName != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${localizations.from} ${shipment.pressUnitName}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              if (shipment.receiverUnitName != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${localizations.to} ${shipment.receiverUnitName}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${localizations.palletsLabel} ${shipment.sentPalletsNumber}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
