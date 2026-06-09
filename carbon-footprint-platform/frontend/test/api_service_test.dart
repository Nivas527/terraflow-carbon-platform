import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/daily_emission.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  group('ApiService & Model Unit Tests', () {
    test('DailyEmission JSON Parsing', () {
      final json = {
        'id': 42,
        'userId': 1,
        'date': '2026-06-08T00:00:00.000Z',
        'transportDistanceKm': 25.0,
        'transportVehicleType': 'Car',
        'transportFuelType': 'Petrol',
        'transportEmissionsCo2Kg': 4.5,
        'electricityKwh': 12.0,
        'electricityEmissionsCo2Kg': 4.8,
        'wasteWeightKg': 2.5,
        'wasteType': 'Mixed',
        'recyclingRatePercentage': 20.0,
        'wasteEmissionsCo2Kg': 3.8,
        'totalEmissionsCo2Kg': 13.1,
      };

      final log = DailyEmission.fromJson(json);
      expect(log.id, 42);
      expect(log.transportDistanceKm, 25.0);
      expect(log.totalEmissionsCo2Kg, 13.1);

      final encoded = log.toJson();
      expect(encoded['transportDistanceKm'], 25.0);
      expect(encoded['userId'], 1);
    });

    test('CarbonStats JSON Parsing', () {
      final json = {
        'totalEmissionsCo2Kg': 50.0,
        'averageDailyEmissionsCo2Kg': 12.5,
        'transportTotalCo2Kg': 15.0,
        'electricityTotalCo2Kg': 20.0,
        'wasteTotalCo2Kg': 15.0,
        'logCount': 4,
      };

      final stats = CarbonStats.fromJson(json);
      expect(stats.totalEmissionsCo2Kg, 50.0);
      expect(stats.logCount, 4);
    });

    test('ApiService Input Hardening Validation Bounds', () async {
      final service = ApiService();

      // Negative distance
      expect(
        () => service.addLog(-5.0, 'Car', 'Petrol', 10.0, 2.0, 'Mixed', 30.0),
        throwsArgumentError,
      );

      // Distance out of bounds
      expect(
        () => service.addLog(1500.0, 'Car', 'Petrol', 10.0, 2.0, 'Mixed', 30.0),
        throwsArgumentError,
      );

      // Negative electricity
      expect(
        () => service.addLog(10.0, 'Car', 'Petrol', -2.0, 2.0, 'Mixed', 30.0),
        throwsArgumentError,
      );

      // Negative recycling rate
      expect(
        () => service.addLog(10.0, 'Car', 'Petrol', 10.0, 2.0, 'Mixed', -10.0),
        throwsArgumentError,
      );
    });

    test('ApiService Standalone Local Carbon Math Calculation', () async {
      final service = ApiService();

      final log = await service.addLog(
        50.0,
        'Car',
        'Petrol',
        10.0,
        5.0,
        'Mixed',
        40.0,
      );

      // Transport: 50km * 0.18 (Petrol Car) = 9.0 kg CO2
      // Electricity: 10 kWh * 0.40 = 4.0 kg CO2
      // Waste: 5 kg * 1.9 * (1 - 0.4) = 5.7 kg CO2
      // Total: 9.0 + 4.0 + 5.7 = 18.7 kg CO2
      expect(log.transportEmissionsCo2Kg, 9.0);
      expect(log.electricityEmissionsCo2Kg, 4.0);
      expect(log.wasteEmissionsCo2Kg, 5.7);
      expect(log.totalEmissionsCo2Kg, 18.7);
    });
  });
}
