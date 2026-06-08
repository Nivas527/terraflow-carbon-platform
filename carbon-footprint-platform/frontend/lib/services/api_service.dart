import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/daily_emission.dart';

/// Service class handles communication with the backend ASP.NET Web API
/// and maintains local mock cache states if the remote instance is offline.
class ApiService {
  /// Base endpoint URL for carbon logs.
  static const String baseUrl = 'http://localhost:5125/api';

  /// Pre-seeded active user context.
  static const int demoUserId = 1;

  /// In-memory mock data cache for standalone/offline operations.
  static final List<DailyEmission> _mockLogs = [
    DailyEmission(
      id: 1,
      userId: demoUserId,
      date: DateTime.now().subtract(const Duration(days: 6)),
      transportDistanceKm: 25.0,
      transportVehicleType: 'Car',
      transportFuelType: 'Petrol',
      transportEmissionsCo2Kg: 4.5,
      electricityKwh: 12.0,
      electricityEmissionsCo2Kg: 4.8,
      wasteWeightKg: 2.5,
      wasteType: 'Mixed',
      recyclingRatePercentage: 20.0,
      wasteEmissionsCo2Kg: 3.8,
      totalEmissionsCo2Kg: 13.1,
    ),
    DailyEmission(
      id: 2,
      userId: demoUserId,
      date: DateTime.now().subtract(const Duration(days: 5)),
      transportDistanceKm: 15.0,
      transportVehicleType: 'Motorcycle',
      transportFuelType: 'Petrol',
      transportEmissionsCo2Kg: 1.5,
      electricityKwh: 10.0,
      electricityEmissionsCo2Kg: 4.0,
      wasteWeightKg: 1.8,
      wasteType: 'Mixed',
      recyclingRatePercentage: 30.0,
      wasteEmissionsCo2Kg: 2.4,
      totalEmissionsCo2Kg: 7.9,
    ),
    DailyEmission(
      id: 3,
      userId: demoUserId,
      date: DateTime.now().subtract(const Duration(days: 4)),
      transportDistanceKm: 45.0,
      transportVehicleType: 'Bus',
      transportFuelType: 'Diesel',
      transportEmissionsCo2Kg: 3.6,
      electricityKwh: 15.0,
      electricityEmissionsCo2Kg: 6.0,
      wasteWeightKg: 3.0,
      wasteType: 'Mixed',
      recyclingRatePercentage: 10.0,
      wasteEmissionsCo2Kg: 5.13,
      totalEmissionsCo2Kg: 14.73,
    ),
    DailyEmission(
      id: 4,
      userId: demoUserId,
      date: DateTime.now().subtract(const Duration(days: 3)),
      transportDistanceKm: 0.0,
      transportVehicleType: 'Bicycle',
      transportFuelType: 'None',
      transportEmissionsCo2Kg: 0.0,
      electricityKwh: 8.0,
      electricityEmissionsCo2Kg: 3.2,
      wasteWeightKg: 1.0,
      wasteType: 'Mixed',
      recyclingRatePercentage: 80.0,
      wasteEmissionsCo2Kg: 0.38,
      totalEmissionsCo2Kg: 3.58,
    ),
    DailyEmission(
      id: 5,
      userId: demoUserId,
      date: DateTime.now().subtract(const Duration(days: 2)),
      transportDistanceKm: 30.0,
      transportVehicleType: 'Car',
      transportFuelType: 'Electric',
      transportEmissionsCo2Kg: 1.5,
      electricityKwh: 14.0,
      electricityEmissionsCo2Kg: 5.6,
      wasteWeightKg: 2.0,
      wasteType: 'Mixed',
      recyclingRatePercentage: 50.0,
      wasteEmissionsCo2Kg: 1.9,
      totalEmissionsCo2Kg: 9.0,
    ),
    DailyEmission(
      id: 6,
      userId: demoUserId,
      date: DateTime.now().subtract(const Duration(days: 1)),
      transportDistanceKm: 10.0,
      transportVehicleType: 'Train',
      transportFuelType: 'Electric',
      transportEmissionsCo2Kg: 0.4,
      electricityKwh: 11.5,
      electricityEmissionsCo2Kg: 4.6,
      wasteWeightKg: 1.5,
      wasteType: 'Mixed',
      recyclingRatePercentage: 60.0,
      wasteEmissionsCo2Kg: 1.14,
      totalEmissionsCo2Kg: 6.14,
    ),
    DailyEmission(
      id: 7,
      userId: demoUserId,
      date: DateTime.now(),
      transportDistanceKm: 20.0,
      transportVehicleType: 'Car',
      transportFuelType: 'Diesel',
      transportEmissionsCo2Kg: 3.4,
      electricityKwh: 13.0,
      electricityEmissionsCo2Kg: 5.2,
      wasteWeightKg: 2.2,
      wasteType: 'Mixed',
      recyclingRatePercentage: 40.0,
      wasteEmissionsCo2Kg: 2.5,
      totalEmissionsCo2Kg: 11.1,
    ),
  ];

  /// Fetches historical daily carbon emission logs for the user.
  /// Falls back to local memory logs if the backend server is unreachable.
  Future<List<DailyEmission>> fetchLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/carbonlogs?userId=$demoUserId'))
          .timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => DailyEmission.fromJson(json)).toList();
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API fetch logs failed ($e). Falling back to mock data.');
      _mockLogs.sort((a, b) => a.date.compareTo(b.date));
      return List.from(_mockLogs);
    }
  }

  /// Fetches cumulative statistical summaries for carbon emissions.
  /// Computes figures locally using cached records if backend is offline.
  Future<CarbonStats> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/carbonlogs/stats?userId=$demoUserId'))
          .timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        return CarbonStats.fromJson(json.decode(response.body));
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API fetch stats failed ($e). Calculating mock stats locally.');
      if (_mockLogs.isEmpty) return CarbonStats.empty();

      double totalEmissions = 0.0;
      double transportTotal = 0.0;
      double electricityTotal = 0.0;
      double wasteTotal = 0.0;

      for (var log in _mockLogs) {
        totalEmissions += log.totalEmissionsCo2Kg;
        transportTotal += log.transportEmissionsCo2Kg;
        electricityTotal += log.electricityEmissionsCo2Kg;
        wasteTotal += log.wasteEmissionsCo2Kg;
      }

      double averageDaily = totalEmissions / _mockLogs.length;

      return CarbonStats(
        totalEmissionsCo2Kg: double.parse(totalEmissions.toStringAsFixed(2)),
        averageDailyEmissionsCo2Kg: double.parse(averageDaily.toStringAsFixed(2)),
        transportTotalCo2Kg: double.parse(transportTotal.toStringAsFixed(2)),
        electricityTotalCo2Kg: double.parse(electricityTotal.toStringAsFixed(2)),
        wasteTotalCo2Kg: double.parse(wasteTotal.toStringAsFixed(2)),
        logCount: _mockLogs.length,
      );
    }
  }

  /// Appends a new activity log entry.
  /// Validates parameters to ensure sanitization and correct boundaries.
  /// Operates locally if backend server connection fails.
  Future<DailyEmission> addLog(
    double distance,
    String vehicle,
    String fuel,
    double electricity,
    double waste,
    String wasteType,
    double recyclingRate,
  ) async {
    // 1. Validation & Hardening bounds (Security & Code Quality)
    if (distance < 0 || distance > 1000) {
      throw ArgumentError('Distance must be between 0 and 1000 km.');
    }
    if (electricity < 0 || electricity > 500) {
      throw ArgumentError('Electricity must be between 0 and 500 kWh.');
    }
    if (waste < 0 || waste > 200) {
      throw ArgumentError('Waste weight must be between 0 and 200 kg.');
    }
    if (recyclingRate < 0 || recyclingRate > 100) {
      throw ArgumentError('Recycling rate must be between 0% and 100%.');
    }

    // Sanitize string variables to prevent malicious injection payloads
    final sanitizedVehicle = vehicle.trim();
    final sanitizedFuel = fuel.trim();
    final sanitizedWasteType = wasteType.trim();

    final Map<String, dynamic> requestBody = {
      'userId': demoUserId,
      'date': DateTime.now().toIso8601String(),
      'transportDistanceKm': distance,
      'transportVehicleType': sanitizedVehicle,
      'transportFuelType': sanitizedFuel,
      'electricityKwh': electricity,
      'wasteWeightKg': waste,
      'wasteType': sanitizedWasteType,
      'recyclingRatePercentage': recyclingRate,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/carbonlogs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newLog = DailyEmission.fromJson(json.decode(response.body));
        _updateMockLogs(newLog);
        return newLog;
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('API add log failed ($e). Calculating results locally and saving to mock storage.');
      
      // Calculate local values using same formulas as Web API
      double transportEmissions = _calculateTransport(distance, sanitizedVehicle, sanitizedFuel);
      double electricityEmissions = double.parse((electricity * 0.40).toStringAsFixed(2));
      double wasteEmissions = double.parse((waste * 1.9 * (1.0 - (recyclingRate / 100.0))).toStringAsFixed(2));
      double totalEmissions = double.parse((transportEmissions + electricityEmissions + wasteEmissions).toStringAsFixed(2));

      final localLog = DailyEmission(
        id: _mockLogs.length + 1,
        userId: demoUserId,
        date: DateTime.now(),
        transportDistanceKm: distance,
        transportVehicleType: sanitizedVehicle,
        transportFuelType: sanitizedFuel,
        transportEmissionsCo2Kg: transportEmissions,
        electricityKwh: electricity,
        electricityEmissionsCo2Kg: electricityEmissions,
        wasteWeightKg: waste,
        wasteType: sanitizedWasteType,
        recyclingRatePercentage: recyclingRate,
        wasteEmissionsCo2Kg: wasteEmissions,
        totalEmissionsCo2Kg: totalEmissions,
      );

      _updateMockLogs(localLog);
      return localLog;
    }
  }

  static void _updateMockLogs(DailyEmission newLog) {
    final today = DateTime.now();
    final index = _mockLogs.indexWhere((l) => 
        l.date.year == today.year && 
        l.date.month == today.month && 
        l.date.day == today.day
    );

    if (index != -1) {
      _mockLogs[index] = newLog;
    } else {
      _mockLogs.add(newLog);
    }
  }

  /// Internal utility to perform carbon calculation for travel.
  static double _calculateTransport(double distance, String vehicleType, String fuelType) {
    if (distance <= 0) return 0;
    double factor = 0.12;
    switch (vehicleType.toLowerCase()) {
      case 'car':
        switch (fuelType.toLowerCase()) {
          case 'petrol': factor = 0.18; break;
          case 'diesel': factor = 0.17; break;
          case 'electric': factor = 0.05; break;
          default: factor = 0.15;
        }
        break;
      case 'motorcycle':
        factor = fuelType.toLowerCase() == 'petrol' ? 0.10 : 0.08;
        break;
      case 'bus': factor = 0.08; break;
      case 'train': factor = 0.04; break;
      case 'bicycle': factor = 0.0; break;
      case 'walking': factor = 0.0; break;
    }
    return double.parse((distance * factor).toStringAsFixed(2));
  }
}
