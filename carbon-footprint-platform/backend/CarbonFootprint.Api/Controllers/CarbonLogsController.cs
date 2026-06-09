using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CarbonFootprint.Api.Data;
using CarbonFootprint.Api.Models;
using CarbonFootprint.Api.DTOs;
using CarbonFootprint.Api.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CarbonFootprint.Api.Controllers;

/// <summary>
/// API Controller for managing user daily carbon logs and generating footprint statistics.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class CarbonLogsController : ControllerBase
{
    private readonly CarbonDbContext _context;
    private readonly ICarbonCalculatorService _calculatorService;

    /// <summary>
    /// Initializes a new instance of the <see cref="CarbonLogsController"/> class.
    /// </summary>
    /// <param name="context">The database context instance.</param>
    /// <param name="calculatorService">The carbon calculation service instance.</param>
    public CarbonLogsController(CarbonDbContext context, ICarbonCalculatorService calculatorService)
    {
        _context = context;
        _calculatorService = calculatorService;
    }

    /// <summary>
    /// Retrieves all logged daily emissions for a specific user.
    /// Uses database query tracing optimization (AsNoTracking).
    /// </summary>
    /// <param name="userId">The unique identifier of the user (defaults to 1).</param>
    /// <returns>A list of daily emission logs.</returns>
    [HttpGet]
    [ProducesResponseType(200, Type = typeof(IEnumerable<DailyEmissionDto>))]
    public async Task<ActionResult<IEnumerable<DailyEmissionDto>>> GetLogs([FromQuery] int userId = 1)
    {
        var logs = await _context.DailyEmissions
            .AsNoTracking()
            .Where(e => e.UserId == userId)
            .OrderBy(e => e.Date)
            .Select(e => MapToDto(e))
            .ToListAsync();

        return Ok(logs);
    }

    /// <summary>
    /// Retrieves a single daily emission log by its unique ID.
    /// Uses database query tracing optimization (AsNoTracking).
    /// </summary>
    /// <param name="id">The unique identifier of the daily emission log.</param>
    /// <returns>The daily emission log details if found; otherwise, NotFound.</returns>
    [HttpGet("{id:int}")]
    [ProducesResponseType(200, Type = typeof(DailyEmissionDto))]
    [ProducesResponseType(404)]
    public async Task<ActionResult<DailyEmissionDto>> GetLog(int id)
    {
        var log = await _context.DailyEmissions
            .AsNoTracking()
            .FirstOrDefaultAsync(e => e.Id == id);

        if (log == null)
        {
            return NotFound($"Log with ID {id} was not found.");
        }

        return Ok(MapToDto(log));
    }

    /// <summary>
    /// Compiles aggregated carbon statistics (totals, daily averages, and category breakdown) for a user.
    /// Uses database query tracing optimization (AsNoTracking).
    /// </summary>
    /// <param name="userId">The unique identifier of the user (defaults to 1).</param>
    /// <returns>A JSON stats summary object.</returns>
    [HttpGet("stats")]
    [ProducesResponseType(200)]
    public async Task<ActionResult> GetStats([FromQuery] int userId = 1)
    {
        var logs = await _context.DailyEmissions
            .AsNoTracking()
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

    /// <summary>
    /// Logs daily lifestyle activity parameters, calculates footprint offsets, and persists/updates the database.
    /// </summary>
    /// <param name="dto">The create activity log transfer object with inputs.</param>
    /// <returns>The created or updated daily emission result.</returns>
    [HttpPost]
    [ProducesResponseType(201, Type = typeof(DailyEmissionDto))]
    [ProducesResponseType(400)]
    public async Task<ActionResult<DailyEmissionDto>> CreateLog([FromBody] CreateDailyEmissionDto dto)
    {
        if (dto == null)
        {
            return BadRequest("Payload is null.");
        }

        // Validate range bounds (additional controller-level hardening)
        if (dto.TransportDistanceKm < 0 || dto.ElectricityKwh < 0 || dto.WasteWeightKg < 0 || dto.RecyclingRatePercentage < 0 || dto.RecyclingRatePercentage > 100)
        {
            return BadRequest("Parameters exceed allowed range constraints.");
        }

        // Check if user exists
        var userExists = await _context.Users.AnyAsync(u => u.Id == dto.UserId);
        if (!userExists)
        {
            return BadRequest($"User with ID {dto.UserId} does not exist.");
        }

        // Sanitize string parameters to prevent XSS or DB injection
        var vehicle = (dto.TransportVehicleType ?? string.Empty).Trim();
        var fuel = (dto.TransportFuelType ?? string.Empty).Trim();
        var wasteType = (dto.WasteType ?? string.Empty).Trim();

        // Validate against enum/set bounds (Security & Code Quality hardening)
        var allowedVehicles = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Car", "Bus", "Train", "Motorcycle", "Bicycle", "Walking" };
        var allowedFuels = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Petrol", "Diesel", "Electric", "None" };
        var allowedWasteTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "Organic", "Plastic", "Paper", "Mixed" };

        if (!allowedVehicles.Contains(vehicle))
        {
            return BadRequest($"Invalid vehicle type '{vehicle}'. Allowed values are: {string.Join(", ", allowedVehicles)}");
        }
        if (!allowedFuels.Contains(fuel))
        {
            return BadRequest($"Invalid fuel type '{fuel}'. Allowed values are: {string.Join(", ", allowedFuels)}");
        }
        if (!allowedWasteTypes.Contains(wasteType))
        {
            return BadRequest($"Invalid waste type '{wasteType}'. Allowed values are: {string.Join(", ", allowedWasteTypes)}");
        }

        // Check if there is already a log for this user on this date
        var targetDate = dto.Date.Date;
        var existingLog = await _context.DailyEmissions
            .FirstOrDefaultAsync(e => e.UserId == dto.UserId && e.Date == targetDate);

        // Perform carbon calculations using the injected service (Separation of Concerns)
        double transportEmissions = _calculatorService.CalculateTransportEmissions(dto.TransportDistanceKm, vehicle, fuel);
        double electricityEmissions = _calculatorService.CalculateElectricityEmissions(dto.ElectricityKwh);
        double wasteEmissions = _calculatorService.CalculateWasteEmissions(dto.WasteWeightKg, wasteType, dto.RecyclingRatePercentage);
        double totalEmissions = Math.Round(transportEmissions + electricityEmissions + wasteEmissions, 2);

        DailyEmission log;

        if (existingLog != null)
        {
            // Update existing log for the day
            existingLog.TransportDistanceKm = dto.TransportDistanceKm;
            existingLog.TransportVehicleType = vehicle;
            existingLog.TransportFuelType = fuel;
            existingLog.TransportEmissionsCo2Kg = transportEmissions;
            existingLog.ElectricityKwh = dto.ElectricityKwh;
            existingLog.ElectricityEmissionsCo2Kg = electricityEmissions;
            existingLog.WasteWeightKg = dto.WasteWeightKg;
            existingLog.WasteType = wasteType;
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
                TransportVehicleType = vehicle,
                TransportFuelType = fuel,
                TransportEmissionsCo2Kg = transportEmissions,
                ElectricityKwh = dto.ElectricityKwh,
                ElectricityEmissionsCo2Kg = electricityEmissions,
                WasteWeightKg = dto.WasteWeightKg,
                WasteType = wasteType,
                RecyclingRatePercentage = dto.RecyclingRatePercentage,
                WasteEmissionsCo2Kg = wasteEmissions,
                TotalEmissionsCo2Kg = totalEmissions
            };

            _context.DailyEmissions.Add(log);
        }

        await _context.SaveChangesAsync();

        var responseDto = MapToDto(log);
        return CreatedAtAction(nameof(GetLog), new { id = log.Id }, responseDto);
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
}
