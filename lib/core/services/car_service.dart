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
}

