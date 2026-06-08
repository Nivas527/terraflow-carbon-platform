using System;

namespace CarbonFootprint.Api.Services;

/// <summary>
/// Service implementation of <see cref="ICarbonCalculatorService"/> to process carbon footprint mathematics.
/// </summary>
public class CarbonCalculatorService : ICarbonCalculatorService
{
    /// <inheritdoc />
    public double CalculateTransportEmissions(double distance, string vehicleType, string fuelType)
    {
        if (distance <= 0) return 0;

        // Clean and validate strings to prevent errors
        var cleanedVehicle = (vehicleType ?? string.Empty).Trim().ToLowerInvariant();
        var cleanedFuel = (fuelType ?? string.Empty).Trim().ToLowerInvariant();

        double factor = cleanedVehicle switch
        {
            "car" => cleanedFuel switch
            {
                "petrol" => 0.18,
                "diesel" => 0.17,
                "electric" => 0.05,
                _ => 0.15
            },
            "motorcycle" => cleanedFuel switch
            {
                "petrol" => 0.10,
                _ => 0.08
            },
            "bus" => 0.08,
            "train" => 0.04,
            "bicycle" => 0.0,
            "walking" => 0.0,
            _ => 0.12
        };

        return Math.Round(distance * factor, 2);
    }

    /// <inheritdoc />
    public double CalculateElectricityEmissions(double kwh)
    {
        if (kwh <= 0) return 0;
        // Standard regional average emission factor: 0.40 kg CO2 per kWh
        return Math.Round(kwh * 0.40, 2);
    }

    /// <inheritdoc />
    public double CalculateWasteEmissions(double weight, string wasteType, double recyclingRate)
    {
        if (weight <= 0) return 0;
        
        // Enforce recycling rate boundaries safely between 0.0 and 100.0
        double rate = Math.Clamp(recyclingRate, 0.0, 100.0);

        // Standard landfilled mixed waste emission factor: 1.9 kg CO2 per kg
        double baseFactor = 1.9;
        double multiplier = 1.0 - (rate / 100.0);

        return Math.Round(weight * baseFactor * multiplier, 2);
    }
}
