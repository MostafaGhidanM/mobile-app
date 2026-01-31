import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../localization/app_localizations.dart';
import '../../core/services/sender_service.dart';
import '../../core/services/upload_service.dart';
import '../../core/models/sender.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/constrained_dropdown.dart';

/// Self-registration for senders (no unit assignment). Single-page form like press "register sender" plus password.
/// On success navigates to login.
class RegisterSenderSelfScreen extends StatefulWidget {
  const RegisterSenderSelfScreen({Key? key}) : super(key: key);

  @override
  State<RegisterSenderSelfScreen> createState() => _RegisterSenderSelfScreenState();
}

class _RegisterSenderSelfScreenState extends State<RegisterSenderSelfScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _expectedDailyAmountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _phoneController.dispose();
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _mobileNumberController.dispose();
    _expectedDailyAmountController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    if (_frontIdImageUrl == null || _backIdImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'يرجى رفع صورتي البطاقة'
                : 'Please upload both ID card images',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final password = _passwordController.text;
    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'كلمة المرور 4 أحرف على الأقل'
                : 'Password must be at least 4 characters',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'كلمة المرور غير متطابقة'
                : 'Passwords do not match',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mobile = _mobileNumberController.text.trim().isEmpty
          ? _phoneController.text.trim()
          : _mobileNumberController.text.trim();
      final sender = Sender(
        id: '',
        fullName: _fullNameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        address: _addressController.text.trim(),
        mobileNumber: mobile,
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

      final response = await _senderService.registerSender(sender, password);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم التسجيل بنجاح. يرجى تسجيل الدخول.'
                  : 'Registered successfully. Please log in.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error?.message ?? 'Registration failed'),
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

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isRTL ? 'تسجيل كمرسل' : 'Register as sender',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: localizations.translate('mobile_phone_number'),
                  hint: localizations.translate('mobile_phone_number'),
                  controller: _phoneController,
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
                CustomTextField(
                  label: localizations.password,
                  hint: localizations.enterPassword,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.translate('required_field');
                    }
                    if (value.length < 4) {
                      return localizations.passwordMin4Chars;
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: localizations.confirmPassword,
                  hint: localizations.reEnterPassword,
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return localizations.passwordsDoNotMatch;
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: isRTL ? 'الاسم الكامل' : 'Full Name',
                  controller: _fullNameController,
                  validator: (v) =>
                      (v == null || v.isEmpty)
                          ? localizations.translate('required_field')
                          : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: isRTL ? 'الرقم القومي' : 'National ID',
                  controller: _nationalIdController,
                  keyboardType: TextInputType.text,
                  validator: (v) =>
                      (v == null || v.isEmpty)
                          ? localizations.translate('required_field')
                          : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: isRTL ? 'العنوان' : 'Address',
                  controller: _addressController,
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.isEmpty)
                          ? localizations.translate('required_field')
                          : null,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: isRTL ? 'رقم الهاتف' : 'Mobile Number',
                  controller: _mobileNumberController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                ImagePickerWidget(
                  imagePath: _frontIdImagePath,
                  label: isRTL ? 'البطاقة الأمامية' : 'Front ID Card',
                  onImagePicked: (fileOrBytes) async {
                    setState(() {
                      if (kIsWeb && fileOrBytes is Uint8List) {
                      } else if (!kIsWeb && fileOrBytes is File) {
                        _frontIdImagePath = fileOrBytes.path;
                      }
                    });
                    await _uploadImage(fileOrBytes, true);
                  },
                  icon: Icons.credit_card,
                ),
                const SizedBox(height: 24),
                ImagePickerWidget(
                  imagePath: _backIdImagePath,
                  label: isRTL ? 'البطاقة الخلفية' : 'Back ID Card',
                  onImagePicked: (fileOrBytes) async {
                    setState(() {
                      if (kIsWeb && fileOrBytes is Uint8List) {
                      } else if (!kIsWeb && fileOrBytes is File) {
                        _backIdImagePath = fileOrBytes.path;
                      }
                    });
                    await _uploadImage(fileOrBytes, false);
                  },
                  icon: Icons.credit_card,
                ),
                const SizedBox(height: 20),
                ConstrainedDropdownButtonFormField<Gender>(
                  value: _selectedGender,
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
                    if (value != null) setState(() => _selectedGender = value);
                  },
                ),
                const SizedBox(height: 20),
                ConstrainedDropdownButtonFormField<SenderType>(
                  value: _selectedSenderType,
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
                    if (value != null) setState(() => _selectedSenderType = value);
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: isRTL ? 'الكمية المتوقعة يومياً' : 'Expected Daily Amount',
                  controller: _expectedDailyAmountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: Text(isRTL ? 'لديه هاتف ذكي' : 'Has Smartphone'),
                  value: _haveSmartPhone,
                  onChanged: (value) =>
                      setState(() => _haveSmartPhone = value ?? false),
                ),
                CheckboxListTile(
                  title: Text(isRTL ? 'شركة عائلية' : 'Family Company'),
                  value: _familyCompany,
                  onChanged: (value) =>
                      setState(() => _familyCompany = value ?? false),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: isRTL ? 'تسجيل' : 'Register',
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
