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
import '../../core/services/sender_service.dart';
import '../../core/models/waste_type.dart';
import '../../core/models/car.dart';
import '../../core/models/recycling_unit.dart';
import '../../core/models/trade.dart';
import '../../core/models/sender.dart';
import '../../core/models/shipment.dart';
import '../../features/auth/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';
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
  final _tradeIdController = TextEditingController();
  
  final ShipmentService _shipmentService = ShipmentService();
  final WasteTypeService _wasteTypeService = WasteTypeService();
  final CarService _carService = CarService();
  final RecyclingUnitService _recyclingUnitService = RecyclingUnitService();
  final TradeService _tradeService = TradeService();
  final UploadService _uploadService = UploadService();
  final SenderService _senderService = SenderService();

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
  List<Sender> _assignedSenders = [];
  List<Map<String, dynamic>> _splits = []; // Each split: {senderId, senderName, palletsController, weightController}
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingData = true;
  Map<String, double>? _shipmentLocation;

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
    _tradeIdController.dispose();
    // Dispose split controllers
    for (var split in _splits) {
      (split['palletsController'] as TextEditingController).dispose();
      (split['weightController'] as TextEditingController).dispose();
    }
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
        final allUnitsResponse = await _recyclingUnitService.getRecyclingUnits(
          page: 1,
          pageSize: 100,
        );
        
        if (allUnitsResponse.isSuccess && allUnitsResponse.data != null) {
          // Filter for SHREDDER and WASHING_LINE units only
          factoryUnits = allUnitsResponse.data!.where((unit) {
            return unit.unitType == UnitType.shredder || unit.unitType == UnitType.washingLine;
          }).toList();
        }
      } catch (e) {
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
        // Continue without trades list
      }

      // Load assigned senders
      List<Sender> assignedSenders = [];
      try {
        final sendersResponse = await _senderService.getAssignedSenders();
        if (sendersResponse.isSuccess && sendersResponse.data != null) {
          assignedSenders = sendersResponse.data!;
        }
      } catch (e) {
        // Continue without senders list
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
          _assignedSenders = assignedSenders;
          // Initialize with one empty split
          if (_splits.isEmpty) {
            _addSplit();
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.errorLoadingData} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addSplit() {
    setState(() {
      _splits.add({
        'senderId': null,
        'senderName': null,
        'palletsController': TextEditingController(),
        'weightController': TextEditingController(),
      });
    });
  }

  void _removeSplit(int index) {
    setState(() {
      (_splits[index]['palletsController'] as TextEditingController).dispose();
      (_splits[index]['weightController'] as TextEditingController).dispose();
      _splits.removeAt(index);
    });
  }

  void _updateSplitSender(int index, String? senderId) {
    if (_assignedSenders.isEmpty || senderId == null) return;
    setState(() {
      final sender = _assignedSenders.firstWhere(
        (s) => s.id == senderId,
        orElse: () => _assignedSenders.first,
      );
      _splits[index]['senderId'] = senderId;
      _splits[index]['senderName'] = sender.fullName;
    });
  }

  double _calculateTotalSplitWeight() {
    return _splits.fold<double>(0.0, (sum, split) {
      final weight = double.tryParse((split['weightController'] as TextEditingController).text) ?? 0.0;
      return sum + weight;
    });
  }

  int _calculateTotalSplitPallets() {
    return _splits.fold<int>(0, (sum, split) {
      final pallets = int.tryParse((split['palletsController'] as TextEditingController).text) ?? 0;
      return sum + pallets;
    });
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
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? localizations.failedToUploadImage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.errorUploadingImage}: $e'),
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
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? localizations.failedToUploadImage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.errorUploadingImage}: $e'),
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

    // Validate splits
    if (_splits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.pleaseAddAtLeastOneSplit),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all splits have sender selected
    for (var i = 0; i < _splits.length; i++) {
      if (_splits[i]['senderId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.pleaseSelectSenderForSplit} ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Validate totals match
    final totalWeight = double.tryParse(_weightController.text) ?? 0;
    final totalSplitWeight = _calculateTotalSplitWeight();
    if ((totalSplitWeight - totalWeight).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.totalSplitWeight} (${totalSplitWeight.toStringAsFixed(2)} ${localizations.kg}) ${localizations.doesNotMatchShipmentWeight} (${totalWeight.toStringAsFixed(2)} ${localizations.kg})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch next shipment number from backend
      final nextNumberResponse = await _shipmentService.getNextProcessedMaterialShipmentNumber();
      if (!nextNumberResponse.isSuccess || nextNumberResponse.data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nextNumberResponse.error?.message ?? localizations.failedToGetNextShipmentNumber),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

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
        sentPalletsNumber: _calculateTotalSplitPallets(),
        dateOfSending: _selectedDate,
        shipmentNumber: nextNumberResponse.data,
        receiptFromPress: _receiptImageUrl,
        splits: _splits.map((split) {
          return ProcessedMaterialShipmentSplit(
            senderId: split['senderId'] as String,
            senderName: split['senderName'] as String?,
            pallets: int.parse((split['palletsController'] as TextEditingController).text),
            weight: double.parse((split['weightController'] as TextEditingController).text),
          );
        }).toList(),
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
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.error} $e'),
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
                        captureLocation: true,
                        onLocationCaptured: (location) {
                          setState(() {
                            _shipmentLocation = location;
                          });
                        },
                        onImagePicked: _uploadShipmentImage,
                      ),
                      const SizedBox(height: 16),
                      
                      // Material Type
                      ConstrainedDropdownButtonFormField<WasteType>(
                        value: _selectedMaterialType,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: '${localizations.materialType} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _materialTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.nameAr ?? type.nameEn ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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
                        label: '${localizations.weightKg} *',
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
                      ConstrainedDropdownButtonFormField<Car>(
                        value: _selectedCar,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: '${localizations.car} *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _cars.map((car) {
                          return DropdownMenuItem(
                            value: car,
                            child: Text(
                              car.carPlate,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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
                          ? ConstrainedDropdownButtonFormField<RecyclingUnit>(
                              value: _selectedReceiver,
                              isExpanded: true,
                              menuMaxHeight: 300,
                              decoration: InputDecoration(
                                labelText: '${localizations.receiverUnit} *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _factoryUnits.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit.unitName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
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
                          ? ConstrainedDropdownButtonFormField<Trade>(
                              value: _selectedTrade,
                              isExpanded: true,
                              menuMaxHeight: 300,
                              decoration: InputDecoration(
                                labelText: '${localizations.trade} *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _trades.map((trade) {
                                return DropdownMenuItem(
                                  value: trade,
                                  child: Text(
                                    trade.name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
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
                                    _selectedTrade = Trade(id: value, name: localizations.unknown);
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
                      
                      // Splits Section
                      Text(
                        '${localizations.palletsNumber} ${localizations.splitBySender} *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_splits.length, (index) {
                        final split = _splits[index];
                        return Column(
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${localizations.split} ${index + 1}',
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        if (_splits.length > 1)
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _removeSplit(index),
                                            tooltip: localizations.removeSplit,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Sender Dropdown
                                    ConstrainedDropdownButtonFormField<Sender>(
                                      value: split['senderId'] != null && _assignedSenders.isNotEmpty
                                          ? _assignedSenders.firstWhere(
                                              (s) => s.id == split['senderId'],
                                              orElse: () => _assignedSenders.first,
                                            )
                                          : null,
                                      items: _assignedSenders.map((sender) {
                                        return DropdownMenuItem<Sender>(
                                          value: sender,
                                          child: Text(
                                            sender.fullName,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (sender) {
                                        if (sender != null) {
                                          _updateSplitSender(index, sender.id);
                                        }
                                      },
                                      decoration: InputDecoration(
                                        labelText: '${localizations.selectSender} *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null) {
                                          return localizations.pleaseSelectSender;
                                        }
                                        return null;
                                      },
                                      isExpanded: true,
                                    ),
                                    const SizedBox(height: 8),
                                    // Pallets Input
                                    CustomTextField(
                                      controller: split['palletsController'] as TextEditingController,
                                      label: '${localizations.pallets} *',
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}), // Trigger rebuild to update totals
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return localizations.pleaseEnterPallets;
                                        }
                                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                          return localizations.pleaseEnterValidPositiveNumber;
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Weight Input
                                    CustomTextField(
                                      controller: split['weightController'] as TextEditingController,
                                      label: '${localizations.weightLabel} (${localizations.kg}) *',
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setState(() {}), // Trigger rebuild to update totals
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return localizations.pleaseEnterWeight;
                                        }
                                        final weight = double.tryParse(value);
                                        if (weight == null || weight <= 0) {
                                          return localizations.pleaseEnterValidPositiveNumber;
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                      // Add Split Button
                      OutlinedButton.icon(
                        onPressed: _addSplit,
                        icon: const Icon(Icons.add),
                        label: Text(localizations.addSplit),
                      ),
                      const SizedBox(height: 16),
                      // Totals Display
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.totals,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${localizations.totalPallets} ${_calculateTotalSplitPallets()}'),
                              Text('${localizations.totalWeight} ${_calculateTotalSplitWeight().toStringAsFixed(2)} ${localizations.kg}'),
                              Text('${localizations.shipmentWeight} ${_weightController.text.isEmpty ? "0" : _weightController.text} ${localizations.kg}'),
                              const SizedBox(height: 4),
                              if (_weightController.text.isNotEmpty)
                                Text(
                                  _calculateTotalSplitWeight().toStringAsFixed(2) == double.tryParse(_weightController.text)?.toStringAsFixed(2)
                                      ? localizations.totalsMatch
                                      : localizations.totalsDoNotMatch,
                                  style: TextStyle(
                                    color: _calculateTotalSplitWeight().toStringAsFixed(2) == double.tryParse(_weightController.text)?.toStringAsFixed(2)
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
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
