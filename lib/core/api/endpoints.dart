import '../utils/constants.dart';

class ApiEndpoints {
  static String get baseUrl => AppConstants.baseUrl + AppConstants.apiPrefix;

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';

  // Shipments
  static const String shipments = '/raw-material-shipments-received';
  static String shipmentById(String id) => '$shipments/$id';
  static const String shipmentsNextNumber = '$shipments/next-number';

  // Senders
  static const String senders = '/senders';
  static String senderById(String id) => '$senders/$id';
  static const String assignedSenders = '$senders/assigned';

  // Cars
  static const String cars = '/cars';
  static const String registerCar = '$cars/register';
  static const String assignedCars = '$cars/assigned';

  // Waste Types
  static const String wasteTypes = '/waste-types';

  // Car Brands & Types
  static const String carBrands = '/car-brands';
  static const String carTypes = '/car-types';

  // Upload
  static const String uploadImage = '/upload/image';

  // Registration
  static const String registrationCreate = '/registration/create';
  
  // Activity Types
  static const String activityTypes = '/admin/activity-types';
  
  // Recycling Units
  static const String recyclingUnitsRegister = '/recycling-units/register';
  static const String recyclingUnits = '/recycling-units';

  // Processed Material Shipments
  static const String processedMaterialShipmentsSent = '/processed-material-shipments-sent';
  static String processedMaterialShipmentById(String id) => '$processedMaterialShipmentsSent/$id';
  static String processedMaterialShipmentReceive(String id) => '$processedMaterialShipmentsSent/$id/receive';
  static const String processedMaterialShipmentsPendingReceipt = '$processedMaterialShipmentsSent/pending-receipt';
  static const String processedMaterialShipmentsReceived = '$processedMaterialShipmentsSent/received';
  static const String processedMaterialShipmentsNextNumber = '$processedMaterialShipmentsSent/next-number';

  // Trades
  static const String trades = '/trades';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationById(String id) => '$notifications/$id';
  static String notificationMarkRead(String id) => '$notifications/$id/mark-read';
  static const String notificationsUnreadCount = '$notifications/unread-count';
}

