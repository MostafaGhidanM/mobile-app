import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString;
    try {
      jsonString = await rootBundle.loadString('assets/localization/${locale.languageCode}.json');
    } catch (e) {
      // Fallback to English if language file not found
      jsonString = await rootBundle.loadString('assets/localization/en.json');
    }
    _localizedStrings = json.decode(jsonString);
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String? translateOrNull(String key) {
    return _localizedStrings[key];
  }

  // Helper getter for common translations
  String get appName => translate('app_name');
  String get login => translate('login');
  String get welcomeBack => translate('welcome_back');
  String get phoneNumber => translate('phone_number');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get loginButton => translate('login_button');
  String get home => translate('home');
  String get shipments => translate('shipments');
  String get orders => translate('orders');
  String get more => translate('more');
  String get myShipments => translate('my_shipments');
  String get search => translate('search');
  String get all => translate('all');
  String get open => translate('open');
  String get inProgress => translate('in_progress');
  String get closed => translate('closed');
  String get receiveShipment => translate('receive_shipment');
  String get sendShipment => translate('send_shipment');
  String get viewShipment => translate('view_shipment');
  String get supplyRequests => translate('supply_requests');
  String get registerVehicle => translate('register_vehicle');
  String get registerSender => translate('register_sender');
  String get inventory => translate('inventory');
  String get quickActions => translate('quick_actions');
  String get settings => translate('settings');
  String get submit => translate('submit');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get retry => translate('retry');
  String get noData => translate('no_data');
  String get shareApp => translate('share_app');
  String get contactUs => translate('contact_us');
  String get termsAndPolicies => translate('terms_and_policies');
  String get accountLanguage => translate('account_language');
  String get personalInformation => translate('personal_information');
  String get shipmentSender => translate('shipment_sender');
  String get shippedWeight => translate('shipped_weight');
  String get shippingDate => translate('shipping_date');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

