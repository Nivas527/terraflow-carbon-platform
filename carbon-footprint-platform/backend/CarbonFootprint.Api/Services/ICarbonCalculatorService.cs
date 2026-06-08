namespace CarbonFootprint.Api.Services;

/// <summary>
/// Service interface for processing daily carbon footprint values.
/// </summary>
public interface ICarbonCalculatorService
{
    /// <summary>
    /// Computes carbon emissions for transportation activities.
    /// </summary>
    double CalculateTransportEmissions(double distance, string vehicleType, string fuelType);

    /// <summary>
    /// Computes carbon emissions for home electricity usage.
    /// </summary>
    double CalculateElectricityEmissions(double kwh);

    /// <summary>
    /// Computes carbon emissions for household waste generation.
    /// </summary>
    double CalculateWasteEmissions(double weight, string wasteType, double recyclingRate);
}
