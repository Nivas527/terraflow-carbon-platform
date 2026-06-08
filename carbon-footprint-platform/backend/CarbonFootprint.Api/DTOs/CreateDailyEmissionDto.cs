using System;
using System.ComponentModel.DataAnnotations;

namespace CarbonFootprint.Api.DTOs;

public class CreateDailyEmissionDto
{
    [Required]
    public int UserId { get; set; }

    [Required]
    public DateTime Date { get; set; } = DateTime.UtcNow.Date;

    // Transport metrics
    [Range(0, 1000)]
    public double TransportDistanceKm { get; set; }

    [Required]
    public string TransportVehicleType { get; set; } = string.Empty; // Car, Bus, Train, Motorcycle, Bicycle

    [Required]
    public string TransportFuelType { get; set; } = string.Empty; // Petrol, Diesel, Electric, None

    // Electricity metrics
    [Range(0, 500)]
    public double ElectricityKwh { get; set; }

    // Waste metrics
    [Range(0, 200)]
    public double WasteWeightKg { get; set; }

    [Required]
    public string WasteType { get; set; } = string.Empty; // Organic, Plastic, Paper, Mixed

    [Range(0, 100)]
    public double RecyclingRatePercentage { get; set; }
}
