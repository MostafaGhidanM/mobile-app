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
  String get sendProcessedShipment => translate('send_processed_shipment');
  String get materialType => translate('material_type');
  String get weightTons => translate('weight_tons');
  String get car => translate('car');
  String get carPlateNumber => translate('car_plate_number');
  String get driverFirstName => translate('driver_first_name');
  String get driverSecondName => translate('driver_second_name');
  String get driverThirdName => translate('driver_third_name');
  String get receiverUnit => translate('receiver_unit');
  String get receiverUnitId => translate('receiver_unit_id');
  String get trade => translate('trade');
  String get tradeId => translate('trade_id');
  String get palletsNumber => translate('pallets_number');
  String get dateOfSending => translate('date_of_sending');
  String get receiptFromPress => translate('receipt_from_press');
  String get pleaseSelectMaterialType => translate('please_select_material_type');
  String get pleaseEnterWeight => translate('please_enter_weight');
  String get pleaseEnterValidNumber => translate('please_enter_valid_number');
  String get pleaseSelectCar => translate('please_select_car');
  String get pleaseEnterCarPlate => translate('please_enter_car_plate');
  String get required => translate('required');
  String get pleaseSelectReceiverUnit => translate('please_select_receiver_unit');
  String get pleaseEnterReceiverUnitId => translate('please_enter_receiver_unit_id');
  String get pleaseSelectTrade => translate('please_select_trade');
  String get pleaseEnterTradeId => translate('please_enter_trade_id');
  String get pleaseEnterPalletsNumber => translate('please_enter_pallets_number');
  String get pleaseUploadShipmentImage => translate('please_upload_shipment_image');
  String get pleaseFillAllRequiredFields => translate('please_fill_all_required_fields');
  String get createShipment => translate('create_shipment');
  String get processedMaterialShipmentCreated => translate('processed_material_shipment_created');
  String get optional => translate('optional');
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

