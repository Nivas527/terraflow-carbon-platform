using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarbonFootprint.Api.Data;
using CarbonFootprint.Api.Models;
using CarbonFootprint.Api.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CarbonFootprint.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CarbonLogsController : ControllerBase
{
    private readonly CarbonDbContext _context;

    public CarbonLogsController(CarbonDbContext context)
    {
        _context = context;
    }

    // GET: api/carbonlogs
    [HttpGet]
    public async Task<ActionResult<IEnumerable<DailyEmissionDto>>> GetLogs([FromQuery] int userId = 1)
    {
        var logs = await _context.DailyEmissions
            .Where(e => e.UserId == userId)
            .OrderBy(e => e.Date)
            .Select(e => MapToDto(e))
            .ToListAsync();

        return Ok(logs);
    }

    // GET: api/carbonlogs/stats
    [HttpGet("stats")]
    public async Task<ActionResult> GetStats([FromQuery] int userId = 1)
    {
        var logs = await _context.DailyEmissions
            .Where(e => e.UserId == userId)
            .ToListAsync();

        if (!logs.Any())
        {
            return Ok(new
            {
                totalEmissionsCo2Kg = 0.0,
                averageDailyEmissionsCo2Kg = 0.0,
                transportTotalCo2Kg = 0.0,
                electricityTotalCo2Kg = 0.0,
                wasteTotalCo2Kg = 0.0,
                logCount = 0
            });
        }

        var totalEmissions = logs.Sum(e => e.TotalEmissionsCo2Kg);
        var transportTotal = logs.Sum(e => e.TransportEmissionsCo2Kg);
        var electricityTotal = logs.Sum(e => e.ElectricityEmissionsCo2Kg);
        var wasteTotal = logs.Sum(e => e.WasteEmissionsCo2Kg);
        var averageDaily = logs.Average(e => e.TotalEmissionsCo2Kg);

        return Ok(new
        {
            totalEmissionsCo2Kg = Math.Round(totalEmissions, 2),
            averageDailyEmissionsCo2Kg = Math.Round(averageDaily, 2),
            transportTotalCo2Kg = Math.Round(transportTotal, 2),
            electricityTotalCo2Kg = Math.Round(electricityTotal, 2),
            wasteTotalCo2Kg = Math.Round(wasteTotal, 2),
            logCount = logs.Count
        });
    }

    // POST: api/carbonlogs
    [HttpPost]
    public async Task<ActionResult<DailyEmissionDto>> CreateLog([FromBody] CreateDailyEmissionDto dto)
    {
        // Check if user exists
        var userExists = await _context.Users.AnyAsync(u => u.Id == dto.UserId);
        if (!userExists)
        {
            return BadRequest($"User with ID {dto.UserId} does not exist.");
        }

        // Check if there is already a log for this user on this date
        var targetDate = dto.Date.Date;
        var existingLog = await _context.DailyEmissions
            .FirstOrDefaultAsync(e => e.UserId == dto.UserId && e.Date == targetDate);

        // Perform carbon calculations
        double transportEmissions = CalculateTransportEmissions(dto.TransportDistanceKm, dto.TransportVehicleType, dto.TransportFuelType);
        double electricityEmissions = CalculateElectricityEmissions(dto.ElectricityKwh);
        double wasteEmissions = CalculateWasteEmissions(dto.WasteWeightKg, dto.WasteType, dto.RecyclingRatePercentage);
        double totalEmissions = Math.Round(transportEmissions + electricityEmissions + wasteEmissions, 2);

        DailyEmission log;

        if (existingLog != null)
        {
            // Update existing log for the day
            existingLog.TransportDistanceKm = dto.TransportDistanceKm;
            existingLog.TransportVehicleType = dto.TransportVehicleType;
            existingLog.TransportFuelType = dto.TransportFuelType;
            existingLog.TransportEmissionsCo2Kg = transportEmissions;
            existingLog.ElectricityKwh = dto.ElectricityKwh;
            existingLog.ElectricityEmissionsCo2Kg = electricityEmissions;
            existingLog.WasteWeightKg = dto.WasteWeightKg;
            existingLog.WasteType = dto.WasteType;
            existingLog.RecyclingRatePercentage = dto.RecyclingRatePercentage;
            existingLog.WasteEmissionsCo2Kg = wasteEmissions;
            existingLog.TotalEmissionsCo2Kg = totalEmissions;

            log = existingLog;
            _context.Entry(log).State = EntityState.Modified;
        }
        else
        {
            // Create new log
            log = new DailyEmission
            {
                UserId = dto.UserId,
                Date = targetDate,
                TransportDistanceKm = dto.TransportDistanceKm,
                TransportVehicleType = dto.TransportVehicleType,
                TransportFuelType = dto.TransportFuelType,
                TransportEmissionsCo2Kg = transportEmissions,
                ElectricityKwh = dto.ElectricityKwh,
                ElectricityEmissionsCo2Kg = electricityEmissions,
                WasteWeightKg = dto.WasteWeightKg,
                WasteType = dto.WasteType,
                RecyclingRatePercentage = dto.RecyclingRatePercentage,
                WasteEmissionsCo2Kg = wasteEmissions,
                TotalEmissionsCo2Kg = totalEmissions
            };

            _context.DailyEmissions.Add(log);
        }

        await _context.SaveChangesAsync();

        var responseDto = MapToDto(log);
        return CreatedAtAction(nameof(GetLogs), new { userId = log.UserId }, responseDto);
    }

    private static DailyEmissionDto MapToDto(DailyEmission log)
    {
        return new DailyEmissionDto
        {
            Id = log.Id,
            UserId = log.UserId,
            Date = log.Date,
            TransportDistanceKm = log.TransportDistanceKm,
            TransportVehicleType = log.TransportVehicleType,
            TransportFuelType = log.TransportFuelType,
            TransportEmissionsCo2Kg = log.TransportEmissionsCo2Kg,
            ElectricityKwh = log.ElectricityKwh,
            ElectricityEmissionsCo2Kg = log.ElectricityEmissionsCo2Kg,
            WasteWeightKg = log.WasteWeightKg,
            WasteType = log.WasteType,
            RecyclingRatePercentage = log.RecyclingRatePercentage,
            WasteEmissionsCo2Kg = log.WasteEmissionsCo2Kg,
            TotalEmissionsCo2Kg = log.TotalEmissionsCo2Kg
        };
    }

    private double CalculateTransportEmissions(double distance, string vehicleType, string fuelType)
    {
        if (distance <= 0) return 0;

        double factor = vehicleType.ToLower() switch
        {
            "car" => fuelType.ToLower() switch
            {
                "petrol" => 0.18,
                "diesel" => 0.17,
                "electric" => 0.05,
                _ => 0.15
            },
            "motorcycle" => fuelType.ToLower() switch
            {
                "petrol" => 0.10,
                _ => 0.08
            },
            "bus" => 0.08,
            "train" => 0.04,
            "bicycle" => 0,
            "walking" => 0,
            _ => 0.12
        };

        return Math.Round(distance * factor, 2);
    }

    private double CalculateElectricityEmissions(double kwh)
    {
        if (kwh <= 0) return 0;
        // Standard average emission factor: 0.40 kg CO2 per kWh
        return Math.Round(kwh * 0.40, 2);
    }

    private double CalculateWasteEmissions(double weight, string wasteType, double recyclingRate)
    {
        if (weight <= 0) return 0;
        // Standard landfilled mixed waste emission factor: 1.9 kg CO2 per kg
        double baseFactor = 1.9;
        
        // Recycling rate mitigates landfilled footprint
        double multiplier = 1.0 - (recyclingRate / 100.0);
        if (multiplier < 0) multiplier = 0;
        if (multiplier > 1) multiplier = 1;

        return Math.Round(weight * baseFactor * multiplier, 2);
    }
}
