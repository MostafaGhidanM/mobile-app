import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/shipment_service.dart';
import '../../core/services/waste_type_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/services/recycling_unit_service.dart';
import '../../core/models/waste_type.dart';
import '../../core/models/recycling_unit.dart';
import '../../features/auth/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';

/// Sender flow: send raw shipment to a chosen press unit.
/// Fields: shipment image, waste type, scale/receipt image, weight, sender (self), source description optional.
class SendShipmentToPressScreen extends StatefulWidget {
  const SendShipmentToPressScreen({Key? key}) : super(key: key);

  @override
  State<SendShipmentToPressScreen> createState() => _SendShipmentToPressScreenState();
}

class _SendShipmentToPressScreenState extends State<SendShipmentToPressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _sourceDescriptionController = TextEditingController();

  final ShipmentService _shipmentService = ShipmentService();
  final WasteTypeService _wasteTypeService = WasteTypeService();
  final UploadService _uploadService = UploadService();
  final RecyclingUnitService _recyclingUnitService = RecyclingUnitService();

  String? _shipmentImagePath;
  String? _shipmentImageUrl;
  String? _receiptImagePath;
  String? _receiptImageUrl;
  WasteType? _selectedWasteType;
  RecyclingUnit? _selectedPressUnit;
  List<WasteType> _wasteTypes = [];
  List<RecyclingUnit> _pressUnits = [];
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
    _sourceDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final wasteTypesResponse = await _wasteTypeService.getWasteTypes();
      final pressUnitsResponse = await _recyclingUnitService.getPressUnitsForSender();

      if (mounted) {
        setState(() {
          if (wasteTypesResponse.isSuccess && wasteTypesResponse.data != null) {
            _wasteTypes = wasteTypesResponse.data!;
          }
          if (pressUnitsResponse.isSuccess && pressUnitsResponse.data != null) {
            _pressUnits = pressUnitsResponse.data!;
          }
          _isLoadingData = false;
        });
        if (!wasteTypesResponse.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load waste types: ${wasteTypesResponse.error?.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (!pressUnitsResponse.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load press units: ${pressUnitsResponse.error?.message ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
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
    if (!_formKey.currentState!.validate()) return;

    if (_shipmentImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'ar'
              ? 'يرجى رفع صورة استلام الشحنة'
              : 'Please upload shipment image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedWasteType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'ar'
              ? 'يرجى اختيار نوع المخلفات'
              : 'Please select waste type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedPressUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'ar'
              ? 'يرجى اختيار المكبس'
              : 'Please select press unit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _shipmentService.createShipmentAsSender(
        shipmentImage: _shipmentImageUrl!,
        wasteTypeId: _selectedWasteType!.id,
        weight: double.parse(_weightController.text),
        recyclingUnitId: _selectedPressUnit!.id,
        receiptImage: _receiptImageUrl,
        sourceDescription: _sourceDescriptionController.text.trim().isEmpty
            ? null
            : _sourceDescriptionController.text.trim(),
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم إرسال الشحنة إلى المكبس بنجاح'
                  : 'Shipment sent to press successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to send shipment'),
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
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final authProvider = Provider.of<AuthProvider>(context);
    final sender = authProvider.sender;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRTL ? 'إرسال شحنة إلى المكبس' : 'Send shipment to press'),
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
                      // صورة استلام الشحنة من المرسل
                      ImagePickerWidget(
                        imagePath: _shipmentImagePath,
                        label: isRTL ? 'صورة استلام الشحنة من المرسل' : 'Shipment receipt image',
                        onImagePicked: (fileOrBytes) async {
                          setState(() {
                            if (kIsWeb && fileOrBytes is Uint8List) {
                            } else if (!kIsWeb && fileOrBytes is File) {
                              _shipmentImagePath = fileOrBytes.path;
                            }
                          });
                          await _uploadImage(fileOrBytes);
                        },
                        icon: Icons.camera_alt,
                      ),
                      const SizedBox(height: 20),
                      // نوع المخلفات
                      ConstrainedDropdownButtonFormField<WasteType>(
                        value: _selectedWasteType,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: isRTL ? 'نوع المخلفات *' : 'Waste type *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        onChanged: (value) => setState(() => _selectedWasteType = value),
                        validator: (value) =>
                            value == null ? (isRTL ? 'مطلوب' : 'Required') : null,
                      ),
                      const SizedBox(height: 20),
                      // صورة كارتة الميزان من المرسل
                      ImagePickerWidget(
                        imagePath: _receiptImagePath,
                        label: isRTL ? 'صورة كارتة الميزان من المرسل' : 'Scale card image',
                        onImagePicked: (fileOrBytes) async {
                          setState(() {
                            if (kIsWeb && fileOrBytes is Uint8List) {
                            } else if (!kIsWeb && fileOrBytes is File) {
                              _receiptImagePath = fileOrBytes.path;
                            }
                          });
                          await _uploadReceiptImage(fileOrBytes);
                        },
                        icon: Icons.scale,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        label: isRTL ? 'الوزن كيلو *' : 'Weight (kg) *',
                        hint: isRTL ? 'الوزن' : 'Weight',
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isRTL ? 'مطلوب' : 'Required';
                          }
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return isRTL ? 'أدخل رقماً صحيحاً' : 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // مرسل الشحنة (read-only)
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: isRTL ? 'مرسل الشحنة' : 'Sender',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        child: Text(
                          sender?.fullName ?? '',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // مصدر الشحنة تتكتب بالإيد (optional)
                      CustomTextField(
                        label: isRTL ? 'مصدر الشحنة تتكتب بالإيد' : 'Source description (optional)',
                        hint: isRTL ? 'اختياري' : 'Optional',
                        controller: _sourceDescriptionController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      // Press unit dropdown
                      ConstrainedDropdownButtonFormField<RecyclingUnit>(
                        value: _selectedPressUnit,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: isRTL ? 'المكبس (الوحدة المستهدفة) *' : 'Press unit (target) *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _pressUnits.map((unit) {
                          return DropdownMenuItem<RecyclingUnit>(
                            value: unit,
                            child: Text(
                              unit.unitName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedPressUnit = value),
                        validator: (value) =>
                            value == null ? (isRTL ? 'مطلوب' : 'Required') : null,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: isRTL ? 'إرسال إلى المكبس' : 'Send to press',
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
