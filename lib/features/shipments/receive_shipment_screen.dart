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
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';

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
  WasteType? _selectedWasteType;
  Sender? _selectedSender;
  List<WasteType> _wasteTypes = [];
  List<Sender> _senders = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    
    try {
      debugPrint('[ReceiveShipmentScreen] Loading waste types...');
      final wasteTypesResponse = await _wasteTypeService.getWasteTypes();
      debugPrint('[ReceiveShipmentScreen] Waste types response: ${wasteTypesResponse.isSuccess}');
      debugPrint('[ReceiveShipmentScreen] Waste types data: ${wasteTypesResponse.data?.length ?? 0}');
      debugPrint('[ReceiveShipmentScreen] Waste types error: ${wasteTypesResponse.error?.message}');

      debugPrint('[ReceiveShipmentScreen] Loading senders...');
      final sendersResponse = await _senderService.getAssignedSenders();
      debugPrint('[ReceiveShipmentScreen] Senders response: ${sendersResponse.isSuccess}');
      debugPrint('[ReceiveShipmentScreen] Senders data: ${sendersResponse.data?.length ?? 0}');
      debugPrint('[ReceiveShipmentScreen] Senders error: ${sendersResponse.error?.message}');

      if (mounted) {
        setState(() {
          if (wasteTypesResponse.isSuccess && wasteTypesResponse.data != null) {
            _wasteTypes = wasteTypesResponse.data!;
            debugPrint('[ReceiveShipmentScreen] Loaded ${_wasteTypes.length} waste types');
          } else {
            debugPrint('[ReceiveShipmentScreen] Failed to load waste types: ${wasteTypesResponse.error?.message}');
          }
          if (sendersResponse.isSuccess && sendersResponse.data != null) {
            _senders = sendersResponse.data!;
            debugPrint('[ReceiveShipmentScreen] Loaded ${_senders.length} senders');
          } else {
            debugPrint('[ReceiveShipmentScreen] Failed to load senders: ${sendersResponse.error?.message}');
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
      debugPrint('[ReceiveShipmentScreen] Exception loading data: $e');
      debugPrint('[ReceiveShipmentScreen] Stack trace: $stackTrace');
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
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipment created successfully'),
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
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Shipment Image
                      ImagePickerWidget(
                        imagePath: _shipmentImagePath,
                        label: localizations.translate('shipment_image'),
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
                      const SizedBox(height: 20),
                      // Weight Input
                      CustomTextField(
                        label: '${localizations.translate('weight_kg')} *',
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
                          labelText: '${localizations.translate('shipment_sender')} *',
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
                          final result = await Navigator.pushNamed(
                            context,
                            '/senders/register',
                          );
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
                      // Submit Button
                      CustomButton(
                        text: localizations.submit,
                        onPressed: _submitForm,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

