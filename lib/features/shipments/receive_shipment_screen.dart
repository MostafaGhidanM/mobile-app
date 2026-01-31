import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/shipment_service.dart';
import '../../core/services/waste_type_service.dart';
import '../../core/services/sender_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/models/waste_type.dart';
import '../../core/models/sender.dart';
import '../../core/models/shipment.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';
import 'package:go_router/go_router.dart';

class ReceiveShipmentScreen extends StatefulWidget {
  const ReceiveShipmentScreen({Key? key}) : super(key: key);

  @override
  State<ReceiveShipmentScreen> createState() => _ReceiveShipmentScreenState();
}

class _ReceiveShipmentScreenState extends State<ReceiveShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  
  final ShipmentService _shipmentService = ShipmentService();
  final WasteTypeService _wasteTypeService = WasteTypeService();
  final SenderService _senderService = SenderService();
  final UploadService _uploadService = UploadService();

  String? _shipmentImagePath;
  String? _shipmentImageUrl;
  String? _receiptImagePath;
  String? _receiptImageUrl;
  WasteType? _selectedWasteType;
  Sender? _selectedSender;
  List<WasteType> _wasteTypes = [];
  List<Sender> _senders = [];
  bool _isLoading = false;
  bool _isLoadingData = true;
  Map<String, double>? _shipmentLocation;

  // Complete-from-sender flow
  String _receiveMode = 'new'; // 'new' | 'complete_from_sender'
  List<RawMaterialShipmentReceived> _senderCreatedShipments = [];
  RawMaterialShipmentReceived? _selectedShipmentForComplete;
  final _completeWeightController = TextEditingController();
  String? _completeReceiptImagePath;
  String? _completeReceiptImageUrl;
  bool _loadingSenderShipments = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _completeWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadSenderCreatedShipments() async {
    setState(() => _loadingSenderShipments = true);
    try {
      final response = await _shipmentService.listShipments(
        page: 1,
        pageSize: 100,
        createdBy: 'SENDER',
      );
      if (mounted) {
        setState(() {
          _senderCreatedShipments = response.isSuccess && response.data != null
              ? response.data!.items
              : [];
          _loadingSenderShipments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSenderShipments = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadCompleteReceiptImage(dynamic imageData) async {
    setState(() => _isLoading = true);
    try {
      final response = await _uploadService.uploadImage(imageData);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _completeReceiptImageUrl = response.data!.url;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCompleteFromSender() async {
    if (_selectedShipmentForComplete == null) return;
    if (_completeReceiptImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'ar'
              ? 'يرجى رفع صورة كارتة الميزان'
              : 'Please upload scale card image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final weight = double.tryParse(_completeWeightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'ar'
              ? 'أدخل الوزن صحيحاً'
              : 'Enter valid weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _shipmentService.completeShipmentFromSender(
        shipmentId: _selectedShipmentForComplete!.id,
        weight: weight,
        receiptImage: _completeReceiptImageUrl!,
      );
      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localizations.localeOf(context).languageCode == 'ar'
                ? 'تم استلام الشحنة بنجاح'
                : 'Shipment completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedShipmentForComplete = null;
          _completeWeightController.clear();
          _completeReceiptImageUrl = null;
          _completeReceiptImagePath = null;
        });
        _loadSenderCreatedShipments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to complete shipment'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final wasteTypesResponse = await _wasteTypeService.getWasteTypes();
      final sendersResponse = await _senderService.getAssignedSenders();

      if (mounted) {
        setState(() {
          if (wasteTypesResponse.isSuccess && wasteTypesResponse.data != null) {
            _wasteTypes = wasteTypesResponse.data!;
          }
          if (sendersResponse.isSuccess && sendersResponse.data != null) {
            _senders = sendersResponse.data!;
          }
          _isLoadingData = false;
        });

        // Show error messages if any
        if (!wasteTypesResponse.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load waste types: ${wasteTypesResponse.error?.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (!sendersResponse.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load senders: ${sendersResponse.error?.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(dynamic imageData) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _uploadService.uploadImage(imageData);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _shipmentImageUrl = response.data!.url;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to upload image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadReceiptImage(dynamic imageData) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _uploadService.uploadImage(imageData);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _receiptImageUrl = response.data!.url;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to upload receipt image'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading receipt image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_shipmentImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload shipment image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWasteType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select waste type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select sender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch next shipment number from backend
      final nextNumberResponse = await _shipmentService.getNextRawMaterialShipmentNumber();
      if (!nextNumberResponse.isSuccess || nextNumberResponse.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nextNumberResponse.error?.message ?? 'Failed to get next shipment number'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final response = await _shipmentService.createShipment(
        shipmentImage: _shipmentImageUrl!,
        wasteTypeId: _selectedWasteType!.id,
        weight: double.parse(_weightController.text),
        senderId: _selectedSender!.id,
        shipmentNumber: nextNumberResponse.data,
        receiptImage: _receiptImageUrl,
        geoLocation: _shipmentLocation,
      );

      if (response.isSuccess && mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.rawShipmentCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to create shipment'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
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
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.receiveShipment),
        ),
        body: _isLoadingData && _receiveMode == 'new'
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mode selector: Receive new | Complete from sender
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _receiveMode = 'new';
                                _selectedShipmentForComplete = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _receiveMode == 'new'
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : null,
                            ),
                            child: Text(
                              isRTL ? 'استلام شحنة جديدة' : 'Receive new shipment',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _receiveMode = 'complete_from_sender';
                                _selectedShipmentForComplete = null;
                              });
                              _loadSenderCreatedShipments();
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _receiveMode == 'complete_from_sender'
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : null,
                            ),
                            child: Text(
                              isRTL ? 'استكمال شحنة من مرسل' : 'Complete from sender',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content based on mode
                  Expanded(
                    child: _receiveMode == 'complete_from_sender'
                        ? _buildCompleteFromSenderContent(localizations, isRTL)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _buildReceiveNewFormChildren(localizations, isRTL),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCompleteFromSenderContent(AppLocalizations localizations, bool isRTL) {
    if (_selectedShipmentForComplete != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isRTL ? 'استكمال الشحنة' : 'Complete shipment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField(isRTL ? 'مرسل الشحنة' : 'Sender', _selectedShipmentForComplete!.senderName ?? ''),
            _buildReadOnlyField(isRTL ? 'نوع المخلفات' : 'Waste type', _selectedShipmentForComplete!.wasteTypeName ?? ''),
            _buildReadOnlyField(isRTL ? 'الوزن (من المرسل)' : 'Weight (from sender)', '${_selectedShipmentForComplete!.weight} kg'),
            const SizedBox(height: 20),
            CustomTextField(
              label: isRTL ? 'الوزن كيلو *' : 'Weight (kg) *',
              hint: '0',
              controller: _completeWeightController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ImagePickerWidget(
              imagePath: _completeReceiptImagePath,
              label: isRTL ? 'صورة كارتة الميزان من المرسل *' : 'Scale card image *',
              onImagePicked: (fileOrBytes) async {
                setState(() {
                  if (kIsWeb && fileOrBytes is Uint8List) {
                  } else if (!kIsWeb && fileOrBytes is File) {
                    _completeReceiptImagePath = fileOrBytes.path;
                  }
                });
                await _uploadCompleteReceiptImage(fileOrBytes);
              },
              icon: Icons.scale,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: isRTL ? 'استلام' : 'Complete',
              onPressed: _submitCompleteFromSender,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedShipmentForComplete = null;
                  _completeWeightController.clear();
                  _completeReceiptImageUrl = null;
                  _completeReceiptImagePath = null;
                });
              },
              child: Text(isRTL ? 'رجوع للقائمة' : 'Back to list'),
            ),
          ],
        ),
      );
    }
    if (_loadingSenderShipments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_senderCreatedShipments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            isRTL ? 'لا توجد شحنات من مرسلين بانتظار الاستكمال' : 'No shipments from senders awaiting completion',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _senderCreatedShipments.length,
      itemBuilder: (context, index) {
        final s = _senderCreatedShipments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(s.senderName ?? 'Sender'),
            subtitle: Text(
              '${isRTL ? 'الوزن' : 'Weight'}: ${s.weight} kg • #${s.shipmentNumber}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _selectedShipmentForComplete = s;
                _completeWeightController.text = s.weight.toStringAsFixed(0);
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildReceiveNewFormChildren(AppLocalizations localizations, bool isRTL) {
    return [
                      // صورة استلام الشحنة من المرسل
                      ImagePickerWidget(
                        imagePath: _shipmentImagePath,
                        label: localizations.translate('raw_shipment_image'),
                        captureLocation: true,
                        onLocationCaptured: (location) {
                          setState(() {
                            _shipmentLocation = location;
                          });
                        },
                        onImagePicked: (fileOrBytes) async {
                          setState(() {
                            if (kIsWeb && fileOrBytes is Uint8List) {
                              // Store bytes for web
                            } else if (!kIsWeb && fileOrBytes is File) {
                              _shipmentImagePath = fileOrBytes.path;
                            }
                          });
                          await _uploadImage(fileOrBytes);
                        },
                        icon: Icons.camera_alt,
                        helperText: localizations.translate('max_file_size'),
                      ),
                      const SizedBox(height: 24),
                      // Waste Type Dropdown
                      ConstrainedDropdownButtonFormField<WasteType>(
                        value: _selectedWasteType,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: '${localizations.translate('waste_type')} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _wasteTypes.map((type) {
                          return DropdownMenuItem<WasteType>(
                            value: type,
                            child: Text(
                              isRTL ? type.nameAr : type.nameEn,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedWasteType = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return localizations.translate('required_field');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // صورة كارتة الميزان من المرسل
                      ImagePickerWidget(
                        imagePath: _receiptImagePath,
                        label: localizations.translate('raw_scale_card_image'),
                        onImagePicked: (fileOrBytes) async {
                          setState(() {
                            if (kIsWeb && fileOrBytes is Uint8List) {
                              // Store bytes for web
                            } else if (!kIsWeb && fileOrBytes is File) {
                              _receiptImagePath = fileOrBytes.path;
                            }
                          });
                          await _uploadReceiptImage(fileOrBytes);
                        },
                        icon: Icons.receipt,
                        helperText: localizations.translate('max_file_size'),
                      ),
                      const SizedBox(height: 20),
                      // الوزن كيلو
                      CustomTextField(
                        label: '${localizations.translate('raw_weight_kg')} *',
                        hint: '0',
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.translate('required_field');
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return localizations.translate('invalid_format');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Sender Dropdown
                      ConstrainedDropdownButtonFormField<Sender>(
                        value: _selectedSender,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: '${localizations.translate('raw_sender')} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _senders.map((sender) {
                          return DropdownMenuItem<Sender>(
                            value: sender,
                            child: Text(
                              sender.fullName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSender = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return localizations.translate('required_field');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Register New Sender Button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await context.push('/senders/register');
                          if (result == true) {
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: Text(localizations.translate('register_new_sender')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // استلام
                      CustomButton(
                        text: localizations.translate('raw_receive_button'),
                        onPressed: _submitForm,
                        isLoading: _isLoading,
                      ),
    ];
  }
}

