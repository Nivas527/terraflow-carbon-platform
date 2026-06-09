/// Represents a daily carbon log containing emissions telemetry
/// across transportation, electricity usage, and waste generation.
class DailyEmission {
  /// The unique record identifier (nullable if not persisted yet).
  final int? id;

  /// The ID of the logging user.
  final int userId;

  /// The calendar date this log belongs to.
  final DateTime date;

  /// The travel distance covered in kilometers.
  final double transportDistanceKm;

  /// The type of transit vehicle used (e.g. Car, Bus, Train).
  final String transportVehicleType;

  /// The type of fuel used (e.g. Petrol, Diesel, Electric).
  final String transportFuelType;

  /// Calculated carbon emissions for transportation in kg CO2.
  final double transportEmissionsCo2Kg;

  /// Household electricity usage in kilowatt-hours (kWh).
  final double electricityKwh;

  /// Calculated carbon emissions for electricity in kg CO2.
  final double electricityEmissionsCo2Kg;

  /// Household waste weight in kilograms.
  final double wasteWeightKg;

  /// The type of waste generated (e.g. Mixed, Organic).
  final String wasteType;

  /// The percentage rate of waste sent for recycling.
  final double recyclingRatePercentage;

  /// Calculated carbon emissions for waste in kg CO2.
  final double wasteEmissionsCo2Kg;

  /// Calculated combined carbon footprint for the entire day.
  final double totalEmissionsCo2Kg;

  /// Creates an instance of [DailyEmission].
  DailyEmission({
    this.id,
    required this.userId,
    required this.date,
    required this.transportDistanceKm,
    required this.transportVehicleType,
    required this.transportFuelType,
    required this.transportEmissionsCo2Kg,
    required this.electricityKwh,
    required this.electricityEmissionsCo2Kg,
    required this.wasteWeightKg,
    required this.wasteType,
    required this.recyclingRatePercentage,
    required this.wasteEmissionsCo2Kg,
    required this.totalEmissionsCo2Kg,
  });

  /// Decodes a JSON map into a [DailyEmission] entity.
  factory DailyEmission.fromJson(Map<String, dynamic> json) {
    return DailyEmission(
      id: json['id'],
      userId: json['userId'] ?? 1,
      date: DateTime.parse(json['date']),
      transportDistanceKm: (json['transportDistanceKm'] as num).toDouble(),
      transportVehicleType: json['transportVehicleType'] ?? '',
      transportFuelType: json['transportFuelType'] ?? '',
      transportEmissionsCo2Kg: (json['transportEmissionsCo2Kg'] as num)
          .toDouble(),
      electricityKwh: (json['electricityKwh'] as num).toDouble(),
      electricityEmissionsCo2Kg: (json['electricityEmissionsCo2Kg'] as num)
          .toDouble(),
      wasteWeightKg: (json['wasteWeightKg'] as num).toDouble(),
      wasteType: json['wasteType'] ?? '',
      recyclingRatePercentage: (json['recyclingRatePercentage'] as num)
          .toDouble(),
      wasteEmissionsCo2Kg: (json['wasteEmissionsCo2Kg'] as num).toDouble(),
      totalEmissionsCo2Kg: (json['totalEmissionsCo2Kg'] as num).toDouble(),
    );
  }

  /// Encodes this [DailyEmission] entity into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'transportDistanceKm': transportDistanceKm,
      'transportVehicleType': transportVehicleType,
      'transportFuelType': transportFuelType,
      'electricityKwh': electricityKwh,
      'wasteWeightKg': wasteWeightKg,
      'wasteType': wasteType,
      'recyclingRatePercentage': recyclingRatePercentage,
    };
  }
}

/// Represents aggregated footprint metrics shown on the dashboard panels.
class CarbonStats {
  /// Cumulative carbon emissions logged across all entries in kg CO2.
  final double totalEmissionsCo2Kg;

  /// Daily average carbon emissions logged in kg CO2.
  final double averageDailyEmissionsCo2Kg;

  /// Total carbon emissions from transportation.
  final double transportTotalCo2Kg;

  /// Total carbon emissions from home electricity.
  final double electricityTotalCo2Kg;

  /// Total carbon emissions from household waste.
  final double wasteTotalCo2Kg;

  /// Total count of days logged.
  final int logCount;

  /// Creates an instance of [CarbonStats].
  CarbonStats({
    required this.totalEmissionsCo2Kg,
    required this.averageDailyEmissionsCo2Kg,
    required this.transportTotalCo2Kg,
    required this.electricityTotalCo2Kg,
    required this.wasteTotalCo2Kg,
    required this.logCount,
  });

  /// Decodes a JSON map into a [CarbonStats] entity.
  factory CarbonStats.fromJson(Map<String, dynamic> json) {
    return CarbonStats(
      totalEmissionsCo2Kg: (json['totalEmissionsCo2Kg'] as num).toDouble(),
      averageDailyEmissionsCo2Kg: (json['averageDailyEmissionsCo2Kg'] as num)
          .toDouble(),
      transportTotalCo2Kg: (json['transportTotalCo2Kg'] as num).toDouble(),
      electricityTotalCo2Kg: (json['electricityTotalCo2Kg'] as num).toDouble(),
      wasteTotalCo2Kg: (json['wasteTotalCo2Kg'] as num).toDouble(),
      logCount: json['logCount'] ?? 0,
    );
  }

  /// Instantiates empty stats with zeros.
  factory CarbonStats.empty() {
    return CarbonStats(
      totalEmissionsCo2Kg: 0.0,
      averageDailyEmissionsCo2Kg: 0.0,
      transportTotalCo2Kg: 0.0,
      electricityTotalCo2Kg: 0.0,
      wasteTotalCo2Kg: 0.0,
      logCount: 0,
    );
  }
}
