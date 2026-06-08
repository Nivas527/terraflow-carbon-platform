using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;
using CarbonFootprint.Api.Controllers;
using CarbonFootprint.Api.Data;
using CarbonFootprint.Api.Models;
using CarbonFootprint.Api.DTOs;
using CarbonFootprint.Api.Services;

namespace CarbonFootprint.Api.Tests;

public class CarbonLogsControllerTests
{
    private readonly DbContextOptions<CarbonDbContext> _dbOptions;
    private readonly ICarbonCalculatorService _calculatorService;

    public CarbonLogsControllerTests()
    {
        _dbOptions = new DbContextOptionsBuilder<CarbonDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
            
        _calculatorService = new CarbonCalculatorService();
    }

    private async Task SeedDatabaseAsync(CarbonDbContext context)
    {
        var user = new User { Id = 1, Name = "Test User", Email = "test@user.com" };
        context.Users.Add(user);

        var log = new DailyEmission
        {
            Id = 1,
            UserId = 1,
            Date = DateTime.UtcNow.Date,
            TransportDistanceKm = 10.0,
            TransportVehicleType = "Car",
            TransportFuelType = "Petrol",
            TransportEmissionsCo2Kg = 1.8,
            ElectricityKwh = 10.0,
            ElectricityEmissionsCo2Kg = 4.0,
            WasteWeightKg = 2.0,
            WasteType = "Mixed",
            RecyclingRatePercentage = 0.0,
            WasteEmissionsCo2Kg = 3.8,
            TotalEmissionsCo2Kg = 9.6
        };
        context.DailyEmissions.Add(log);
        
        await context.SaveChangesAsync();
    }

    [Fact]
    public async Task GetLogs_ReturnsLogsForValidUser()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var result = await controller.GetLogs(1);

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var logs = Assert.IsAssignableFrom<IEnumerable<DailyEmissionDto>>(okResult.Value);
        Assert.Single(logs);
        Assert.Equal(9.6, logs.First().TotalEmissionsCo2Kg);
    }

    [Fact]
    public async Task GetStats_ReturnsEmissionsCalculationsForValidUser()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var result = await controller.GetStats(1);

        var okResult = Assert.IsType<OkObjectResult>(result);
        
        // Use reflection to assert anonymous type values
        var value = okResult.Value;
        Assert.NotNull(value);
        var totalEmissions = (double)value.GetType().GetProperty("totalEmissionsCo2Kg")!.GetValue(value)!;
        var logCount = (int)value.GetType().GetProperty("logCount")!.GetValue(value)!;

        Assert.Equal(9.6, totalEmissions);
        Assert.Equal(1, logCount);
    }

    [Fact]
    public async Task CreateLog_ValidPayload_SavesAndReturns201Created()
    {
        using var context = new CarbonDbContext(_dbOptions);
        await SeedDatabaseAsync(context);

        var controller = new CarbonLogsController(context, _calculatorService);

        var payload = new CreateDailyEmissionDto
        {
            UserId = 1,
            Date = DateTime.UtcNow.Date.AddDays(1),
            TransportDistanceKm = 20.0,
            TransportVehicleType = "Car",
            TransportFuelType = "Petrol",
            ElectricityKwh = 15.0,
            WasteWeightKg = 5.0,
            WasteType = "Mixed",
            RecyclingRatePercentage = 20.0
        };

        var result = await controller.CreateLog(payload);

        var createdResult = Assert.IsType<CreatedAtActionResult>(result.Result);
        var logDto = Assert.IsType<DailyEmissionDto>(createdResult.Value);

        // Math:
        // Transport: 20 * 0.18 = 3.6
        // Electricity: 15 * 0.40 = 6.0
        // Waste: 5 * 1.9 * (1 - 0.2) = 7.6
        // Total: 3.6 + 6.0 + 7.6 = 17.2
        Assert.Equal(17.2, logDto.TotalEmissionsCo2Kg);

        // Verify it was saved to DB
        var dbLogs = await context.DailyEmissions.Where(e => e.UserId == 1).ToListAsync();
        Assert.Equal(2, dbLogs.Count);
    }
}
