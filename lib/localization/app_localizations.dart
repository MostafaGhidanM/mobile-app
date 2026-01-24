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

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString;
    try {
      jsonString = await rootBundle
          .loadString('assets/localization/${locale.languageCode}.json');
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
  String get weightKg => translate('weight_kg');
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
  String get pleaseSelectMaterialType =>
      translate('please_select_material_type');
  String get pleaseEnterWeight => translate('please_enter_weight');
  String get pleaseEnterValidNumber => translate('please_enter_valid_number');
  String get pleaseSelectCar => translate('please_select_car');
  String get pleaseEnterCarPlate => translate('please_enter_car_plate');
  String get required => translate('required');
  String get pleaseSelectReceiverUnit =>
      translate('please_select_receiver_unit');
  String get pleaseEnterReceiverUnitId =>
      translate('please_enter_receiver_unit_id');
  String get pleaseSelectTrade => translate('please_select_trade');
  String get pleaseEnterTradeId => translate('please_enter_trade_id');
  String get pleaseEnterPalletsNumber =>
      translate('please_enter_pallets_number');
  String get pleaseUploadShipmentImage =>
      translate('please_upload_shipment_image');
  String get pleaseFillAllRequiredFields =>
      translate('please_fill_all_required_fields');
  String get createShipment => translate('create_shipment');
  String get processedMaterialShipmentCreated =>
      translate('processed_material_shipment_created');
  String get optional => translate('optional');
  String get receiveProcessedShipment =>
      translate('receive_processed_shipment');
  String get shipmentNotFound => translate('shipment_not_found');
  String get pressUnitInformation => translate('press_unit_information');
  String get pressUnitName => translate('press_unit_name');
  String get shipmentNumber => translate('shipment_number');
  String get weightFromPress => translate('weight_from_press');
  String get driverName => translate('driver_name');
  String get shipmentImageFromPress => translate('shipment_image_from_press');
  String get factoryReceiptInformation =>
      translate('factory_receipt_information');
  String get carCheckImage => translate('car_check_image');
  String get receiptImage => translate('receipt_image');
  String get receivedWeight => translate('received_weight');
  String get emptyCarWeight => translate('empty_car_weight');
  String get plenty => translate('plenty');
  String get plentyReason => translate('plenty_reason');
  String get calculatedNetWeight => translate('calculated_net_weight');
  String get receive => translate('receive');
  String get pleaseEnterReceivedWeight =>
      translate('please_enter_received_weight');
  String get pleaseEnterEmptyCarWeight =>
      translate('please_enter_empty_car_weight');
  String get pleaseEnterPlentyPercentage =>
      translate('please_enter_plenty_percentage');
  String get plentyMustBeBetween0And100 =>
      translate('plenty_must_be_between_0_and_100');
  String get pleaseUploadBothImages => translate('please_upload_both_images');
  String get factoryUnitIdNotFound => translate('factory_unit_id_not_found');
  String get shipmentReceivedSuccessfully =>
      translate('shipment_received_successfully');
  String get errorUploadingImage => translate('error_uploading_image');
  String get noReceiverUnitsAvailable =>
      translate('no_receiver_units_available');
  String get arabic => translate('arabic');
  String get english => translate('english');
  String get shipmentSentSuccessfully =>
      translate('shipment_sent_successfully');
  String get split => translate('split');
  String get splits => translate('splits');
  String get splitBySender => translate('split_by_sender');
  String get addSplit => translate('add_split');
  String get removeSplit => translate('remove_split');
  String get selectSender => translate('select_sender');
  String get pleaseSelectSender => translate('please_select_sender');
  String get pleaseAddAtLeastOneSplit =>
      translate('please_add_at_least_one_split');
  String get pleaseSelectSenderForSplit =>
      translate('please_select_sender_for_split');
  String get totalSplitWeight => translate('total_split_weight');
  String get doesNotMatchShipmentWeight =>
      translate('does_not_match_shipment_weight');
  String get pallets => translate('pallets');
  String get pleaseEnterPallets => translate('please_enter_pallets');
  String get totals => translate('totals');
  String get totalPallets => translate('total_pallets');
  String get totalWeight => translate('total_weight');
  String get shipmentWeight => translate('shipment_weight');
  String get totalsMatch => translate('totals_match');
  String get totalsDoNotMatch => translate('totals_do_not_match');
  String get weightLabel => translate('weight_label');
  String get netWeight => translate('net_weight');
  String get material => translate('material');
  String get date => translate('date');
  String get from => translate('from');
  String get to => translate('to');
  String get palletsLabel => translate('pallets_label');
  String get shipment => translate('shipment');
  String get failedToUploadImage => translate('failed_to_upload_image');
  String get failedToGetNextShipmentNumber =>
      translate('failed_to_get_next_shipment_number');
  String get failedToReceiveShipment => translate('failed_to_receive_shipment');
  String get errorLoadingData => translate('error_loading_data');
  String get kg => translate('kg');
  String get pleaseEnterValidPositiveNumber =>
      translate('please_enter_valid_positive_number');
  String get unknown => translate('unknown');
  String get statusPending => translate('status_pending');
  String get statusApproved => translate('status_approved');
  String get statusRejected => translate('status_rejected');
  String get statusSentToFactory => translate('status_sent_to_factory');
  String get statusReceivedAtFactory => translate('status_received_at_factory');
  String get statusSentToAdmin => translate('status_sent_to_admin');
  String get statusOpen => translate('status_open');
  String get statusInProgress => translate('status_in_progress');
  String get statusClosed => translate('status_closed');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
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
