import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/shipment_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/models/shipment.dart';
import '../../features/auth/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import 'package:go_router/go_router.dart';

class ReceiveProcessedShipmentScreen extends StatefulWidget {
  const ReceiveProcessedShipmentScreen({Key? key}) : super(key: key);

  @override
  State<ReceiveProcessedShipmentScreen> createState() => _ReceiveProcessedShipmentScreenState();
}

class _ReceiveProcessedShipmentScreenState extends State<ReceiveProcessedShipmentScreen> {
  final ShipmentService _shipmentService = ShipmentService();
  final UploadService _uploadService = UploadService();
  
  List<ProcessedMaterialShipment> _pendingShipments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingShipments();
  }

  Future<void> _loadPendingShipments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _shipmentService.getPendingReceiptShipments();
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          _pendingShipments = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error?.message ?? 'Failed to load shipments';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openReceiveDialog(ProcessedMaterialShipment shipment) {
    showDialog(
      context: context,
      builder: (context) => _ReceiveShipmentDialog(
        shipment: shipment,
        onReceived: () {
          _loadPendingShipments();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receive Processed Material Shipments'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPendingShipments,
                          child: Text(localizations.retry),
                        ),
                      ],
                    ),
                  )
                : _pendingShipments.isEmpty
                    ? Center(child: Text(localizations.noData))
                    : RefreshIndicator(
                        onRefresh: _loadPendingShipments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pendingShipments.length,
                          itemBuilder: (context, index) {
                            final shipment = _pendingShipments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text('Shipment: ${shipment.shipmentNumber}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Weight: ${shipment.weight} tons'),
                                    Text('Material: ${shipment.materialTypeName ?? 'N/A'}'),
                                    Text('From: ${shipment.pressUnitName ?? 'N/A'}'),
                                    Text('Date: ${shipment.dateOfSending.year}-${shipment.dateOfSending.month}-${shipment.dateOfSending.day}'),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _openReceiveDialog(shipment),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class _ReceiveShipmentDialog extends StatefulWidget {
  final ProcessedMaterialShipment shipment;
  final VoidCallback onReceived;

  const _ReceiveShipmentDialog({
    required this.shipment,
    required this.onReceived,
  });

  @override
  State<_ReceiveShipmentDialog> createState() => _ReceiveShipmentDialogState();
}

class _ReceiveShipmentDialogState extends State<_ReceiveShipmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _receivedWeightController = TextEditingController();
  final _emptyCarWeightController = TextEditingController();
  final _plentyController = TextEditingController(text: '0');
  final _plentyReasonController = TextEditingController(text: 'هالك');
  
  final ShipmentService _shipmentService = ShipmentService();
  final UploadService _uploadService = UploadService();

  String? _carCheckImagePath;
  String? _carCheckImageUrl;
  String? _receiptImagePath;
  String? _receiptImageUrl;
  double? _calculatedNetWeight;
  bool _isLoading = false;

  @override
  void dispose() {
    _receivedWeightController.dispose();
    _emptyCarWeightController.dispose();
    _plentyController.dispose();
    _plentyReasonController.dispose();
    super.dispose();
  }

  void _calculateNetWeight() {
    final receivedWeight = double.tryParse(_receivedWeightController.text);
    final emptyCarWeight = double.tryParse(_emptyCarWeightController.text);
    final plenty = double.tryParse(_plentyController.text) ?? 0;

    if (receivedWeight != null && emptyCarWeight != null) {
      if (receivedWeight <= emptyCarWeight) {
        setState(() => _calculatedNetWeight = null);
        return;
      }
      final netWeight = (receivedWeight - emptyCarWeight) * (1 - plenty / 100);
      setState(() => _calculatedNetWeight = netWeight);
    } else {
      setState(() => _calculatedNetWeight = null);
    }
  }

  Future<void> _uploadCarCheckImage(dynamic imageData) async {
    if (kIsWeb) {
      setState(() => _carCheckImagePath = 'web_image');
      await _uploadImageFromBytes(imageData as Uint8List, true);
    } else {
      final file = imageData as File;
      setState(() => _carCheckImagePath = file.path);
      await _uploadImageFromFile(file, true);
    }
  }

  Future<void> _uploadReceiptImageDialog(dynamic imageData) async {
    if (kIsWeb) {
      setState(() => _receiptImagePath = 'web_image');
      await _uploadImageFromBytes(imageData as Uint8List, false);
    } else {
      final file = imageData as File;
      setState(() => _receiptImagePath = file.path);
      await _uploadImageFromFile(file, false);
    }
  }

  Future<void> _uploadImageFromFile(File file, bool isCarCheck) async {
    setState(() => _isLoading = true);
    try {
      final response = await _uploadService.uploadImage(file);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          if (isCarCheck) {
            _carCheckImageUrl = response.data!.url;
          } else {
            _receiptImageUrl = response.data!.url;
          }
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageFromBytes(Uint8List bytes, bool isCarCheck) async {
    setState(() => _isLoading = true);
    try {
      final response = await _uploadService.uploadImage(bytes);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          if (isCarCheck) {
            _carCheckImageUrl = response.data!.url;
          } else {
            _receiptImageUrl = response.data!.url;
          }
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitReceive() async {
    if (!_formKey.currentState!.validate()) return;
    
    final receivedWeight = double.parse(_receivedWeightController.text);
    final emptyCarWeight = double.parse(_emptyCarWeightController.text);
    
    if (receivedWeight <= emptyCarWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Received weight must be greater than empty car weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final factoryUnitId = Provider.of<AuthProvider>(context, listen: false)
        .recyclingUnit?.id;
    
    if (factoryUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factory unit ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _shipmentService.receiveProcessedMaterialShipment(
        shipmentId: widget.shipment.id,
        factoryUnitId: factoryUnitId,
        receivedWeight: receivedWeight,
        emptyCarWeight: emptyCarWeight,
        plenty: double.parse(_plentyController.text),
        carCheckImage: _carCheckImageUrl,
        receiptImage: _receiptImageUrl,
        plentyReason: _plentyReasonController.text,
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment received successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close dialog
        widget.onReceived();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to receive shipment'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Receive Shipment: ${widget.shipment.shipmentNumber}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Shipment Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weight: ${widget.shipment.weight} tons'),
                          Text('Material: ${widget.shipment.materialTypeName ?? 'N/A'}'),
                          Text('Pallets: ${widget.shipment.sentPalletsNumber}'),
                          Text('From: ${widget.shipment.pressUnitName ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Car Check Image
                  ImagePickerWidget(
                    label: 'Car Check Image',
                    imagePath: _carCheckImagePath,
                    onImagePicked: _uploadCarCheckImage,
                  ),
                  const SizedBox(height: 16),
                  
                  // Receipt Image
                  ImagePickerWidget(
                    label: 'Receipt Image',
                    imagePath: _receiptImagePath,
                    onImagePicked: _uploadReceiptImageDialog,
                  ),
                  const SizedBox(height: 16),
                  
                  // Received Weight
                  CustomTextField(
                    controller: _receivedWeightController,
                    label: 'Received Weight (tons) *',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateNetWeight(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter received weight';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Empty Car Weight
                  CustomTextField(
                    controller: _emptyCarWeightController,
                    label: 'Empty Car Weight (tons) *',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateNetWeight(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter empty car weight';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Plenty
                  CustomTextField(
                    controller: _plentyController,
                    label: 'Plenty (%) *',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateNetWeight(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter plenty percentage';
                      }
                      final plenty = double.tryParse(value);
                      if (plenty == null) {
                        return 'Please enter a valid number';
                      }
                      if (plenty < 0 || plenty > 100) {
                        return 'Plenty must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Plenty Reason
                  CustomTextField(
                    controller: _plentyReasonController,
                    label: 'Plenty Reason',
                  ),
                  const SizedBox(height: 16),
                  
                  // Calculated Net Weight
                  if (_calculatedNetWeight != null)
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Calculated Net Weight: ${_calculatedNetWeight!.toStringAsFixed(3)} tons',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomButton(
                          text: 'Receive',
                          onPressed: _isLoading ? null : _submitReceive,
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
