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
    setState(() => _isGettingLocation = true);
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isRTL ? 'يرجى تفعيل خدمات الموقع' : 'Please enable location services'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isGettingLocation = false);
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
                content: Text(_isRTL ? 'تم رفض إذن الموقع' : 'Location permissions are denied'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isRTL ? 'يجب تفعيل إذن الموقع من الإعدادات' : 'Location permissions are permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isGettingLocation = false);
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
            content: Text(_isRTL ? 'تم الحصول على الموقع بنجاح' : 'Location captured successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRTL ? 'فشل الحصول على الموقع' : 'Failed to get location: $e'),
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
            content: Text(response.error?.message ?? 'Failed to load waste types'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required images
    if ((kIsWeb ? _idCardFrontBytes == null : _idCardFront == null)) {
      _showError(_isRTL ? 'يرجى إضافة صورة الهوية الأمامية' : 'Please add ID card front image');
      return;
    }

    if ((kIsWeb ? _idCardBackBytes == null : _idCardBack == null)) {
      _showError(_isRTL ? 'يرجى إضافة صورة الهوية الخلفية' : 'Please add ID card back image');
      return;
    }

    // Validate conditional images based on unit type
    if (_selectedUnitType == 'PRESS') {
      if (kIsWeb ? _rentalContractBytes == null : _rentalContract == null) {
        _showError(_isRTL ? 'يرجى إضافة صورة عقد الإيجار (مطلوب للمكبس)' : 'Please add rental contract image (required for PRESS)');
        return;
      }
    } else if (_selectedUnitType == 'WASHING_LINE' || _selectedUnitType == 'SHREDDER') {
      if (kIsWeb ? _commercialRegisterBytes == null : _commercialRegister == null) {
        _showError(_isRTL ? 'يرجى إضافة صورة السجل التجاري (مطلوب لخط الغسيل والتمزيق)' : 'Please add commercial register image (required for WASHING_LINE and SHREDDER)');
        return;
      }
      if (kIsWeb ? _taxCardBytes == null : _taxCard == null) {
        _showError(_isRTL ? 'يرجى إضافة صورة البطاقة الضريبية (مطلوب لخط الغسيل والتمزيق)' : 'Please add tax card image (required for WASHING_LINE and SHREDDER)');
        return;
      }
    }

    if (_selectedWasteType == null) {
      _showError(_isRTL ? 'يرجى اختيار نوع المخلفات' : 'Please select waste type');
      return;
    }

    if (_selectedGender == null) {
      _showError(_isRTL ? 'يرجى اختيار النوع' : 'Please select gender');
      return;
    }

    if (_selectedUnitType == null) {
      _showError(_isRTL ? 'يرجى اختيار نوع الوحدة' : 'Please select unit type');
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
            content: Text(_isRTL ? 'تم إرسال طلبك بنجاح. سيتم مراجعته قريباً' : 'Registration submitted successfully. It will be reviewed soon'),
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
            content: Text(response.error?.message ?? 'Registration failed. Please try again.'),
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
          title: Text(
            isRTL ? 'تسجيل وحدة إعادة التدوير' : 'Register Recycling Unit',
          ),
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
                    isRTL ? 'يرجى ملء البيانات التالية للتسجيل' : 'Please fill in the following information to register',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 32),
                  
                  // Unit Name
                  CustomTextField(
                    label: isRTL ? 'اسم الوحدة' : 'Unit Name',
                    hint: isRTL ? 'أدخل اسم الوحدة' : 'Enter unit name',
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
                    label: isRTL ? 'اسم صاحب الوحدة' : 'Unit Owner Name',
                    hint: isRTL ? 'أدخل اسم صاحب الوحدة' : 'Enter unit owner name',
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
                    label: isRTL ? 'كلمة المرور' : 'Password',
                    hint: isRTL ? 'أدخل كلمة المرور' : 'Enter password',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      if (value.length < 4) {
                        return isRTL ? 'كلمة المرور يجب أن تكون 4 أحرف على الأقل' : 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password
                  CustomTextField(
                    label: isRTL ? 'تأكيد كلمة المرور' : 'Confirm Password',
                    hint: isRTL ? 'أعد إدخال كلمة المرور' : 'Re-enter password',
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      if (value != _passwordController.text) {
                        return isRTL ? 'كلمات المرور غير متطابقة' : 'Passwords do not match';
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
                      labelText: isRTL ? 'النوع' : 'Gender',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'MALE',
                        child: Text(
                          isRTL ? 'ذكر' : 'Male',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'FEMALE',
                        child: Text(
                          isRTL ? 'أنثى' : 'Female',
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
                    label: isRTL ? 'عنوان الوحدة' : 'Unit Address',
                    hint: isRTL ? 'أدخل عنوان الوحدة' : 'Enter unit address',
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
                        : Icon(_geoLocation != null ? Icons.check_circle : Icons.location_on),
                    label: Text(
                      _geoLocation != null
                          ? (isRTL ? 'تم الحصول على الموقع' : 'Location Captured')
                          : (isRTL ? 'الحصول على موقع الوحدة' : 'Capture Unit Location'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _geoLocation != null
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (_geoLocation != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${isRTL ? 'الموقع:' : 'Location:'} ${_geoLocation!['lat']!.toStringAsFixed(6)}, ${_geoLocation!['lng']!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  
                  // Waste Type Dropdown
                  ConstrainedDropdownButtonFormField<WasteType>(
                    value: _selectedWasteType,
                    isExpanded: true,
                    menuMaxHeight: 300,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'نوع المخلفات' : 'Waste Type',
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
                                isRTL ? wasteType.nameAr : (wasteType.nameEn ?? wasteType.nameAr),
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
                      labelText: isRTL ? 'نوع الوحدة' : 'Unit Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'PRESS',
                        child: Text(
                          isRTL ? 'مكبس' : 'Press',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'SHREDDER',
                        child: Text(
                          isRTL ? 'تمزيق' : 'Shredder',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'WASHING_LINE',
                        child: Text(
                          isRTL ? 'خط غسيل' : 'Washing Line',
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
                    label: isRTL ? 'عدد العمال' : 'Workers Count',
                    hint: isRTL ? 'أدخل عدد العمال' : 'Enter workers count',
                    controller: _workersCountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 0) {
                        return isRTL ? 'يرجى إدخال رقم صحيح' : 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Machines Count
                  CustomTextField(
                    label: isRTL ? 'عدد الآلات' : 'Machines Count',
                    hint: isRTL ? 'أدخل عدد الآلات' : 'Enter machines count',
                    controller: _machinesCountController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      final count = int.tryParse(value);
                      if (count == null || count < 0) {
                        return isRTL ? 'يرجى إدخال رقم صحيح' : 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Station Capacity
                  CustomTextField(
                    label: isRTL ? 'سعة المحطة' : 'Station Capacity',
                    hint: isRTL ? 'أدخل سعة المحطة' : 'Enter station capacity',
                    controller: _stationCapacityController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      final capacity = double.tryParse(value);
                      if (capacity == null || capacity < 0) {
                        return isRTL ? 'يرجى إدخال رقم صحيح' : 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // ID Card Front Image
                  ImagePickerWidget(
                    label: isRTL ? 'صورة الهوية الأمامية' : 'ID Card Front',
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
                    helperText: isRTL ? 'التقط أو اختر صورة الهوية من الأمام' : 'Take or select front ID image',
                  ),
                  const SizedBox(height: 24),
                  
                  // ID Card Back Image
                  ImagePickerWidget(
                    label: isRTL ? 'صورة الهوية الخلفية' : 'ID Card Back',
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
                    helperText: isRTL ? 'التقط أو اختر صورة الهوية من الخلف' : 'Take or select back ID image',
                  ),
                  const SizedBox(height: 24),
                  
                  // Conditional Images based on Unit Type
                  if (_selectedUnitType == 'PRESS') ...[
                    // Rental Contract (required for PRESS)
                    ImagePickerWidget(
                      label: isRTL ? 'صورة عقد الإيجار *' : 'Rental Contract Image *',
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
                      helperText: isRTL ? 'مطلوب للمكبس' : 'Required for PRESS',
                    ),
                    const SizedBox(height: 24),
                  ] else if (_selectedUnitType == 'WASHING_LINE' || _selectedUnitType == 'SHREDDER') ...[
                    // Commercial Register (required for WASHING_LINE and SHREDDER)
                    ImagePickerWidget(
                      label: isRTL ? 'صورة السجل التجاري *' : 'Commercial Register Image *',
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
                      helperText: isRTL ? 'مطلوب لخط الغسيل والتمزيق' : 'Required for WASHING_LINE and SHREDDER',
                    ),
                    const SizedBox(height: 24),
                    
                    // Tax Card (required for WASHING_LINE and SHREDDER)
                    ImagePickerWidget(
                      label: isRTL ? 'صورة البطاقة الضريبية *' : 'Tax Card Image *',
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
                      helperText: isRTL ? 'مطلوب لخط الغسيل والتمزيق' : 'Required for WASHING_LINE and SHREDDER',
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Register Button
                  CustomButton(
                    text: isRTL ? 'إرسال الطلب' : 'Submit Request',
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
}
