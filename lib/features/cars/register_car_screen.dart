import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/car_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/models/car.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';
import '../../widgets/car_plate_input.dart';

class RegisterCarScreen extends StatefulWidget {
  const RegisterCarScreen({Key? key}) : super(key: key);

  @override
  State<RegisterCarScreen> createState() => _RegisterCarScreenState();
}

class _RegisterCarScreenState extends State<RegisterCarScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  int _remainingAttempts = 3;

  final _carPlateController = TextEditingController();
  final _maximumCapacityController = TextEditingController();
  String _carPlateValue = '';

  final CarService _carService = CarService();
  final UploadService _uploadService = UploadService();

  String? _carImagePath;
  Uint8List? _carImageBytes;
  String? _carImageUrl;
  String? _licenceFrontImagePath;
  String? _licenceFrontImageUrl;
  String? _licenceBackImagePath;
  String? _licenceBackImageUrl;

  CarBrand? _selectedCarBrand;
  CarType? _selectedCarType;
  List<CarBrand> _carBrands = [];
  List<CarType> _carTypes = [];
  bool _isLoading = false;
  bool _isLoadingBrands = false;
  bool _isLoadingTypes = false;

  @override
  void initState() {
    super.initState();
    _loadCarBrands();
    _loadCarTypes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carPlateController.dispose();
    _maximumCapacityController.dispose();
    super.dispose();
  }

  Future<void> _loadCarBrands() async {
    setState(() => _isLoadingBrands = true);
    final response = await _carService.getCarBrands();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _carBrands = response.data!;
        _isLoadingBrands = false;
      });
    } else {
      setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _loadCarTypes() async {
    setState(() => _isLoadingTypes = true);
    final response = await _carService.getCarTypes();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _carTypes = response.data!;
        _isLoadingTypes = false;
      });
    } else {
      setState(() => _isLoadingTypes = false);
    }
  }

  Future<void> _uploadImage(dynamic imageData, String type) async {
    setState(() => _isLoading = true);

    try {
      final response = await _uploadService.uploadImage(imageData);

      if (response.isSuccess && response.data != null) {
        setState(() {
          switch (type) {
            case 'car':
              _carImageUrl = response.data!.url;
              break;
            case 'licenceFront':
              _licenceFrontImageUrl = response.data!.url;
              break;
            case 'licenceBack':
              _licenceBackImageUrl = response.data!.url;
              break;
          }
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
    if (_carImageUrl == null ||
        _licenceFrontImageUrl == null ||
        _licenceBackImageUrl == null ||
        _selectedCarBrand == null ||
        _selectedCarType == null ||
        _carPlateValue.trim().isEmpty ||
        _maximumCapacityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final car = Car(
        id: '',
        carImage: _carImageUrl!,
        maximumCapacity: double.tryParse(_maximumCapacityController.text) ?? 0,
        carTypeId: _selectedCarType!.id,
        carBrandId: _selectedCarBrand!.id,
        licenceFrontImage: _licenceFrontImageUrl!,
        licenceBackImage: _licenceBackImageUrl!,
        carPlate: _carPlateValue.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _carService.registerCar(car);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car registered successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to register car'),
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
          title: Text(localizations.translate('car_registration')),
          actions: [
            if (_currentStep == 1)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _isLoading ? null : _submitForm,
              ),
          ],
        ),
        body: Column(
          children: [
            // Step Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _StepIndicator(
                    label: localizations.translate('license_plate_tab'),
                    isActive: _currentStep == 0,
                    isCompleted: _currentStep > 0,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                    ),
                  ),
                  _StepIndicator(
                    label: localizations.translate('complete_data'),
                    isActive: _currentStep == 1,
                    isCompleted: false,
                  ),
                ],
              ),
            ),
            // Form Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _LicensePlateStep(
                    carImagePath: _carImagePath,
                    carImageBytes: _carImageBytes,
                    remainingAttempts: _remainingAttempts,
                    onImagePicked: (fileOrBytes) async {
                      setState(() {
                        if (kIsWeb && fileOrBytes is Uint8List) {
                          _carImageBytes = fileOrBytes;
                        } else if (!kIsWeb && fileOrBytes is File) {
                          _carImagePath = fileOrBytes.path;
                        }
                        _remainingAttempts--;
                      });
                      await _uploadImage(fileOrBytes, 'car');
                    },
                    onNext: () {
                      if (_carImageUrl != null) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentStep = 1);
                      }
                    },
                  ),
                  _CompleteDataStep(
                    carPlateValue: _carPlateValue,
                    onCarPlateChanged: (value) {
                      setState(() {
                        _carPlateValue = value;
                        _carPlateController.text = value;
                      });
                    },
                    maximumCapacityController: _maximumCapacityController,
                    licenceFrontImagePath: _licenceFrontImagePath,
                    licenceBackImagePath: _licenceBackImagePath,
                    selectedCarBrand: _selectedCarBrand,
                    selectedCarType: _selectedCarType,
                    carBrands: _carBrands,
                    carTypes: _carTypes,
                    isLoadingBrands: _isLoadingBrands,
                    isLoadingTypes: _isLoadingTypes,
                    onLicenceFrontImagePicked: (fileOrBytes) async {
                      setState(() {
                        if (kIsWeb && fileOrBytes is Uint8List) {
                          // Store bytes for web
                        } else if (!kIsWeb && fileOrBytes is File) {
                          _licenceFrontImagePath = fileOrBytes.path;
                        }
                      });
                      await _uploadImage(fileOrBytes, 'licenceFront');
                    },
                    onLicenceBackImagePicked: (fileOrBytes) async {
                      setState(() {
                        if (kIsWeb && fileOrBytes is Uint8List) {
                          // Store bytes for web
                        } else if (!kIsWeb && fileOrBytes is File) {
                          _licenceBackImagePath = fileOrBytes.path;
                        }
                      });
                      await _uploadImage(fileOrBytes, 'licenceBack');
                    },
                    onCarBrandChanged: (value) => setState(() => _selectedCarBrand = value),
                    onCarTypeChanged: (value) => setState(() => _selectedCarType = value),
                    onSubmit: _submitForm,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepIndicator({
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCompleted
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300],
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _LicensePlateStep extends StatelessWidget {
  final String? carImagePath;
  final Uint8List? carImageBytes;
  final int remainingAttempts;
  final Function(dynamic) onImagePicked;
  final VoidCallback onNext;

  const _LicensePlateStep({
    required this.carImagePath,
    this.carImageBytes,
    required this.remainingAttempts,
    required this.onImagePicked,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Car Image Preview or Placeholder
          if (carImagePath != null || carImageBytes != null)
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb && carImageBytes != null
                    ? Image.memory(
                        carImageBytes!,
                        fit: BoxFit.cover,
                      )
                    : !kIsWeb && carImagePath != null
                        ? Image.file(
                            File(carImagePath!),
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
              ),
            )
          else
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRTL ? 'صورة السيارة' : 'Car Image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          // Instructions
          _InstructionItem(
            number: '١',
            title: localizations.translate('step1'),
            subtitle: localizations.translate('step1_sub'),
          ),
          const SizedBox(height: 16),
          _InstructionItem(
            number: '٢',
            title: localizations.translate('step2'),
            subtitle: localizations.translate('step2_sub'),
          ),
          const SizedBox(height: 16),
          _InstructionItem(
            number: '٣',
            title: localizations.translate('step3'),
            subtitle: localizations.translate('step3_sub'),
          ),
          const SizedBox(height: 16),
          _InstructionItem(
            number: '٤',
            title: localizations.translate('step4'),
            subtitle: localizations.translate('step4_sub').replaceAll('٣', remainingAttempts.toString()),
          ),
          const SizedBox(height: 32),
          ImagePickerWidget(
            imagePath: kIsWeb ? null : carImagePath,
            imageBytes: kIsWeb ? carImageBytes : null,
            label: localizations.translate('take_car_photo'),
            onImagePicked: onImagePicked,
            icon: Icons.camera_alt,
            helperText: localizations.translate('max_file_size'),
          ),
          if (carImagePath != null || carImageBytes != null) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: localizations.translate('next') ?? 'Next',
              onPressed: onNext,
            ),
          ],
        ],
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _InstructionItem({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompleteDataStep extends StatelessWidget {
  final String carPlateValue;
  final ValueChanged<String> onCarPlateChanged;
  final TextEditingController maximumCapacityController;
  final String? licenceFrontImagePath;
  final String? licenceBackImagePath;
  final CarBrand? selectedCarBrand;
  final CarType? selectedCarType;
  final List<CarBrand> carBrands;
  final List<CarType> carTypes;
  final bool isLoadingBrands;
  final bool isLoadingTypes;
  final Function(dynamic) onLicenceFrontImagePicked;
  final Function(dynamic) onLicenceBackImagePicked;
  final Function(CarBrand?) onCarBrandChanged;
  final Function(CarType?) onCarTypeChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _CompleteDataStep({
    required this.carPlateValue,
    required this.onCarPlateChanged,
    required this.maximumCapacityController,
    required this.licenceFrontImagePath,
    required this.licenceBackImagePath,
    required this.selectedCarBrand,
    required this.selectedCarType,
    required this.carBrands,
    required this.carTypes,
    required this.isLoadingBrands,
    required this.isLoadingTypes,
    required this.onLicenceFrontImagePicked,
    required this.onLicenceBackImagePicked,
    required this.onCarBrandChanged,
    required this.onCarTypeChanged,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarPlateInput(
            label: localizations.translate('plate_number'),
            value: carPlateValue,
            onChanged: onCarPlateChanged,
            required: true,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: isRTL ? 'السعة القصوى (كيلو)' : 'Maximum Capacity (kg)',
            controller: maximumCapacityController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          // Car Brand Dropdown
          ConstrainedDropdownButtonFormField<CarBrand>(
            value: selectedCarBrand,
            isExpanded: true,
            menuMaxHeight: 300,
            decoration: InputDecoration(
              labelText: isRTL ? 'ماركة السيارة' : 'Car Brand',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: carBrands.map((brand) {
              return DropdownMenuItem<CarBrand>(
                value: brand,
                child: Text(
                  isRTL ? brand.nameAr : (brand.nameEn ?? brand.nameAr),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: isLoadingBrands ? null : onCarBrandChanged,
          ),
          const SizedBox(height: 20),
          // Car Type Dropdown
          ConstrainedDropdownButtonFormField<CarType>(
            value: selectedCarType,
            isExpanded: true,
            menuMaxHeight: 300,
            decoration: InputDecoration(
              labelText: isRTL ? 'نوع السيارة' : 'Car Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: carTypes.map((type) {
              return DropdownMenuItem<CarType>(
                value: type,
                child: Text(
                  isRTL ? type.nameAr : (type.nameEn ?? type.nameAr),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: isLoadingTypes ? null : onCarTypeChanged,
          ),
          const SizedBox(height: 24),
          ImagePickerWidget(
            imagePath: licenceFrontImagePath,
            label: isRTL ? 'صورة الرخصة الأمامية' : 'License Front Image',
            onImagePicked: onLicenceFrontImagePicked,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 24),
          ImagePickerWidget(
            imagePath: licenceBackImagePath,
            label: isRTL ? 'صورة الرخصة الخلفية' : 'License Back Image',
            onImagePicked: onLicenceBackImagePicked,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: localizations.submit,
            onPressed: onSubmit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

