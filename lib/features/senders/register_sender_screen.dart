import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/sender_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/models/sender.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';

class RegisterSenderScreen extends StatefulWidget {
  const RegisterSenderScreen({Key? key}) : super(key: key);

  @override
  State<RegisterSenderScreen> createState() => _RegisterSenderScreenState();
}

class _RegisterSenderScreenState extends State<RegisterSenderScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _expectedDailyAmountController = TextEditingController();

  final SenderService _senderService = SenderService();
  final UploadService _uploadService = UploadService();

  String? _frontIdImagePath;
  String? _frontIdImageUrl;
  String? _backIdImagePath;
  String? _backIdImageUrl;
  Gender _selectedGender = Gender.male;
  SenderType _selectedSenderType = SenderType.residentialUnit;
  bool _haveSmartPhone = false;
  bool _familyCompany = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _mobileNumberController.dispose();
    _expectedDailyAmountController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage(dynamic imageData, bool isFront) async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _uploadService.uploadImage(imageData);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          if (isFront) {
            _frontIdImageUrl = response.data!.url;
          } else {
            _backIdImageUrl = response.data!.url;
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
    if (_frontIdImageUrl == null || _backIdImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both ID card images'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sender = Sender(
        id: '',
        fullName: _fullNameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        address: _addressController.text.trim(),
        mobileNumber: _mobileNumberController.text.trim(),
        nationalIdFront: _frontIdImageUrl!,
        nationalIdBack: _backIdImageUrl!,
        gender: _selectedGender,
        senderType: _selectedSenderType,
        expectedDailyAmount: double.tryParse(_expectedDailyAmountController.text) ?? 0,
        haveSmartPhone: _haveSmartPhone,
        familyCompany: _familyCompany,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _senderService.createSender(sender);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sender registered successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Failed to register sender'),
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
          title: Text(localizations.translate('register_new_sender_title')),
          actions: [
            if (_currentStep == 2)
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
                    label: localizations.translate('phone_number_tab'),
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
                    label: localizations.translate('front_id_tab'),
                    isActive: _currentStep == 1,
                    isCompleted: _currentStep > 1,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 1
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300],
                    ),
                  ),
                  _StepIndicator(
                    label: localizations.translate('complete_data_tab'),
                    isActive: _currentStep == 2,
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
                  _PhoneNumberStep(
                    controller: _phoneController,
                    onNext: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      setState(() => _currentStep = 1);
                    },
                  ),
                  _IdCardStep(
                    frontImagePath: _frontIdImagePath,
                    backImagePath: _backIdImagePath,
                    onFrontImagePicked: (fileOrBytes) async {
                      setState(() {
                        if (kIsWeb && fileOrBytes is Uint8List) {
                          // Store bytes for web
                        } else if (!kIsWeb && fileOrBytes is File) {
                          _frontIdImagePath = fileOrBytes.path;
                        }
                      });
                      await _uploadImage(fileOrBytes, true);
                    },
                    onBackImagePicked: (fileOrBytes) async {
                      setState(() {
                        if (kIsWeb && fileOrBytes is Uint8List) {
                          // Store bytes for web
                        } else if (!kIsWeb && fileOrBytes is File) {
                          _backIdImagePath = fileOrBytes.path;
                        }
                      });
                      await _uploadImage(fileOrBytes, false);
                    },
                    onNext: () {
                      if (_frontIdImageUrl != null && _backIdImageUrl != null) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentStep = 2);
                      }
                    },
                  ),
                  _CompleteDataStep(
                    fullNameController: _fullNameController,
                    nationalIdController: _nationalIdController,
                    addressController: _addressController,
                    mobileNumberController: _mobileNumberController,
                    expectedDailyAmountController: _expectedDailyAmountController,
                    selectedGender: _selectedGender,
                    selectedSenderType: _selectedSenderType,
                    haveSmartPhone: _haveSmartPhone,
                    familyCompany: _familyCompany,
                    onGenderChanged: (value) => setState(() => _selectedGender = value),
                    onSenderTypeChanged: (value) => setState(() => _selectedSenderType = value),
                    onHaveSmartPhoneChanged: (value) => setState(() => _haveSmartPhone = value),
                    onFamilyCompanyChanged: (value) => setState(() => _familyCompany = value),
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

class _PhoneNumberStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onNext;

  const _PhoneNumberStep({
    required this.controller,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            label: localizations.translate('mobile_phone_number'),
            hint: localizations.translate('mobile_phone_number'),
            controller: controller,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: localizations.translate('search'),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _IdCardStep extends StatelessWidget {
  final String? frontImagePath;
  final String? backImagePath;
  final Function(dynamic) onFrontImagePicked;
  final Function(dynamic) onBackImagePicked;
  final VoidCallback onNext;

  const _IdCardStep({
    required this.frontImagePath,
    required this.backImagePath,
    required this.onFrontImagePicked,
    required this.onBackImagePicked,
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
          ImagePickerWidget(
            imagePath: frontImagePath,
            label: isRTL ? 'البطاقة الأمامية' : 'Front ID Card',
            onImagePicked: onFrontImagePicked,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 24),
          ImagePickerWidget(
            imagePath: backImagePath,
            label: isRTL ? 'البطاقة الخلفية' : 'Back ID Card',
            onImagePicked: onBackImagePicked,
            icon: Icons.credit_card,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: localizations.translate('next') ?? 'Next',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _CompleteDataStep extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController nationalIdController;
  final TextEditingController addressController;
  final TextEditingController mobileNumberController;
  final TextEditingController expectedDailyAmountController;
  final Gender selectedGender;
  final SenderType selectedSenderType;
  final bool haveSmartPhone;
  final bool familyCompany;
  final Function(Gender) onGenderChanged;
  final Function(SenderType) onSenderTypeChanged;
  final Function(bool) onHaveSmartPhoneChanged;
  final Function(bool) onFamilyCompanyChanged;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _CompleteDataStep({
    required this.fullNameController,
    required this.nationalIdController,
    required this.addressController,
    required this.mobileNumberController,
    required this.expectedDailyAmountController,
    required this.selectedGender,
    required this.selectedSenderType,
    required this.haveSmartPhone,
    required this.familyCompany,
    required this.onGenderChanged,
    required this.onSenderTypeChanged,
    required this.onHaveSmartPhoneChanged,
    required this.onFamilyCompanyChanged,
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
          CustomTextField(
            label: isRTL ? 'الاسم الكامل' : 'Full Name',
            controller: fullNameController,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: isRTL ? 'الرقم القومي' : 'National ID',
            controller: nationalIdController,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: isRTL ? 'العنوان' : 'Address',
            controller: addressController,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: isRTL ? 'رقم الهاتف' : 'Mobile Number',
            controller: mobileNumberController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          // Gender Dropdown
          ConstrainedDropdownButtonFormField<Gender>(
            value: selectedGender,
            isExpanded: true,
            menuMaxHeight: 300,
            decoration: InputDecoration(
              labelText: isRTL ? 'النوع' : 'Gender',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: Gender.values.map((gender) {
              return DropdownMenuItem<Gender>(
                value: gender,
                child: Text(
                  gender == Gender.male 
                      ? (isRTL ? 'ذكر' : 'Male')
                      : (isRTL ? 'أنثى' : 'Female'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onGenderChanged(value);
            },
          ),
          const SizedBox(height: 20),
          // Sender Type Dropdown
          ConstrainedDropdownButtonFormField<SenderType>(
            value: selectedSenderType,
            isExpanded: true,
            menuMaxHeight: 300,
            decoration: InputDecoration(
              labelText: isRTL ? 'نوع المرسل' : 'Sender Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: SenderType.values.map((type) {
              String label;
              switch (type) {
                case SenderType.residentialUnit:
                  label = isRTL ? 'وحدة سكنية' : 'Residential Unit';
                  break;
                case SenderType.collectionCenter:
                  label = isRTL ? 'مركز تجميع' : 'Collection Center';
                  break;
                case SenderType.mobileCollection:
                  label = isRTL ? 'تجميع متنقل' : 'Mobile Collection';
                  break;
                case SenderType.collectionWorker:
                  label = isRTL ? 'عامل تجميع' : 'Collection Worker';
                  break;
              }
              return DropdownMenuItem<SenderType>(
                value: type,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onSenderTypeChanged(value);
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: isRTL ? 'الكمية المتوقعة يومياً' : 'Expected Daily Amount',
            controller: expectedDailyAmountController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          // Checkboxes
          CheckboxListTile(
            title: Text(isRTL ? 'لديه هاتف ذكي' : 'Has Smartphone'),
            value: haveSmartPhone,
            onChanged: (value) => onHaveSmartPhoneChanged(value ?? false),
          ),
          CheckboxListTile(
            title: Text(isRTL ? 'شركة عائلية' : 'Family Company'),
            value: familyCompany,
            onChanged: (value) => onFamilyCompanyChanged(value ?? false),
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

