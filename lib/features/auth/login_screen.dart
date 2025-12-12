import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'auth_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isRTL = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isRTL = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    debugPrint('[LoginScreen] Login button pressed');
    debugPrint('[LoginScreen] Phone: ${_phoneController.text.trim()}');
    debugPrint('[LoginScreen] Password length: ${_passwordController.text.length}');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('[LoginScreen] Form validation failed');
      return;
    }

    debugPrint('[LoginScreen] Form validated, attempting login...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    debugPrint('[LoginScreen] Login result: $success');
    debugPrint('[LoginScreen] Is recycling unit: ${authProvider.isRecyclingUnit}');
    debugPrint('[LoginScreen] Error message: ${authProvider.errorMessage}');

    if (success && mounted) {
      debugPrint('[LoginScreen] Login successful, navigating to dashboard');
      if (authProvider.isRecyclingUnit) {
        context.go('/dashboard');
      } else {
        // Regular user - navigate to user dashboard if needed
        context.go('/dashboard');
      }
    } else if (mounted) {
      debugPrint('[LoginScreen] Login failed, showing error message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo and App Name
                  Row(
                    mainAxisAlignment: isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.recycling, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        localizations.appName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    localizations.login,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.welcomeBack,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),
                  const SizedBox(height: 32),
                  // Phone Number Field
                  CustomTextField(
                    label: localizations.phoneNumber,
                    hint: localizations.phoneNumber,
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
                  // Password Field
                  CustomTextField(
                    label: localizations.password,
                    hint: localizations.password,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.translate('required_field');
                      }
                      if (value.length < 4) {
                        return localizations.translate('invalid_format');
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Forgot Password
                  Align(
                    alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      child: Text(
                        localizations.forgotPassword,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login Button
                  CustomButton(
                    text: localizations.loginButton,
                    onPressed: _handleLogin,
                    isLoading: authProvider.isLoading,
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          isRTL ? 'أو' : 'or',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Register as Unit Button
                  OutlinedButton(
                    onPressed: () {
                      debugPrint('[LoginScreen] Register as unit button pressed');
                      debugPrint('[LoginScreen] Navigating to registration screen');
                      try {
                        context.push('/register-unit');
                        debugPrint('[LoginScreen] Navigation command executed');
                      } catch (e, stackTrace) {
                        debugPrint('[LoginScreen] Navigation error: $e');
                        debugPrint('[LoginScreen] Stack trace: $stackTrace');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Navigation error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isRTL ? 'تسجيل كوحدة معالجة' : 'Register as a processing unit',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Login with Code
                  TextButton(
                    onPressed: () {
                      // TODO: Implement login with code
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        children: [
                          TextSpan(text: isRTL ? 'تسجيل الدخول ب' : 'Login with '),
                          TextSpan(
                            text: isRTL ? 'رمز التحقق' : 'verification code',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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

