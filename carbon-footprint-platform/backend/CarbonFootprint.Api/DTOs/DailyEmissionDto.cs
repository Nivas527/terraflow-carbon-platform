using System;

namespace CarbonFootprint.Api.DTOs;

public class DailyEmissionDto
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public DateTime Date { get; set; }

    public double TransportDistanceKm { get; set; }
    public string TransportVehicleType { get; set; } = string.Empty;
    public string TransportFuelType { get; set; } = string.Empty;
    public double TransportEmissionsCo2Kg { get; set; }

    public double ElectricityKwh { get; set; }
    public double ElectricityEmissionsCo2Kg { get; set; }

    public double WasteWeightKg { get; set; }
    public string WasteType { get; set; } = string.Empty;
    public double RecyclingRatePercentage { get; set; }
    public double WasteEmissionsCo2Kg { get; set; }

    public double TotalEmissionsCo2Kg { get; set; }
}
