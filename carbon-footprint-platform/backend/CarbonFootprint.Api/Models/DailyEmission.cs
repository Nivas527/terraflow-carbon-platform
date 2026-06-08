using System;

namespace CarbonFootprint.Api.Models;

public class DailyEmission
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public DateTime Date { get; set; } = DateTime.UtcNow.Date;

    // Transport metrics
    public double TransportDistanceKm { get; set; }
    public string TransportVehicleType { get; set; } = string.Empty; // Car, Bus, Train, Motorcycle, Bicycle
    public string TransportFuelType { get; set; } = string.Empty; // Petrol, Diesel, Electric, None
    public double TransportEmissionsCo2Kg { get; set; }

    // Electricity metrics
    public double ElectricityKwh { get; set; }
    public double ElectricityEmissionsCo2Kg { get; set; }

    // Waste metrics
    public double WasteWeightKg { get; set; }
    public string WasteType { get; set; } = string.Empty; // Organic, Plastic, Paper, Mixed
    public double RecyclingRatePercentage { get; set; }
    public double WasteEmissionsCo2Kg { get; set; }

    // Summary
    public double TotalEmissionsCo2Kg { get; set; }

    // Navigation property
    public User? User { get; set; }
}
