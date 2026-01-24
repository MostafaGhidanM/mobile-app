import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../localization/app_localizations.dart';
import '../../features/auth/auth_provider.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../core/utils/storage.dart';
import '../../main.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final unit = authProvider.recyclingUnit;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(localizations.settings),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Station Selection Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit?.unitName ?? localizations.translate('bulking_station'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            localizations.translate('bulking_station'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // Account Settings Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.person,
                      title: localizations.personalInformation,
                      onTap: () {
                        // TODO: Navigate to personal information
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    _SettingsItem(
                      icon: Icons.language,
                      title: localizations.accountLanguage,
                      onTap: () {
                        _showLanguageDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // App Features Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.inventory,
                      title: localizations.myShipments,
                      onTap: () {
                        context.push('/shipments');
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    _SettingsItem(
                      icon: Icons.share,
                      title: localizations.shareApp,
                      onTap: () {
                        // TODO: Implement share functionality
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Support & Legal Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.email,
                      title: localizations.contactUs,
                      onTap: () {
                        // TODO: Navigate to contact us
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    _SettingsItem(
                      icon: Icons.description,
                      title: localizations.termsAndPolicies,
                      onTap: () {
                        // TODO: Navigate to terms and policies
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Logout Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _SettingsItem(
                  icon: Icons.logout,
                  title: localizations.translate('logout'),
                  onTap: () {
                    _showLogoutDialog(context, authProvider, isRTL);
                  },
                  isDestructive: true,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            switch (index) {
              case 0:
                context.push('/dashboard');
                break;
              case 1:
                context.push('/shipments');
                break;
              case 2:
                // TODO: Navigate to orders
                break;
              case 3:
                // Already on settings
                break;
            }
          },
          isRTL: isRTL,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, bool isRTL) {
    final localizations = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(localizations.translate('logout')),
            content: Text(localizations.translate('logout_confirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(localizations.translate('no')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await authProvider.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: Text(
                  localizations.translate('yes'),
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                      await StorageService.setString('app_language', value.languageCode);
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
                      await StorageService.setString('app_language', value.languageCode);
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

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              isRTL ? Icons.chevron_right : Icons.chevron_left,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? Colors.red : null,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red 
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

