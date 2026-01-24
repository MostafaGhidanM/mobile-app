import 'package:flutter/material.dart';
import '../../core/models/shipment.dart';
import '../../widgets/status_badge.dart';

class ProcessedShipmentCard extends StatelessWidget {
  final ProcessedMaterialShipment shipment;
  final VoidCallback onTap;

  const ProcessedShipmentCard({
    Key? key,
    required this.shipment,
    required this.onTap,
  }) : super(key: key);

  String _getStatusText(ProcessedMaterialShipmentStatus status) {
    switch (status) {
      case ProcessedMaterialShipmentStatus.pending:
        return 'Pending';
      case ProcessedMaterialShipmentStatus.sentToFactory:
        return 'Sent to Factory';
      case ProcessedMaterialShipmentStatus.receivedAtFactory:
        return 'Received at Factory';
      case ProcessedMaterialShipmentStatus.sentToAdmin:
        return 'Sent to Admin';
      case ProcessedMaterialShipmentStatus.approved:
        return 'Approved';
      case ProcessedMaterialShipmentStatus.rejected:
        return 'Rejected';
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
                      'Shipment: ${shipment.shipmentNumber}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StatusBadge(
                    status: _getStatusText(shipment.status),
                    color: _getStatusColor(shipment.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (shipment.materialTypeName != null)
                Text(
                  'Material: ${shipment.materialTypeName}',
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 4),
              Text(
                'Weight: ${shipment.weight} kg',
                style: const TextStyle(fontSize: 14),
              ),
              if (shipment.netWeight != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Net Weight: ${shipment.netWeight!.toStringAsFixed(3)} kg',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Date: ${shipment.dateOfSending.year}-${shipment.dateOfSending.month.toString().padLeft(2, '0')}-${shipment.dateOfSending.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 14),
              ),
              if (shipment.pressUnitName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'From: ${shipment.pressUnitName}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              if (shipment.receiverUnitName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'To: ${shipment.receiverUnitName}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Pallets: ${shipment.sentPalletsNumber}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
