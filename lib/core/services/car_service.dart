import '../api/api_client.dart';
import '../api/api_response.dart';
import '../api/endpoints.dart';
import '../models/car.dart';

class CarService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<CarBrand>>> getCarBrands() async {
    final response = await _apiClient.get<List<CarBrand>>(
      ApiEndpoints.carBrands,
      fromJson: (json) {
        // The API returns { success: true, data: [...] }
        // The fromJson receives the 'data' field which is a List
        if (json is List) {
          return json.map((item) => CarBrand.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <CarBrand>[];
      },
    );

    return response;
  }

  Future<ApiResponse<List<CarType>>> getCarTypes() async {
    final response = await _apiClient.get<List<CarType>>(
      ApiEndpoints.carTypes,
      fromJson: (json) {
        // The API returns { success: true, data: [...] }
        // The fromJson receives the 'data' field which is a List
        if (json is List) {
          return json.map((item) => CarType.fromJson(item as Map<String, dynamic>)).toList();
        }
        return <CarType>[];
      },
    );

    return response;
  }

  Future<ApiResponse<Car>> registerCar(Car car) async {
    return await _apiClient.post<Car>(
      ApiEndpoints.registerCar,
      data: car.toCreateJson(),
      fromJson: (json) => Car.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<Car>>> getCars({
    String? recyclingUnitId,
    int page = 1,
    int pageSize = 100,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (recyclingUnitId != null) {
      queryParams['recyclingUnitId'] = recyclingUnitId;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.cars,
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final items = (data['items'] as List<dynamic>?)
              ?.map((item) => Car.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResponse<List<Car>>(
        success: true,
        data: items,
        message: response.message,
      );
    }

    return ApiResponse<List<Car>>(
      success: false,
      error: response.error,
      message: response.message,
    );
  }

  /// Fetches cars assigned to the authenticated recycling unit.
  /// The endpoint automatically filters by the logged-in unit's ID.
  Future<ApiResponse<List<Car>>> getAssignedCars({
    int page = 1,
    int pageSize = 100,
    String? carTypeId,
    String? carBrandId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (carTypeId != null) {
      queryParams['carTypeId'] = carTypeId;
    }
    if (carBrandId != null) {
      queryParams['carBrandId'] = carBrandId;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.assignedCars,
      queryParameters: queryParams,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      // Handle paginated response: { items: [...], total: X }
      final items = (data['items'] as List<dynamic>?)
              ?.map((item) => Car.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [];
      return ApiResponse<List<Car>>(
        success: true,
        data: items,
        message: response.message,
      );
    }

    return ApiResponse<List<Car>>(
      success: false,
      error: response.error,
      message: response.message,
    );
  }
}

