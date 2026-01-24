import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';
import '../../core/services/recycling_unit_service.dart';
import '../../core/services/waste_type_service.dart';
import '../../core/models/waste_type.dart';
import '../../core/utils/storage.dart';
import '../../main.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

class RegisterUnitScreen extends StatefulWidget {
  const RegisterUnitScreen({Key? key}) : super(key: key);

  @override
  State<RegisterUnitScreen> createState() => _RegisterUnitScreenState();
}

class _RegisterUnitScreenState extends State<RegisterUnitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unitNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _unitOwnerNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _unitAddressController = TextEditingController();
  final _workersCountController = TextEditingController();
  final _machinesCountController = TextEditingController();
  final _stationCapacityController = TextEditingController();

  final RecyclingUnitService _recyclingUnitService = RecyclingUnitService();
  final WasteTypeService _wasteTypeService = WasteTypeService();

  // Images
  File? _idCardFront;
  File? _idCardBack;
  Uint8List? _idCardFrontBytes;
  Uint8List? _idCardBackBytes;
  File? _rentalContract;
  Uint8List? _rentalContractBytes;
  File? _commercialRegister;
  Uint8List? _commercialRegisterBytes;
  File? _taxCard;
  Uint8List? _taxCardBytes;

  // Dropdowns
  List<WasteType> _wasteTypes = [];
  WasteType? _selectedWasteType;
  String? _selectedGender; // MALE or FEMALE
  String? _selectedUnitType; // PRESS, SHREDDER, or WASHING_LINE

  bool _isLoading = false;
  bool _isLoadingWasteTypes = true;
  bool _isRTL = false;
  Map<String, double>? _geoLocation;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadWasteTypes();
    _checkLocationService();
  }

  Future<void> _checkLocationService() async {
    // Check if location services are enabled on app startup
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      // Show dialog to enable location services
      final localizations = AppLocalizations.of(context)!;
      final isRTL = Localizations.localeOf(context).languageCode == 'ar';
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              title: Text(localizations.enableLocationServices),
              content: Text(localizations.locationServicesRequired),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Open location settings
                    await Geolocator.openLocationSettings();
                  },
                  child: Text(localizations.openSettings),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isRTL = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _phoneNumberController.dispose();
    _unitOwnerNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _unitAddressController.dispose();
    _workersCountController.dispose();
    _machinesCountController.dispose();
    _stationCapacityController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() => _isGettingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isGettingLocation = false);
          // Force user to open location settings
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              final localizations = AppLocalizations.of(context)!;
              final isRTL =
                  Localizations.localeOf(context).languageCode == 'ar';
              return Directionality(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: AlertDialog(
                  title: Text(localizations.enableLocationServices),
                  content: Text(localizations.locationServicesRequiredCapture),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Open location settings
                        await Geolocator.openLocationSettings();
                      },
                      child: Text(localizations.openSettings),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.locationPermissionsDenied),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isGettingLocation = false);
          // Force user to open app settings to grant permission
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              final localizations = AppLocalizations.of(context)!;
              final isRTL =
                  Localizations.localeOf(context).languageCode == 'ar';
              return Directionality(
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                child: AlertDialog(
                  title: Text(localizations.enableLocationPermission),
                  content: Text(localizations.locationPermissionRequired),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Open app settings
                        await Geolocator.openAppSettings();
                      },
                      child: Text(localizations.openSettings),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _geoLocation = {
          'lat': position.latitude,
          'lng': position.longitude,
        };
        _isGettingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.locationCapturedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.failedToGetLocation}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _loadWasteTypes() async {
    setState(() {
      _isLoadingWasteTypes = true;
    });

    final response = await _wasteTypeService.getWasteTypes();

    if (response.isSuccess && response.data != null) {
      setState(() {
        _wasteTypes = response.data!;
        _isLoadingWasteTypes = false;
      });
    } else {
      setState(() {
        _isLoadingWasteTypes = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.error?.message ?? 'Failed to load waste types'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required images
    if ((kIsWeb ? _idCardFrontBytes == null : _idCardFront == null)) {
      _showError(localizations.pleaseAddIdCardFront);
      return;
    }

    if ((kIsWeb ? _idCardBackBytes == null : _idCardBack == null)) {
      _showError(localizations.pleaseAddIdCardBack);
      return;
    }

    // Validate conditional images based on unit type
    if (_selectedUnitType == 'PRESS') {
      if (kIsWeb ? _rentalContractBytes == null : _rentalContract == null) {
        _showError(localizations.pleaseAddRentalContract);
        return;
      }
    } else if (_selectedUnitType == 'WASHING_LINE' ||
        _selectedUnitType == 'SHREDDER') {
      if (kIsWeb
          ? _commercialRegisterBytes == null
          : _commercialRegister == null) {
        _showError(localizations.pleaseAddCommercialRegister);
        return;
      }
      if (kIsWeb ? _taxCardBytes == null : _taxCard == null) {
        _showError(localizations.pleaseAddTaxCard);
        return;
      }
    }

    if (_selectedWasteType == null) {
      _showError(localizations.pleaseSelectWasteType);
      return;
    }

    if (_selectedGender == null) {
      _showError(localizations.pleaseSelectGender);
      return;
    }

    if (_selectedUnitType == null) {
      _showError(localizations.pleaseSelectUnitType);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _recyclingUnitService.register(
      unitName: _unitNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      unitOwnerName: _unitOwnerNameController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      gender: _selectedGender!,
      unitAddress: _unitAddressController.text.trim(),
      wasteTypeId: _selectedWasteType!.id,
      unitType: _selectedUnitType!,
      workersCount: int.tryParse(_workersCountController.text) ?? 0,
      machinesCount: int.tryParse(_machinesCountController.text) ?? 0,
      stationCapacity: double.tryParse(_stationCapacityController.text) ?? 0.0,
      idCardFrontFile: kIsWeb ? null : _idCardFront,
      idCardFrontBytes: kIsWeb ? _idCardFrontBytes : null,
      idCardBackFile: kIsWeb ? null : _idCardBack,
      idCardBackBytes: kIsWeb ? _idCardBackBytes : null,
      rentalContractFile: kIsWeb ? null : _rentalContract,
      rentalContractBytes: kIsWeb ? _rentalContractBytes : null,
      commercialRegisterFile: kIsWeb ? null : _commercialRegister,
      commercialRegisterBytes: kIsWeb ? _commercialRegisterBytes : null,
      taxCardFile: kIsWeb ? null : _taxCard,
      taxCardBytes: kIsWeb ? _taxCardBytes : null,
      geoLocation: _geoLocation,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.registrationSubmittedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.pop();
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response.error?.message ?? localizations.registrationFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(localizations.registerRecyclingUnit),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => _showLanguageDialog(context),
              tooltip: localizations.changeLanguage,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    localizations.pleaseFillInformationToRegister,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 32),

                  // Unit Name
                  CustomTextField(
                    label: localizations.unitName,
                    hint: localizations.enterUnitName,
                    controller: _unitNameController,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  CustomTextField(
                    label: localizations.phoneNumber,
                    hint: localizations.phoneNumber,
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      if (value.length < 5) {
                        return localizations.translate('invalid_format');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Unit Owner Name
                  CustomTextField(
                    label: localizations.unitOwnerName,
                    hint: localizations.enterUnitOwnerName,
                    controller: _unitOwnerNameController,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password
                  CustomTextField(
                    label: localizations.password,
                    hint: localizations.enterPassword,
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      if (value.length < 4) {
                        return localizations.passwordMin4Chars;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  CustomTextField(
                    label: localizations.confirmPassword,
                    hint: localizations.reEnterPassword,
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      if (value != _passwordController.text) {
                        return localizations.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Gender Dropdown
                  ConstrainedDropdownButtonFormField<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    menuMaxHeight: 300,
                    decoration: InputDecoration(
                      labelText: localizations.gender,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'MALE',
                        child: Text(
                          localizations.male,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'FEMALE',
                        child: Text(
                          localizations.female,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return localizations.translate('required_field');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Unit Address
                  CustomTextField(
                    label: localizations.unitAddress,
                    hint: localizations.enterUnitAddress,
                    controller: _unitAddressController,
                    keyboardType: TextInputType.streetAddress,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Location Capture Button
                  OutlinedButton.icon(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_geoLocation != null
                            ? Icons.check_circle
                            : Icons.location_on),
                    label: Text(
                      _geoLocation != null
                          ? localizations.locationCaptured
                          : localizations.captureUnitLocation,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _geoLocation != null
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Waste Type Dropdown
                  ConstrainedDropdownButtonFormField<WasteType>(
                    value: _selectedWasteType,
                    isExpanded: true,
                    menuMaxHeight: 300,
                    decoration: InputDecoration(
                      labelText: localizations.wasteType,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _isLoadingWasteTypes
                        ? []
                        : _wasteTypes.map((wasteType) {
                            return DropdownMenuItem(
                              value: wasteType,
                              child: Text(
                                isRTL
                                    ? wasteType.nameAr
                                    : (wasteType.nameEn ?? wasteType.nameAr),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                    onChanged: _isLoadingWasteTypes
                        ? null
                        : (value) {
                            setState(() {
                              _selectedWasteType = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return localizations.translate('required_field');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Unit Type Dropdown
                  ConstrainedDropdownButtonFormField<String>(
                    value: _selectedUnitType,
                    isExpanded: true,
                    menuMaxHeight: 300,
                    decoration: InputDecoration(
                      labelText: localizations.unitType,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'PRESS',
                        child: Text(
                          localizations.press,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'SHREDDER',
                        child: Text(
                          localizations.shredder,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'WASHING_LINE',
                        child: Text(
                          localizations.washingLine,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedUnitType = value;
                        // Clear conditional images when unit type changes
                        if (value != 'PRESS') {
                          _rentalContract = null;
                          _rentalContractBytes = null;
                        }
                        if (value != 'WASHING_LINE' && value != 'SHREDDER') {
                          _commercialRegister = null;
                          _commercialRegisterBytes = null;
                          _taxCard = null;
                          _taxCardBytes = null;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return localizations.translate('required_field');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Workers Count
                  CustomTextField(
                    label: localizations.workersCount,
                    hint: localizations.enterWorkersCount,
                    controller: _workersCountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 0) {
                        return localizations
                                .translate('please_enter_valid_number') ??
                            'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Machines Count
                  CustomTextField(
                    label: localizations.machinesCount,
                    hint: localizations.enterMachinesCount,
                    controller: _machinesCountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 0) {
                        return localizations
                                .translate('please_enter_valid_number') ??
                            'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Station Capacity
                  CustomTextField(
                    label: localizations.stationCapacity,
                    hint: localizations.enterStationCapacity,
                    controller: _stationCapacityController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      final capacity = double.tryParse(value);
                      if (capacity == null || capacity < 0) {
                        return localizations
                                .translate('please_enter_valid_number') ??
                            'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ID Card Front Image
                  ImagePickerWidget(
                    label: localizations.idCardFront,
                    imagePath: kIsWeb ? null : _idCardFront?.path,
                    imageBytes: kIsWeb ? _idCardFrontBytes : null,
                    onImagePicked: (fileOrBytes) {
                      setState(() {
                        if (kIsWeb) {
                          _idCardFrontBytes = fileOrBytes as Uint8List;
                        } else {
                          _idCardFront = fileOrBytes as File;
                        }
                      });
                    },
                    icon: Icons.credit_card,
                    helperText: localizations.takeOrSelectFrontId,
                  ),
                  const SizedBox(height: 24),

                  // ID Card Back Image
                  ImagePickerWidget(
                    label: localizations.idCardBack,
                    imagePath: kIsWeb ? null : _idCardBack?.path,
                    imageBytes: kIsWeb ? _idCardBackBytes : null,
                    onImagePicked: (fileOrBytes) {
                      setState(() {
                        if (kIsWeb) {
                          _idCardBackBytes = fileOrBytes as Uint8List;
                        } else {
                          _idCardBack = fileOrBytes as File;
                        }
                      });
                    },
                    icon: Icons.credit_card,
                    helperText: localizations.takeOrSelectBackId,
                  ),
                  const SizedBox(height: 24),

                  // Conditional Images based on Unit Type
                  if (_selectedUnitType == 'PRESS') ...[
                    // Rental Contract (required for PRESS)
                    ImagePickerWidget(
                      label: '${localizations.rentalContractImage} *',
                      imagePath: kIsWeb ? null : _rentalContract?.path,
                      imageBytes: kIsWeb ? _rentalContractBytes : null,
                      onImagePicked: (fileOrBytes) {
                        setState(() {
                          if (kIsWeb) {
                            _rentalContractBytes = fileOrBytes as Uint8List;
                          } else {
                            _rentalContract = fileOrBytes as File;
                          }
                        });
                      },
                      icon: Icons.description,
                      helperText: localizations.requiredForPress,
                    ),
                    const SizedBox(height: 24),
                  ] else if (_selectedUnitType == 'WASHING_LINE' ||
                      _selectedUnitType == 'SHREDDER') ...[
                    // Commercial Register (required for WASHING_LINE and SHREDDER)
                    ImagePickerWidget(
                      label: '${localizations.commercialRegisterImage} *',
                      imagePath: kIsWeb ? null : _commercialRegister?.path,
                      imageBytes: kIsWeb ? _commercialRegisterBytes : null,
                      onImagePicked: (fileOrBytes) {
                        setState(() {
                          if (kIsWeb) {
                            _commercialRegisterBytes = fileOrBytes as Uint8List;
                          } else {
                            _commercialRegister = fileOrBytes as File;
                          }
                        });
                      },
                      icon: Icons.business,
                      helperText: localizations.requiredForWashingShredder,
                    ),
                    const SizedBox(height: 24),

                    // Tax Card (required for WASHING_LINE and SHREDDER)
                    ImagePickerWidget(
                      label: '${localizations.taxCardImage} *',
                      imagePath: kIsWeb ? null : _taxCard?.path,
                      imageBytes: kIsWeb ? _taxCardBytes : null,
                      onImagePicked: (fileOrBytes) {
                        setState(() {
                          if (kIsWeb) {
                            _taxCardBytes = fileOrBytes as Uint8List;
                          } else {
                            _taxCard = fileOrBytes as File;
                          }
                        });
                      },
                      icon: Icons.receipt,
                      helperText: localizations.requiredForWashingShredder,
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 32),

                  // Register Button
                  CustomButton(
                    text: localizations.submitRequest,
                    onPressed: _isLoading ? null : _handleRegister,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final currentLocale = Localizations.localeOf(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(localizations.accountLanguage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<Locale>(
                  title: const Text('العربية'),
                  value: const Locale('ar'),
                  groupValue: currentLocale,
                  onChanged: (Locale? value) async {
                    if (value != null) {
                      await StorageService.setString(
                          'app_language', value.languageCode);
                      MyAppState.changeLocale(value);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
                RadioListTile<Locale>(
                  title: const Text('English'),
                  value: const Locale('en'),
                  groupValue: currentLocale,
                  onChanged: (Locale? value) async {
                    if (value != null) {
                      await StorageService.setString(
                          'app_language', value.languageCode);
                      MyAppState.changeLocale(value);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.cancel),
              ),
            ],
          ),
        );
      },
    );
  }
}
