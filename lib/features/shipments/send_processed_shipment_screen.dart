import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/shipment_service.dart';
import '../../core/services/waste_type_service.dart';
import '../../core/services/car_service.dart';
import '../../core/services/recycling_unit_service.dart';
import '../../core/services/trade_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/models/waste_type.dart';
import '../../core/models/car.dart';
import '../../core/models/recycling_unit.dart';
import '../../core/models/trade.dart';
import '../../features/auth/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import 'package:go_router/go_router.dart';

class SendProcessedShipmentScreen extends StatefulWidget {
  const SendProcessedShipmentScreen({Key? key}) : super(key: key);

  @override
  State<SendProcessedShipmentScreen> createState() => _SendProcessedShipmentScreenState();
}

class _SendProcessedShipmentScreenState extends State<SendProcessedShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _carPlateController = TextEditingController();
  final _driverFirstNameController = TextEditingController();
  final _driverSecondNameController = TextEditingController();
  final _driverThirdNameController = TextEditingController();
  final _palletsController = TextEditingController();
  final _shipmentNumberController = TextEditingController();
  final _tradeIdController = TextEditingController();
  
  final ShipmentService _shipmentService = ShipmentService();
  final WasteTypeService _wasteTypeService = WasteTypeService();
  final CarService _carService = CarService();
  final RecyclingUnitService _recyclingUnitService = RecyclingUnitService();
  final TradeService _tradeService = TradeService();
  final UploadService _uploadService = UploadService();

  String? _shipmentImagePath;
  String? _shipmentImageUrl;
  String? _receiptImagePath;
  String? _receiptImageUrl;
  WasteType? _selectedMaterialType;
  Car? _selectedCar;
  RecyclingUnit? _selectedReceiver;
  Trade? _selectedTrade;
  List<WasteType> _materialTypes = [];
  List<Car> _cars = [];
  List<RecyclingUnit> _factoryUnits = [];
  List<Trade> _trades = [];
  DateTime _selectedDate = DateTime.now();
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
    _carPlateController.dispose();
    _driverFirstNameController.dispose();
    _driverSecondNameController.dispose();
    _driverThirdNameController.dispose();
    _palletsController.dispose();
    _shipmentNumberController.dispose();
    _tradeIdController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final materialTypesResponse = await _wasteTypeService.getWasteTypes();
      final carsResponse = await _carService.getAssignedCars();
      
      // Load all recycling units and filter for SHREDDER and WASHING_LINE
      List<RecyclingUnit> factoryUnits = [];
      try {
        debugPrint('[SendProcessedShipmentScreen] Loading all recycling units...');
        final allUnitsResponse = await _recyclingUnitService.getRecyclingUnits(
          page: 1,
          pageSize: 100,
        );
        debugPrint('[SendProcessedShipmentScreen] All units response: ${allUnitsResponse.isSuccess}, count: ${allUnitsResponse.data?.length ?? 0}');
        
        if (allUnitsResponse.isSuccess && allUnitsResponse.data != null) {
          // Filter for SHREDDER and WASHING_LINE units only
          factoryUnits = allUnitsResponse.data!.where((unit) {
            return unit.unitType == UnitType.shredder || unit.unitType == UnitType.washingLine;
          }).toList();
          debugPrint('[SendProcessedShipmentScreen] Filtered factory units (SHREDDER/WASHING_LINE): ${factoryUnits.length}');
        }
      } catch (e) {
        debugPrint('[SendProcessedShipmentScreen] Error loading recycling units: $e');
        // Continue without factory units list
      }
      
      // Try to load trades, but don't fail if it errors
      List<Trade> trades = [];
      try {
        final tradesResponse = await _tradeService.getTrades();
        if (tradesResponse.isSuccess && tradesResponse.data != null) {
          trades = tradesResponse.data!;
        }
      } catch (e) {
        debugPrint('[SendProcessedShipmentScreen] Could not load trades: $e');
        // Continue without trades list
      }

      if (mounted) {
        setState(() {
          if (materialTypesResponse.isSuccess && materialTypesResponse.data != null) {
            _materialTypes = materialTypesResponse.data!;
          }
          if (carsResponse.isSuccess && carsResponse.data != null) {
            _cars = carsResponse.data!;
          }
          _factoryUnits = factoryUnits;
          _trades = trades;
          _isLoadingData = false;
        });
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _uploadShipmentImage(dynamic imageData) async {
    if (kIsWeb) {
      setState(() => _shipmentImagePath = 'web_image');
      _uploadImageFromBytes(imageData as Uint8List, true);
    } else {
      final file = imageData as File;
      setState(() => _shipmentImagePath = file.path);
      _uploadImageFromFile(file, true);
    }
  }

  Future<void> _uploadReceiptImage(dynamic imageData) async {
    if (kIsWeb) {
      setState(() => _receiptImagePath = 'web_image');
      _uploadImageFromBytes(imageData as Uint8List, false);
    } else {
      final file = imageData as File;
      setState(() => _receiptImagePath = file.path);
      _uploadImageFromFile(file, false);
    }
  }

  Future<void> _uploadImageFromFile(File file, bool isShipment) async {
    setState(() => _isLoading = true);
    try {
      final response = await _uploadService.uploadImage(file);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          if (isShipment) {
            _shipmentImageUrl = response.data!.url;
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

  Future<void> _uploadImageFromBytes(Uint8List bytes, bool isShipment) async {
    setState(() => _isLoading = true);
    try {
      final response = await _uploadService.uploadImage(bytes);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          if (isShipment) {
            _shipmentImageUrl = response.data!.url;
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

  Future<void> _submitForm() async {
    final localizations = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) return;
    if (_shipmentImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseUploadShipmentImage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedMaterialType == null || _selectedCar == null || 
        _selectedReceiver == null || _selectedTrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseFillAllRequiredFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _shipmentService.createProcessedMaterialShipment(
        shipmentImage: _shipmentImageUrl!,
        materialTypeId: _selectedMaterialType!.id,
        weight: double.parse(_weightController.text),
        carId: _selectedCar!.id,
        carPlateNumber: _selectedCar!.carPlate,
        driverFirstName: _driverFirstNameController.text,
        driverSecondName: _driverSecondNameController.text,
        driverThirdName: _driverThirdNameController.text,
        receiverId: _selectedReceiver!.id,
        tradeId: _selectedTrade!.id,
        sentPalletsNumber: int.parse(_palletsController.text),
        dateOfSending: _selectedDate,
        shipmentNumber: _shipmentNumberController.text.isEmpty 
            ? null 
            : _shipmentNumberController.text,
        receiptFromPress: _receiptImageUrl,
      );

      if (response.isSuccess && mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.processedMaterialShipmentCreated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? localizations.error),
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
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.sendProcessedShipment),
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
                        label: '${localizations.translate('shipment_image')} *',
                        imagePath: _shipmentImagePath,
                        onImagePicked: _uploadShipmentImage,
                      ),
                      const SizedBox(height: 16),
                      
                      // Material Type
                      DropdownButtonFormField<WasteType>(
                        value: _selectedMaterialType,
                        decoration: InputDecoration(
                          labelText: '${localizations.materialType} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _materialTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.nameAr ?? type.nameEn ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedMaterialType = value);
                        },
                        validator: (value) {
                          if (value == null) return localizations.pleaseSelectMaterialType;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Weight
                      CustomTextField(
                        controller: _weightController,
                        label: '${localizations.weightTons} *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.pleaseEnterWeight;
                          }
                          if (double.tryParse(value) == null) {
                            return localizations.pleaseEnterValidNumber;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Car Selection
                      DropdownButtonFormField<Car>(
                        value: _selectedCar,
                        decoration: InputDecoration(
                          labelText: '${localizations.car} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _cars.map((car) {
                          return DropdownMenuItem(
                            value: car,
                            child: Text('${car.carPlate} - ${car.carType?.nameAr ?? car.carType?.nameEn ?? ''}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCar = value;
                            // Car plate is auto-filled from selected car
                          });
                        },
                        validator: (value) {
                          if (value == null) return localizations.pleaseSelectCar;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Car Plate Number (read-only, auto-filled from selected car)
                      if (_selectedCar != null) ...[
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: '${localizations.carPlateNumber} *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          child: Text(
                            _selectedCar!.carPlate,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Driver Name
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _driverFirstNameController,
                              label: '${localizations.driverFirstName} *',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.required;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _driverSecondNameController,
                              label: '${localizations.driverSecondName} *',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.required;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _driverThirdNameController,
                              label: '${localizations.driverThirdName} *',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.required;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Receiver Unit (SHREDDER and WASHING_LINE only)
                      _factoryUnits.isNotEmpty
                          ? DropdownButtonFormField<RecyclingUnit>(
                              value: _selectedReceiver,
                              decoration: InputDecoration(
                                labelText: '${localizations.receiverUnit} *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _factoryUnits.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit.unitName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedReceiver = value);
                              },
                              validator: (value) {
                                if (value == null) return localizations.pleaseSelectReceiverUnit;
                                return null;
                              },
                            )
                          : _isLoadingData
                              ? const Center(child: CircularProgressIndicator())
                              : Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    localizations.translate('no_receiver_units_available') ?? 'No receiver units available',
                                    style: TextStyle(color: Colors.grey[600]),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                      const SizedBox(height: 16),
                      
                      // Trade
                      _trades.isNotEmpty
                          ? DropdownButtonFormField<Trade>(
                              value: _selectedTrade,
                              decoration: InputDecoration(
                                labelText: '${localizations.trade} *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _trades.map((trade) {
                                return DropdownMenuItem(
                                  value: trade,
                                  child: Text(trade.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedTrade = value);
                              },
                              validator: (value) {
                                if (value == null) return localizations.pleaseSelectTrade;
                                return null;
                              },
                            )
                          : CustomTextField(
                              controller: _tradeIdController,
                              label: '${localizations.tradeId} *',
                              onChanged: (value) {
                                // Create a temporary trade with just the ID
                                if (value.isNotEmpty) {
                                  setState(() {
                                    _selectedTrade = Trade(id: value, name: 'Unknown');
                                  });
                                } else {
                                  setState(() => _selectedTrade = null);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return localizations.pleaseEnterTradeId;
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: 16),
                      
                      // Pallets Number
                      CustomTextField(
                        controller: _palletsController,
                        label: '${localizations.palletsNumber} *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.pleaseEnterPalletsNumber;
                          }
                          if (int.tryParse(value) == null) {
                            return localizations.pleaseEnterValidNumber;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date of Sending
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '${localizations.dateOfSending} *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Shipment Number (optional)
                      CustomTextField(
                        controller: _shipmentNumberController,
                        label: '${localizations.translate('shipment_number')} (${localizations.optional})',
                      ),
                      const SizedBox(height: 16),
                      
                      // Receipt Image (optional)
                      ImagePickerWidget(
                        label: '${localizations.receiptFromPress}',
                        imagePath: _receiptImagePath,
                        onImagePicked: _uploadReceiptImage,
                      ),
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      CustomButton(
                        text: localizations.createShipment,
                        onPressed: _isLoading ? null : _submitForm,
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
